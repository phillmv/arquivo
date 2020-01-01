document.onkeyup = function(e) { 
  if(e.ctrlKey && e.which == 76) { 
    document.searchform.searchfield.focus()
  }
  if(e.ctrlKey && e.which == 76) { 
    document.searchform.searchfield.focus()
  }
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
