import autosize from '@github/textarea-autosize';


// press control L to get to the search field
document.onkeyup = function(e) { 
  if(e.ctrlKey && e.which == 76) { 
    document.searchform.searchfield.focus()
  }
}

document.addEventListener("turbolinks:load", function(){
  var existing_textareas;

  if(existing_textareas = document.querySelector("textarea")) {
    autosize(existing_textareas);
  }
});

document.addEventListener("DOMContentLoaded", function(){
  var existing_textareas, new_entry_input;

  if(existing_textareas = document.querySelector("textarea")) {
    autosize(existing_textareas);
  }

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
          document.searchform.searchfield.focus();
          e.preventDefault();
        }
      });
    }
  }
})

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
