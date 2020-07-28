class ActiveStorage::DirectUploadsController < ActiveStorage::BaseController
  def create
    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)

    # purpose of this "monkeypatch" is to provide attachment urls that are tied
    # to the entry's identifier (as opposed to the default signed blob url)
    # if the entry already exists, great
    # if it doesn't, we want to guarantee that this url will work, by creating the entry
    existing_entry = nil

    if params[:id]
      Entry.transaction do

        existing_entry = Entry.for_notebook(params[:notebook]).find_by(identifier: params[:id])
        unless existing_entry
          existing_entry = Entry.for_notebook(params[:notebook]).create(identifier: params[:id], body: "DRAFT")
        end
      end

    end
    render json: direct_upload_json(blob, existing_entry)
  end

  private
  def blob_args
    params.require(:blob).permit(:filename, :byte_size, :checksum, :content_type, :metadata).to_h.symbolize_keys
  end

  def direct_upload_json(blob, entry)
    blob.as_json(root: false, methods: :signed_id).merge(direct_upload: {
      url: blob.service_url_for_direct_upload,
      headers: blob.service_headers_for_direct_upload
    }).merge(file_path: Rails.application.routes.url_helpers.files_entry_path(entry, blob.filename, notebook: entry.notebook, only_path: true))
  end
end
