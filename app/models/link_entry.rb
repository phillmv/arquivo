class LinkEntry < ApplicationRecord
  belongs_to :entry
  belongs_to :link, class_name: "Entry", foreign_key: :link_id, primary_key: :id
end
