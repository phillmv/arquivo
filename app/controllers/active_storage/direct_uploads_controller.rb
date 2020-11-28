class ActiveStorage::DirectUploadsController < ActiveStorage::BaseController
  def create
    # purpose of this "monkeypatch" is to provide attachment urls that are tied
    # to the entry's identifier (as opposed to the default signed blob url)
    # if the entry already exists, great
    # if it doesn't, we want to guarantee that this url will work, by creating the entry
    @entry = nil

    # TODO: why make this param optional?
    if params[:id].blank?
      raise "why are we calling this without an identifier?"
    end
    identifier = params[:id]

    Entry.transaction do
      @entry = Entry.for_notebook(params[:notebook]).find_by(identifier: identifier)
      unless @entry
        @entry = Entry.for_notebook(params[:notebook]).create(identifier: identifier, body: "DRAFT")
      end
    end


    blob_args = blob_params.dup

    # TODO: clean up, more importantly, TEST!!!!
    while @entry.files.blobs.find_by(filename: blob_args[:filename]) || TemporaryEntryBlob.given(@entry, blob_args[:filename])
      blob_args[:filename] = increment_filename_number(blob_args[:filename])
    end

    blob = ActiveStorage::Blob.create_before_direct_upload!(**blob_args)
    TemporaryEntryBlob.add(@entry, blob.filename)
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
    }).merge(file_path: Rails.application.routes.url_helpers.files_entry_path(entry, blob.filename, notebook: entry.notebook, only_path: true))
  end

  def increment_filename_number(filename)
    file_ext = File.extname(filename)
    basename = filename.delete_suffix(file_ext)

    number = /\d+$/.match(basename).to_a[0]
    if number
      basename = basename.delete_suffix(number)
    else
      number = 1
    end

    number = number.succ
    basename = [basename,number,file_ext].join
  end
end
