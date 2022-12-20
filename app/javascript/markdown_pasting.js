import {subscribe} from '@github/paste-markdown'

document.addEventListener("turbolinks:load", function() {
  subscribe(document.querySelector('textarea[data-paste-markdown]'));
  console.log("lol i fired!!!")
});
