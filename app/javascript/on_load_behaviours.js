// import '@github/file-attachment-element';
import 'entry_folding' ;
import 'file_uploading' ;
import 'text_expanding';
import 'textarea_sizing';
import 'task_list_handler';

// press control L to get to the search field
document.onkeyup = function(e) {
  if(e.ctrlKey && e.which == 76) {
    document.searchform.query.focus()
    var len = document.searchform.query.value.length;
    document.searchform.query.setSelectionRange(len, len);
  }

  if(e.ctrlKey && e.which == 78) {
    var notebook = window.location.pathname.split("/")[1]
    if (!document.querySelector("textarea#entry_body")) {
      window.location = `/${notebook}/new`
    }
  }

  if(e.ctrlKey && e.code == "BracketLeft") {
    var [dontcare, notebook, path1, path2] = window.location.pathname.split("/")
    var path_location = [path1, path2 ].join("/")

      switch(path_location) {
        case "agenda/":
          if(document.querySelector("textarea#entry_body").value == "") {
            window.location = `/${notebook}`
          }
          break;
        case "calendar/weekly":
          window.location = `/${notebook}/agenda`
          break;
        case "calendar/":
          window.location = `/${notebook}/calendar/weekly`
          break;
      }
  }

  if(e.ctrlKey && e.code == "BracketRight") {
    var [dontcare, notebook, path1, path2] = window.location.pathname.split("/")
    var path_location = [path1, path2].join("/")

      switch(path_location) {
        case "timeline/":
          window.location = `/${notebook}/agenda`
          break;
        case "agenda/":
          if(document.querySelector("textarea#entry_body").value == "") {
            window.location = `/${notebook}/calendar/weekly`
          }
          break;
        case "calendar/weekly":
          window.location = `/${notebook}/calendar`
          break;
      }
    }

  if(e.ctrlKey && e.code == "KeyK") {
    var details = document.querySelector("details")
    if (details.open) {
      details.open = false
    }
    else {
      details.open = true
    }

    details.querySelector("summary").focus()
  }
  

}

document.addEventListener("turbolinks:load", function(){
  setFilterHandler();
  savedSearch();

  // pretty sure this is about ensuring the main entry is in view
  // when displaying long threads in the show action
  var entry;
  if (document.querySelector('.entry-threaded')) {
    entry = document.querySelector('.entry-show')
    entry.scrollIntoView({
      behavior: "smooth",
      block: "start",
      inline: "nearest"
    });
  }
});


function savedSearch() {
  var saved_search = document.querySelector("#new_saved_search")
  if (saved_search) {
    saved_search.addEventListener("submit", (e) => {
      saved_search.saved_search_query.value = document.searchform.query.value
    });
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
