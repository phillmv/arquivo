import { DirectUpload} from "@rails/activestorage";

// handles directupload to form, injecting url back into textarea
export const uploadFile = (file, file_input) => {

  // your form needs the file_field direct_upload: true, which
  // provides data-direct-upload-url
  const url = file_input.dataset.directUploadUrl
  const upload = new DirectUpload(file, url)

  upload.create((error, blob) => {
    if (error) {
      alert(error);

    } else {

      var form = file_input.closest("form");
      var textarea = form.querySelector("textarea");
      let attachment_link;

      // only set the img tag if it looks like an image!
      if (blob.filename.match(/\.(gif|jpe?g|tiff?|png|webp|bmp)$/)) {
        attachment_link = `![${blob.filename}](${blob.file_path})`
      }
      else {
        attachment_link = `[${blob.filename}](${blob.file_path})`
      }

      textarea.setRangeText(attachment_link, textarea.selectionStart, textarea.selectionEnd, "end");

      // Add an appropriately-named hidden input to the form with a
      // value of blob.signed_id so that the blob ids will be
      // transmitted in the normal upload flow
      const hiddenField = document.createElement('input');
      hiddenField.setAttribute("type", "hidden");
      hiddenField.setAttribute("value", blob.signed_id);
      hiddenField.name = file_input.name;
      form.appendChild(hiddenField);
    }
  })
}

document.addEventListener("turbolinks:load", function(){
  var file_input, textarea;

  // TODO: surely a SelectorAll and a for loop better eh?
  file_input = document.querySelector('input[type=file]#entry_files');
  textarea = document.querySelector('textarea#entry_body');

  // handling uploads
  // Bind to normal file selection
  if(file_input) {

    bind_input_change(file_input)

    // bind to textarea paste events; we make it conditional on the
    // file_input since we need its directUploadUrl
    if (textarea) {
      bind_textarea_paste(textarea, file_input)
    }
  }
});

function bind_input_change(file_input) {
  file_input.addEventListener('change', (event) => {
    Array.from(file_input.files).forEach(file => uploadFile(file, file_input))
    // you might clear the selected files from the input
    file_input.value = null
  })
}

function bind_textarea_paste(textarea, file_input) {
  textarea.addEventListener('paste', e => {
    let clipboard_files = e.clipboardData.files

    // if there are no files, then we want to do the default
    if(clipboard_files.length > 0) {
      e.preventDefault();

      Array.from(clipboard_files).forEach(file => uploadFile(file, file_input))
    }
  });
}
