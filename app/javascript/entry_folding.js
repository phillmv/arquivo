document.addEventListener("turbolinks:load", function(){
  document.querySelectorAll('.show-on-fold').forEach(function(elem) {
    elem.addEventListener("click", function(e) {
      e.preventDefault();
      this.closest(".Box-body").classList.remove("truncate");
    })
  });

  document.querySelectorAll('.hide-on-fold').forEach(function(elem) {
    elem.addEventListener("click", function(e) {
      e.preventDefault();
      this.closest(".Box-body").classList.add("truncate");
    })
  });

  // click anywhere in the entry to remove truncate
  document.addEventListener("click", (e) => {
    var elem = e.target;
    var entry_body;
    if(!elem.matches(".hide-on-fold") && (entry_body = elem.closest(".Box-body"))) {
      entry_body.classList.remove("truncate");
    }

    // TODO: .collapsed is probably deprecated?
    if(elem.closest(".collapsed")){
      elem.closest(".Box-body").classList.remove("collapsed");
    }
  });
});


/* Commented out double click handler, might want to use this later?
document.addEventListener('dblclick', (e) => {
  var elem = e.target;
  var entry_body;
  if(!elem.matches(".show-on-fold") && (entry_body = elem.closest(".Box-body"))) {
    entry_body.classList.add("truncate");

    if (!isScrolledIntoView(entry_body)) {
      entry_body.scrollIntoView({
        behavior: "smooth",
        block: "start",
        inline: "nearest"
      });
    }
  }
});

// used to figure out if top of element is visible
function isScrolledIntoView(el) {
    var rect = el.getBoundingClientRect();
    var elemTop = rect.top;
    var elemBottom = rect.bottom;

    // Only completely visible elements return true:
    var isVisible = (elemTop >= 0) && (elemBottom <= window.innerHeight);
    // Partially visible elements return true:
    //isVisible = elemTop < window.innerHeight && elemBottom >= 0;
    return isVisible;
}


*/
