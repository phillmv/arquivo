import autosize from '@github/textarea-autosize';
// import '@github/file-attachment-element';
import { DirectUpload} from "@rails/activestorage";

import '@github/text-expander-element'

// TODO: tbh, convert this to js and remove coffeescript as a dependency ;p
import TaskList from "task_list";

// press control L to get to the search field
document.onkeyup = function(e) {
  if(e.ctrlKey && e.which == 76) {
    document.searchform.query.focus()
    var len = document.searchform.query.value.length;
    document.searchform.query.setSelectionRange(len, len);
  }
}

// this fn submits the tasklist form to update the entry
// its out here cos its adding an event on document
// TODO: move this inside the fn below? maybe attached to the form
document.addEventListener("tasklist:changed", (e) => {
  var list_elem = e.currentTarget.activeElement.parentElement
  list_elem.classList.add("animate-flicker")
  var form = e.target.closest("form")

  var task_list_field = form.querySelector(".js-task-list-field")
  var form_data = new FormData(form)
  if (!task_list_field.value) {
    // if the task_list_field has .value, then it's a textarea within
    // the form, and its contents will have been captured in the FormData
    //
    // if the task_list_field does not have a .value, then it's because it's
    // our hacky div solution, so we need to look up its textContent and
    // manually insert the field into the form_data.
    form_data.set("entry[body]", task_list_field.textContent)
  }

  fetch(form.action, {
    method: form.method,
    body: form_data,
    headers: {
      "Accept": "application/json"
    }
  }).then((response) => {
    if(response.status == 200) {
      list_elem.classList.remove("animate-flicker")
    }
    else {
      alert("yo, this checkbox failed to update, might want to refresh the page")
    }
  });

});


// durr do i need both turbolinks:load *and* DOMContentLoad?
document.addEventListener("turbolinks:load", function(){
  setTextAreaHandler();
  setFileUploadHandler();
  setEntryFoldToggleHandler();
  setFilterHandler();
  setTaskListHandler()
  savedSearch();

  text_expand_pls();

  // TODO: document this, you fool
  // pretty sure this is about ensuring the main entry is in view
  // when displaying long threads in the show action
  var entry;
  if (entry = document.querySelector('.entry-show')) {
    entry.scrollIntoView({
      behavior: "smooth",
      block: "start",
      inline: "nearest"
    });
  }
});

function text_expand_pls(){
  const expander = document.querySelector('text-expander')

  if(!!expander) {
    expander.addEventListener('text-expander-change', event => {
      const {key, provide, text} = event.detail

      if (key === '#') {
        fetch_textexpand_menu("tags", text, provide)
      } else if (key == "@") {
        fetch_textexpand_menu("contacts", text, provide)
      }
    });

    expander.addEventListener('text-expander-value', function(event) {
      const {key, item}  = event.detail
      if (key === '#') {
        event.detail.value = item.textContent
      } else if (key == '@') {
        event.detail.value = `@${item.textContent}`
      }
    });

  }
 }

function fetch_textexpand_menu(type, text, callback) {
  var notebook = window.location.pathname.split("/")[1]
  var query = encodeURIComponent(text)

  // TODO: dear LORD clean this up, catch errors, etc
  callback(
    fetch(`/${notebook}/${type}/${query}`).
    then( response => response.json() ).
    then( data => {

      const menu = suggestion_menu(data)
      return {matched: data.length > 0, fragment: menu};
    })
  );


}

function suggestion_menu(collection) {
  const menu = document.createElement('ul')
  menu.role = 'listbox'
  menu.classList.add("suggester")
  menu.classList.add("suggester-container")
  menu.classList.add("list-style-none")
  for (const member of collection) {
    const item = document.createElement('li')
    item.setAttribute('role', 'option')
    item.textContent = member.name
    item.id = `option-${member.id}`
    menu.append(item)
  }

  return menu
}

document.addEventListener("DOMContentLoaded", function(){
  setTextAreaHandler();
  setFileUploadHandler();
  setEntryFoldToggleHandler();
  setFilterHandler();

  // text_expand_pls();
   // setTaskListHandler()

  /* TODO: deprecated, used to work, left here for reference only, for now
  var new_entry_input;

  if (document.searchform) {
    // pressing tab from the search form should move to the new entry form
    // if it exists.
    // currently deprecated
    document.searchform.addEventListener("keydown", function(e) {
      if(e.which == 9) {

        new_entry_input = document.querySelector("form.new_entry textarea");
        if (new_entry_input) {
          new_entry_input.focus();
          e.preventDefault();
        }
      }
    });

    // if we're on a page with a new entry text area, pressing shift-tab
    // should move back to the search form.
    // current deprecated
    if (new_entry_input = document.querySelector("form.new_entry textarea")) {
      new_entry_input.addEventListener("keydown", function(e) {
        if (event.shiftKey && event.keyCode == 9) {
          document.searchform.query.focus();
          e.preventDefault();
        }
      });
    } 
  }*/
});


function savedSearch() {
  var saved_search = document.querySelector("#new_saved_search")
  if (saved_search) {
    saved_search.addEventListener("submit", (e) => {
      saved_search.saved_search_query.value = document.searchform.query.value
    });
  }
}

