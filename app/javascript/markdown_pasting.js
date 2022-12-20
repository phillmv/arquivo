import {subscribe} from '@github/paste-markdown'

document.addEventListener("turbolinks:load", function() {
  var textarea = document.querySelector('textarea[data-paste-markdown]')
  if (textarea) {
    subscribe(textarea);
  }
});
