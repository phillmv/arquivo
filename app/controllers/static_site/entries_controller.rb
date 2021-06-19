module StaticSite
  class EntriesController < ApplicationController
    before_action :set_entry, only: [:show, :edit, :update, :destroy, :files, :copy]

    # GET /entries/1
    # GET /entries/1.json
    def show
      if @entry.document?
        blob = @entry.files.blobs.first
        expires_in ActiveStorage.service_urls_expire_in
        redirect_to rails_blob_path(blob, disposition: params[:disposition])
      else
        @show_thread = params[:thread].present?
        @renderer = EntryRenderer.new(@entry)
        @current_date = @entry.occurred_at.strftime("%Y-%m-%d")
      end
    end

    def files
      blob = @entry.files.blobs.find_by!(filename: params[:filename])
      expires_in ActiveStorage.service_urls_expire_in
      redirect_to rails_blob_url(blob, disposition: params[:disposition])
    end

    private
    def set_entry
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
  end
end
