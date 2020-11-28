import autosize from '@github/textarea-autosize';

// 1. always autosize textareas,
// 2. always set selection at the end of the textarea
// 3. always scroll to the bottom
document.addEventListener("turbolinks:load", function(){
  var existing_textarea;

  if(existing_textarea = document.querySelector("textarea")) {
    autosize(existing_textarea);

    var len = existing_textarea.value.length;
    existing_textarea.setSelectionRange(len, len);
    existing_textarea.scrollTop = existing_textarea.scrollHeight;
  }
});
