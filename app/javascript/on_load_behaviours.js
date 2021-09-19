// import '@github/file-attachment-element';
import 'entry_folding' ;
import 'file_uploading' ;
import 'text_expanding';
import 'textarea_sizing';
import 'task_list_handler';

function safe_to_navigate_away_from_entry() {
  if (window.entry_body) {
    if (window.entry_body.value == "") {
      return true
    } else {
      return false
    }
  } else {
    // not being edited
    return true
  }
}

document.onkeyup = function(e) {
  // press control L to get to the search field
  if(e.ctrlKey && e.which == 76) {
    document.searchform.query.focus()
    var len = document.searchform.query.value.length;
    document.searchform.query.setSelectionRange(len, len);
  }

  var current_nwo = window.current_nwo;
  if (current_nwo) {
    var nwo = current_nwo.name

    if(e.ctrlKey && e.which == 78) {
      if (safe_to_navigate_away_from_entry()) {
        window.location.pathname = `/${nwo}/new`
      }
    }

    if(e.ctrlKey && e.code == "BracketLeft") {
      switch(window.current_action.name) {
        case "calendar/daily":
          if(safe_to_navigate_away_from_entry()) {
            window.location.pathname = `/${nwo}`
          }
          break;
        case "calendar/weekly":
          window.location.pathname = `/${nwo}/calendar/daily`
          break;
        case "calendar/monthly":
          window.location.pathname = `/${nwo}/calendar/weekly`
          break;
        default:
          if(safe_to_navigate_away_from_entry()) {
            window.location.pathname = `/${nwo}`
          }
      }
    }

    if(e.ctrlKey && e.code == "BracketRight") {
      switch(window.current_action.name) {
        case "timeline/index":
          window.location.pathname = `/${nwo}/calendar/daily`
          break;
        case "calendar/daily":
          if(safe_to_navigate_away_from_entry()) {
            window.location.pathname = `/${nwo}/calendar/weekly`
          }
          break;
        case "calendar/weekly":
          window.location.pathname = `/${nwo}/calendar`
          break;
      }
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

  if (document.querySelector('entry.threaded')) {
    entry = document.querySelector('.js-entry-show')
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
