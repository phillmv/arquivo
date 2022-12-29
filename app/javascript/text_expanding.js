import '@github/text-expander-element';

function text_expand_pls(){
  // TODO: querySelectorAll
  const expander = document.querySelector('text-expander')

  if(!!expander) {
    expander.addEventListener('text-expander-change', event => {
      const {key, provide, text} = event.detail

      if (key === '#') {
        fetch_textexpand_menu("_tags", text, provide)
      } else if (key == "@") {
        fetch_textexpand_menu("_contacts", text, provide)
      } else if (key == "[[") {
        fetch_textexpand_menu("_subjects", text, provide);
      } else if (key == ":") {
        fetch_textexpand_menu("_emoji", text, provide);
      }
    });

    expander.addEventListener('text-expander-value', function(event) {
      const {key, item}  = event.detail
      if (key === '#') {
        event.detail.value = item.textContent
      } else if (key == '@') {
        event.detail.value = `@${item.textContent}`
      } else if (key == "[[") {
        event.detail.value = `[[${item.identifier}]]`
      } else if (key == ":") {
        event.detail.value = item.identifier
      }
    });

  }
}

function fetch_textexpand_menu(type, text, callback) {
  var nwo = window.current_nwo.name
  var query = encodeURIComponent(text)

  // TODO: dear LORD clean this up, catch errors, etc
  callback(
    fetch(`/${nwo}/${type}/${query}`).
    then( response => response.json() ).
    then( data => {
      var menu;
      if (type == "_subjects") {
        menu = suggestion_menu(data, "identifier", "subject")
      }
      else  {
        menu = suggestion_menu(data)
      }
      return {matched: data.length > 0, fragment: menu};
    })
  );
}

function suggestion_menu(collection, id_attr = "id", label_attr = "name") {
  const menu = document.createElement('ul')
  menu.role = 'listbox'
  menu.classList.add("suggester")
  menu.classList.add("suggester-container")
  menu.classList.add("list-style-none")
  for (const member of collection) {
    const item = document.createElement('li')
    item.setAttribute('role', 'option')
    item.textContent = member[label_attr]
    item.identifier = member[id_attr]
    item.id = `option-${member[id_attr]}`
    menu.append(item)
  }

  return menu
}


document.addEventListener("turbolinks:load", function(){
  text_expand_pls();
});
