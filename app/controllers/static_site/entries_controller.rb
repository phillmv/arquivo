module StaticSite
  class EntriesController < StaticSiteController
    before_action :set_entry, only: [:show, :edit, :update, :destroy, :files, :copy]

    # GET /entries/1
    # GET /entries/1.json
    def show
      if @entry.document?
        blob = @entry.files.blobs.first
        serve_blob(blob)

      elsif @entry.manifest?
        render plain: @entry.render_stylesheet!, content_type: 'text/css'

      # TODO: make up my mind on how to handle templates.
      # elsif @entry.template?
        # don't love it but fix later, lol do not deploy this to untrusted user contexts???
        # render inline: @entry.body, layout: "application"

      elsif @entry.note? || @entry.bookmark? || @entry.template?
        @show_thread = params[:thread].present?
        @renderer = EntryRenderer.new(@entry, remove_subject: true)
        @current_date = @entry.occurred_at.strftime("%Y-%m-%d")
      else
        render plain: "", status: 404
      end
    end

    def files
      blob = @entry.files.blobs.find_by!(filename: params[:filename])
      serve_blob(blob)
    end

    # drop `static_site/` prefix, see StaticSiteController#prepend_custom_paths
    def self.controller_path
      "entries"
    end

    private
    def set_entry

      # TODO: live-reloading
      # see if the file exists and if it does, import it

      # step 1: does it exist as a file?
      # step 2: is it markdown or yaml?
      #   step 2.1: actually this is harder to untangle
      #   will have to think about how i want to support the "normal" dump o yaml
      #   vs the "adhoc" markdown
      # step 3: parse it & add it.

      if Rails.env.development?
      @entry = EntryImporter.new(current_notebook).resolve_and_import!(params[:id])

      if @entry
        return
      end
      end

      # quick terrible hack for routing document type entries
      if params[:format]
        identifier = "#{params[:id]}.#{params[:format]}"
        @entry = Entry.find_by(identifier: identifier, notebook: current_notebook.to_s)

        # if an entry exists, great!
        if @entry
          return
        end

        # but if it doesn't, we should try again with just the
        # id params, so we can throw a 404
      end

      @entry = Entry.find_by!(identifier: params[:id], notebook: current_notebook.to_s)
    end

    def serve_blob(blob)
      path = blob.service.path_for(blob.key)
      content_type = blob.content_type
      disposition = params[:disposition]

      # Taken from ActiveStorage::DiskController#serve_file @ 6.0.2.1
      Rack::File.new(nil).serving(request, path).tap do |(status, headers, body)|
        self.status = status
        self.response_body = body

        headers.each do |name, value|
          response.headers[name] = value
        end

        response.headers["Content-Type"] = content_type ||  ActiveStorage::BaseController::DEFAULT_SEND_FILE_TYPE
        # response.headers["Content-Disposition"] = disposition ||  ActiveStorage::BaseController::DEFAULT_SEND_FILE_DISPOSITION
      end
    end
  end
end
