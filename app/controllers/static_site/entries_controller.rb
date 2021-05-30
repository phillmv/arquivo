module StaticSite
  class EntriesController < ApplicationController
    before_action :set_entry, only: [:show, :edit, :update, :destroy, :files, :copy]

    # GET /entries
    # GET /entries.json
    def index
      @entries = Entry.all.paginate(page: params[:page])
    end

    # GET /entries/1
    # GET /entries/1.json
    def show
      @show_thread = params[:thread].present?
      @renderer = EntryRenderer.new(@entry)
      @current_date = @entry.occurred_at.strftime("%Y-%m-%d")
    end

    def files
      blob = @entry.files.blobs.find_by!(filename: params[:filename])
      expires_in ActiveStorage.service_urls_expire_in
      redirect_to rails_blob_url(blob, disposition: params[:disposition])
    end

    private
    # TODO: We can delete this now, right?
    def set_entry
      # quick terrible hack for routing ical uuids
      # that are email addresses
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def entry_params
      params.require(:entry).permit(:body, :url, :subject, :occurred_at, :in_reply_to, :hide, :occurred_date, :occurred_time, files: [])
    end

    def create_entry_params
      params.require(:entry).permit(:identifier, :body, :url, :subject, :occurred_at, :in_reply_to, :hide, :occurred_date, :occurred_time, files: [])
    end

    def bookmark_params
      params.permit(:body, :url, :subject)
    end
  end
end
