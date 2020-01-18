document.onkeyup = function(e) { 
  if(e.ctrlKey && e.which == 76) { 
    document.searchform.searchfield.focus()
  }
  if(e.ctrlKey && e.which == 76) { 
    document.searchform.searchfield.focus()
  }
}

/*
var editableFormHandler = function(event, f) {
  event.srcElement.querySelector("#entry_body").innerHTML = 
    event.srcElement.querySelector("#entry_content").innerHTML
}

document.addEventListener("DOMContentLoaded", function(){
  pageForms = document.getElementsByTagName("form")

  for(i = 0; i < pageForms.length; i++) {
    currentForm = pageForms[i]
    currentForm.addEventListener('submit', editableFormHandler)
  }

  document.searchform.addEventListener("keydown", function(e) {
    console.log(e.which);
    if(e.which == 9) {
      document.querySelector("#entry_content.new").focus();
      e.preventDefault();
    }
  });


})
*/

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
