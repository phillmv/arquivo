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
}

document.addEventListener("turbolinks:load", function(){
  setFilterHandler();
  savedSearch();

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
