class EntriesController < ApplicationController
  before_action :find_or_build_entry, only: [:show, :edit]
  before_action :find_entry, only: [:update, :destroy, :copy]

  # GET /entries
  # GET /entries.json
  def index
    @entries = Entry.all.paginate(page: params[:page])
  end

  # GET /entries/1
  # GET /entries/1.json
  def show
    if @entry.document?
      # TODO: why import these at all why not just open the frigging thing?
      blob = @entry.files.blobs.first
      expires_in ActiveStorage.service_urls_expire_in
      redirect_to rails_blob_path(blob, disposition: params[:disposition])
    else
      @title = @entry.subject
      @show_thread = params[:thread].present?
      @renderer = EntryRenderer.new(@entry)
      @current_date = @entry.occurred_at.strftime("%Y-%m-%d")

      # TODO: test this in a controller kthnx
      links_rel = @entry.parent_notebook.links
      @links = links_rel.where(identifier: @entry.identifier).or(links_rel.where(url: @entry.identifier))
      @linking_entries = @entry.parent_notebook.entries.where(id: LinkEntry.where(link_id: @links).select(:entry_id)).order(:occurred_at).limit(100)

      @todo_list_items = TodoListItem.where(entry_id: @entry.whole_thread.pluck(:id), checked: false).order(occurred_at: :desc)
    end
  end

  # GET /entries/new
  def new
    @title = "New entry"
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
      @todo_list_items = TodoListItem.where(entry_id: @parent_entry.whole_thread, checked: false).order(occurred_at: :desc)
    end
  end

  def save_bookmark
    url, subject = bookmark_params.values_at(:url, :subject)
    url = UrlNormalizer.new(url).to_s
    entry_attributes = {
      url: url,
      subject: subject,
      occurred_at: Time.now
    }

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
    @title = "Editing #{@entry.subject}"
    @parent_entry = @entry.parent
    # hack hack hack for threaded_todos
    @todo_list_items = TodoListItem.where(entry_id: @entry.whole_thread, checked: false).order(occurred_at: :desc)
  end

  # POST /entries
  # POST /entries.json
  # TODO: why do we support create or update in this method vs the method above?
  def create
    maker = EntryMaker.new(current_notebook)
    @entry, err = maker.create(entry_params)

    respond_to do |format|
      if !err
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
    # TODO: test this obviously insane behaviour
    # are we dealing with a document entry with `files` in the identifier?
    doc_identifier = File.join(params["id"], "files", params["filename"])
    @entry = current_notebook.entries.find_by(identifier: doc_identifier)

    if @entry.nil?
      @entry = current_notebook.entries.find_by!(identifier: params[:id])
    end

    # TODO: undo this when we move documents to just reading the file off disk
    if @entry.document?
      blob = @entry.files.blobs.first
    else
      blob = @entry.files.blobs.find_by(filename: params[:filename])
    end

    expires_in ActiveStorage.service_urls_expire_in
    redirect_to rails_blob_path(blob, disposition: params[:disposition])
  end

  def copy
    target_notebook = Notebook.find_by!(name: params[:target_notebook])

    copy = @entry.copy_to!(target_notebook)

    redirect_to entry_path(copy)
  end

  private
  def find_entry
    identifier = params[:id]
    # quick terrible hack for routing document type entries
    if params[:format]
      identifier = "#{identifier}.#{params[:format]}"
    end

    @entry = current_notebook.entries.find_by!(identifier: identifier)
  end

  # if we're asked to visit a page whose identifier doesn't exist yet,
  # then we should prompt the user to create an entry with that identifier
  # this is used to support wikified links that are typed ahead of time, and
  # rendered in red; clicking on the red link lets you fill in the entry.
  def find_or_build_entry
    identifier = params[:id]
    # quick terrible hack for routing document type entries
    if params[:format]
      identifier = "#{identifier}.#{params[:format]}"
    end

    @entry = current_notebook.entries.find_by(identifier: identifier)

    if @entry.nil?
      @entry = current_notebook.entries.build(identifier: identifier,
                                              occurred_at: Time.current)

      if action_name == "show"
        redirect_to edit_entry_path(@entry)
      else
        # if the referrer exists,
        referrer = request.referrer
        if referrer
          nwo = current_notebook.name_with_owner
          i = referrer.index(nwo)
          # referrer[index + size + "/"]
          referrer_identifier = referrer[i+nwo.size+1..-1]

          # and there's a valid identifier in the referrer,
          # then we set the parent entry so that wikified links
          # reply to / are threaded with the entry that was "clicked thru"
          @parent_entry = current_notebook.entries.find_by(identifier: referrer_identifier)
        end
      end
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def entry_params
    params.require(:entry).permit(:identifier, :generated_identifier, :body, :url, :subject, :occurred_at, :in_reply_to, :hide, :occurred_date, :occurred_time, files: [])
  end

  def bookmark_params
    params.permit(:body, :url, :subject)
  end
end
