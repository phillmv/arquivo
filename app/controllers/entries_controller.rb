class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :destroy]

  # GET /entries
  # GET /entries.json
  def index
    @entries = Entry.all.paginate(page: params[:page])
  end

  # GET /entries/1
  # GET /entries/1.json
  def show
    @renderer = EntryRenderer.new(@entry)
    @current_date = @entry.occurred_at.strftime("%Y-%m-%d")
  end

  # GET /entries/new
  def new
    if parent_identifier = params["in_reply_to"]
      @parent_entry = Entry.find_by!(notebook: @current_notebook.name, identifier: parent_identifier)
    end

    @entry = Entry.new(occurred_at: Time.now)
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
          render "entries/success_close_window"
          # redirect_to timeline_path(notebook: current_notebook), notice: 'Entry was successfully created.'
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
  def create
    @entry = Entry.new(entry_params)
    @entry.notebook = current_notebook
    @entry.occurred_at ||= Time.now

    respond_to do |format|
      if @entry.save
        format.html do
          if request.referer =~ /agenda/
            redirect_back(fallback_location: timeline_path(notebook: current_notebook))
          else
            redirect_to timeline_path(notebook: current_notebook), notice: 'Entry was successfully created.'
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
          format.html { redirect_to timeline_path(notebook: current_notebook) }
        else
          format.html { redirect_to entry_path(@entry, notebook: current_notebook), notice: 'Entry was successfully updated.' }
          format.json { render :show, status: :ok, location: @entry }
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
      params.require(:entry).permit(:body, :url, :subject, :occurred_at, :in_reply_to, :hide, files: [])
    end

    def bookmark_params
      params.permit(:body, :url, :subject)
    end
end
