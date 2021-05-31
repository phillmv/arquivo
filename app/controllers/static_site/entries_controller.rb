module StaticSite
  class EntriesController < ApplicationController
    before_action :set_entry, only: [:show, :edit, :update, :destroy, :files, :copy]

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
    def set_entry
      @entry = Entry.find_by!(identifier: params[:id], notebook: current_notebook.to_s)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def entry_params
      params.require(:entry).permit(:body, :url, :subject, :occurred_at, :in_reply_to, :hide, :occurred_date, :occurred_time, files: [])
    end
  end
end
