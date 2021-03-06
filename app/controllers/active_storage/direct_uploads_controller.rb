class ActiveStorage::DirectUploadsController < ActiveStorage::BaseController
  def create
    # purpose of this "monkeypatch" is to provide attachment urls that are tied
    # to the entry's identifier (as opposed to the default signed blob url)
    # if the entry already exists, great
    # if it doesn't, we want to guarantee that this url will work, by creating the entry
    if (identifier = params[:id]).blank?
      raise "why are we calling this without an identifier?"
    end

    blob_args = blob_params.dup
    filename = blob_args[:filename]
    @entry = nil

    Entry.transaction do
      @entry = Entry.for_notebook(params[:notebook]).find_by(identifier: identifier)
      unless @entry
        @entry = Entry.for_notebook(params[:notebook]).create(identifier: identifier, body: "DRAFT")
      end
    end

    while CachedBlobFilename.taken?(@entry, filename)
      filename = CachedBlobFilename.increment_filename(filename)
    end

    CachedBlobFilename.add(@entry, filename)

    blob_args[:filename] = filename
    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)

    render json: direct_upload_json(blob, @entry)
  end

  private
  def blob_params
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, :metadata).to_h.symbolize_keys
  end

  def direct_upload_json(blob, entry)
    blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload
    }).merge(file_path: Rails.application.routes.url_helpers.files_entry_path(entry, blob.filename, notebook: entry.notebook, owner: entry.parent_notebook.owner, only_path: true))
  end
end
