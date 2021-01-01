class EntryHistory
  attr_reader :entry, :local_syncer
  def initialize(entry, path = nil)
    @entry = entry
    @local_syncer = LocalSyncer.new(entry.parent_notebook, path)
  end

  def revisions
    if defined?(@revisions)
      return @revisions
    end

    @revisions = local_syncer.entry_log(entry)
  end

  def get(sha)
    yaml = local_syncer.get_revision(entry, sha)
    PastEntry.new(YAML.load(yaml))
  end
end
