// TODO: tbh, convert this to js and remove coffeescript as a dependency ;p
import TaskList from "task_list";


document.addEventListener("turbolinks:load", function(){
  var markdown_divs;
  markdown_divs = document.querySelectorAll(".js-task-list-container");
  for (let mdiv of markdown_divs) {
    new TaskList(mdiv);
  }
});

// this fn submits the tasklist form to update the entry
document.addEventListener("tasklist:changed", (e) => {
  var list_elem = e.currentTarget.activeElement.parentElement
  list_elem.classList.add("animate-flicker")

  var form = e.target.closest("form")

  // task-list-field holds the raw markdown content
  var task_list_field = form.querySelector(".js-task-list-field")
  var form_data = new FormData(form)
  if (!task_list_field.value) {
    // there are two ways the task_list_field is set:
    // either thru a hidden form + textarea or a hidden div
    //
    // if the task_list_field has .value, then it's a textarea within
    // the form, and its contents will have been captured in the FormData,
    // and we don't have to do anything.
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