function setTaskListHandler() {
  var markdown_divs;
  markdown_divs = document.querySelectorAll(".js-task-list-container");
  for (let mdiv of markdown_divs) {
    new TaskList(mdiv);
  }
}


function setFilterHandler() {
  var filter_dropdown_links, link, selected_filter;

  filter_dropdown_links = document.querySelectorAll("ul.search-filter a")
  for (let dropdown_link of filter_dropdown_links) {
    dropdown_link.addEventListener("click", (e) => {
      e.preventDefault();
      link = e.currentTarget;

      selected_filter = link.dataset.filter;
      if (document.searchform.search_query.value.indexOf(selected_filter) == -1) {
        document.searchform.search_query.value =  `${document.searchform.search_query.value} ${selected_filter}`
      }
      link.closest("form").submit();
    });
  }
}
// 1. always autosize textareas,
// 2. always scroll to the bottom of the input
function setTextAreaHandler() {
  var existing_textarea;
  if(existing_textarea = document.querySelector("textarea")) {
    autosize(existing_textarea);

    var len = existing_textarea.value.length;
    existing_textarea.setSelectionRange(len, len);
    existing_textarea.scrollTop = existing_textarea.scrollHeight;
  }
}

function setFileUploadHandler() {
  var file_input;

  // TODO: surely a SelectorAll and a for loop better eh?
  file_input = document.querySelector('input[type=file]');

  // handling uploads
  // Bind to normal file selection
  if(file_input) {
    file_input.addEventListener('change', (event) => {
      Array.from(file_input.files).forEach(file => uploadFile(file, file_input))
      // you might clear the selected files from the input
      file_input.value = null
    })
  }
}

function setEntryFoldToggleHandler() {
  // add event listener for handling fold & unfold links:
  document.querySelectorAll('.show-on-fold').forEach(function(elem) {
    elem.addEventListener("click", function(e) {
      e.preventDefault();
      this.closest(".Box-body").classList.remove("truncate");
    })
  });

  document.querySelectorAll('.hide-on-fold').forEach(function(elem) {
    elem.addEventListener("click", function(e) {
      e.preventDefault();
      this.closest(".Box-body").classList.add("truncate");
    })
  });

  // click anywhere in the entry to remove truncate
  document.addEventListener("click", (e) => {
    var elem = e.target;
    var entry_body;
    if(!elem.matches(".hide-on-fold") && (entry_body = elem.closest(".Box-body"))) {
      entry_body.classList.remove("truncate");
    }

    if(elem.closest(".collapsed")){
      elem.closest(".Box-body").classList.remove("collapsed");
    }
  });

  // Commented out for now: double clicking to refold not actually that useful,
  // but not yet ready to delete this.
  // document.addEventListener('dblclick', (e) => {
  //   var elem = e.target;
  //   var entry_body;
  //   if(!elem.matches(".show-on-fold") && (entry_body = elem.closest(".Box-body"))) {
  //     entry_body.classList.add("truncate");
  //
  //     if (!isScrolledIntoView(entry_body)) {
  //       entry_body.scrollIntoView({
  //         behavior: "smooth",
  //         block: "start",
  //         inline: "nearest"
  //       });
  //     }
  //   }
  // });
}

function isScrolledIntoView(el) {
    var rect = el.getBoundingClientRect();
    var elemTop = rect.top;
    var elemBottom = rect.bottom;

    // Only completely visible elements return true:
    var isVisible = (elemTop >= 0) && (elemBottom <= window.innerHeight);
    // Partially visible elements return true:
    //isVisible = elemTop < window.innerHeight && elemBottom >= 0;
    return isVisible;
}

// handles directupload to form, injecting url back into textarea
const uploadFile = (file, file_input) => {
  // your form needs the file_field direct_upload: true, which
  //  provides data-direct-upload-url
  const url = file_input.dataset.directUploadUrl
  const upload = new DirectUpload(file, url)

  upload.create((error, blob) => {
    if (error) {
      alert(error);

    } else {

      var form = file_input.closest("form");
      var textarea = form.querySelector("textarea");
      // TODO: get this to distinguish between
      // images and non-images.
      textarea.setRangeText(`\n![${blob.filename}](${blob.file_path})`);

      // Add an appropriately-named hidden input to the form with a
      //  value of blob.signed_id so that the blob ids will be
      //  transmitted in the normal upload flow
      const hiddenField = document.createElement('input');
      hiddenField.setAttribute("type", "hidden");
      hiddenField.setAttribute("value", blob.signed_id);
      hiddenField.name = file_input.name;
      form.appendChild(hiddenField);
    }
  })
}




// import Turbolinks from 'turbolinks';
// 
// document.addEventListener('turbolinks:load', function(event) {
//   for (let form of document.querySelectorAll('form[method=get][remote=true]')) {
//     form.addEventListener('ajax:beforeSend', function (event) {
//       const detail = event.detail,
//             xhr = detail[0], options = detail[1];
// 
//       Turbolinks.visit(options.url);
//       event.preventDefault();
//     });
//   }
// });
// 
// console.log("what")
//
//
//
//
// --------
