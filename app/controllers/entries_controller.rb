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

  # GET /entries/new
  def new
    if parent_identifier = params["in_reply_to"]
      @parent_entry = Entry.find_by!(notebook: @current_notebook.name, identifier: parent_identifier)
    end

    if params[:occurred_at]
      occurred_at = DateTime.parse(params[:occurred_at])
    else
      occurred_at = Time.current
    end

    @entry = Entry.new(occurred_at: occurred_at)

    if @parent_entry
      @entry.copy_parent(@parent_entry)
    end
  end

  def save_bookmark
    entry_attributes = bookmark_params.slice(:url, :subject)
    entry_attributes[:occurred_at] = Time.now

    @entry = Entry.for_notebook(current_notebook).find_by_url(entry_attributes[:url])
    @entry ||= Entry.new(entry_attributes)
  end

  # create for bookmarks has to work differently.
  def create_or_update
    if entry_params[:url].nil?
      raise ActionController::RoutingError.new('Not Found')
    end

    if @entry = Entry.for_notebook(current_notebook).find_by_url(entry_params[:url])
    else
      @entry = Entry.new(entry_params)
      @entry.kind = "pinboard"
      @entry.notebook = current_notebook
      @entry.occurred_at ||= Time.now
    end

    respond_to do |format|
      if (@entry.new_record? && @entry.save) || @entry.update(entry_params)
        format.html do
          # TODO: test/refactor this dumb behaviour
          if params[:outside_of_bookmarklet]
            # redirect_to timeline_path(notebook: current_notebook)
            redirect_to entry_path(@entry), notice: 'Entry was successfully updated.'
          else
            render "entries/success_close_window"
          end
        end
        format.json { render :show, status: :created, location: @entry }
      else
        format.html { render :new }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /entries/1/edit
  def edit
  end

  # POST /entries
  # POST /entries.json
  # TODO: why do we support create or update in this method vs the method above?
  def create
    @entry = @current_notebook.entries.find_by(identifier: entry_params[:identifier])
    @entry ||= @current_notebook.entries.new(entry_params)

    respond_to do |format|
      if (@entry.new_record? && @entry.save) || @entry.update(entry_params)
        format.html do
          if request.referer =~ /agenda/
            redirect_back(fallback_location: timeline_path(current_notebook))
          else
            redirect_to entry_path(@entry), notice: 'Entry was successfully created.'
          end
        end
        format.json { render :show, status: :created, location: @entry }
      else
        format.html { render :new }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /entries/1
  # PATCH/PUT /entries/1.json
  def update
    respond_to do |format|
      if @entry.update(entry_params)
        if params["redirect_to_timeline"]
          format.html { redirect_to timeline_path(current_notebook) }
        else
          format.html { redirect_to entry_path(@entry), notice: 'Entry was successfully updated.' }
          format.json { render json: @entry.export_attributes, status: :ok, location: @entry }
        end
      else
        format.html { render :edit }
        format.json { render json: @entry.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /entries/1
  # DELETE /entries/1.json
  def destroy
    @entry.destroy
    respond_to do |format|
      format.html { redirect_to entries_url, notice: 'Entry was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def files
    blob = @entry.files.blobs.find_by!(filename: params[:filename])
    expires_in ActiveStorage.service_urls_expire_in
    redirect_to rails_blob_path(blob, disposition: params[:disposition])
  end

  def copy
    target_notebook = Notebook.find_by!(name: params[:target_notebook])

    copy = @entry.copy_to!(target_notebook)

    redirect_to entry_path(copy)
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

    # Never trust parameters from the scary internet, only allow the white list through.
    def entry_params
      params.require(:entry).permit(:identifier, :body, :url, :subject, :occurred_at, :in_reply_to, :hide, :occurred_date, :occurred_time, files: [])
    end

    def bookmark_params
      params.permit(:body, :url, :subject)
    end
end
