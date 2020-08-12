# used for representing past versions of an entry
class PastEntry < Entry
  # can't be saved
  def save
    raise "wot you doin' mate???"
  end
end
