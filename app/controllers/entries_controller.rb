class EntriesController < ApplicationController
  before_action :set_entry, only: [:show, :edit, :update, :destroy]

  # GET /entries
  # GET /entries.json
  def index
    @entries = Entry.all
  end

  # GET /entries/1
  # GET /entries/1.json
  def show
    @renderer = EntryRenderer.new(@entry)
  end

  # GET /entries/new
  def new
    @entry = Entry.new(occurred_at: Time.now)
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
        format.html { redirect_to timeline_path(notebook: current_notebook), notice: 'Entry was successfully created.' }
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
        format.html { redirect_to entry_path(@entry, notebook: current_notebook), notice: 'Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: @entry }
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
      params.require(:entry).permit(:body, :occurred_at, files: [])
    end
end
