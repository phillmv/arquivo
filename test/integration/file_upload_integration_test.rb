require 'test_helper'

class FileUploadIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @current_notebook = Notebook.create(name: "test")
    @file_path = File.join(Rails.root, "test", "fixtures", "test_image.jpg")
  end

  test "files uploaded to the same entry " do

    assert_equal 0, @current_notebook.entries.count
    @entry = @current_notebook.entries.new

    post direct_upload_entry_path(@entry.set_identifier, notebook: @current_notebook), params: { blob: { filename: "test_image.jpg", content_type: "image/jpg", byte_size: 1000, checksum: "123" } }

    # entry didn't exist, so it got created
    assert_equal 1, @current_notebook.entries.count

    # let's reload @entry so its the persisted object
    @entry = @current_notebook.entries.find_by(identifier: @entry.identifier)

    assert_response 200
    blob = JSON.load(response.body)
    assert_equal files_entry_path(@entry, notebook: @current_notebook, filename: "test_image.jpg"), blob["file_path"]

    assert_equal 1, TemporaryEntryBlob.where(entry: @entry, notebook: @entry.notebook).count

    # now we upload a new file w/same name

    post direct_upload_entry_path(@entry.set_identifier, notebook: @current_notebook), params: { blob: { filename: "test_image.jpg", content_type: "image/jpg", byte_size: 1001, checksum: "124" } }

    # no new entries are created once this identifier exists
    assert_equal 1, @current_notebook.entries.count

    assert_response 200
    blob = JSON.load(response.body)

    assert_equal files_entry_path(@entry, notebook: @current_notebook, filename: "test_image2.jpg"), blob["file_path"]

    assert_equal 2, TemporaryEntryBlob.where(entry: @entry, notebook: @entry.notebook).count

    # at some later point we save touch the file, ideally when we hit update, thereby triggering the clean up job
    # so these TempEntryBlob entries don't linger around.

    # in the browser, the js then hits up the direct_upload.url from the response
    # and the file is uploaded, and a key is returned which is then inserted
    # into the entry form. That's a bit complicated! plus all vanilla Rails
    # so let's just skip ahead and pretend we're hitting the entries endpoint
    @entry.save

    assert_equal 0, TemporaryEntryBlob.where(entry: @entry, notebook: @entry.notebook).count
  end
end
