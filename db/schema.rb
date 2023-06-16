# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_06_15_205741) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.integer "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cached_blob_filenames", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "entry_identifier", null: false
    t.string "filename", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook", "entry_identifier", "filename"], name: "idx_temp_entry_blob"
  end

  create_table "calendar_imports", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "title"
    t.string "url", null: false
    t.datetime "last_imported_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook"], name: "index_calendar_imports_on_notebook"
  end

  create_table "contact_email_addresses", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.string "handle"
    t.string "address"
    t.string "label"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_email_addresses_on_contact_id"
  end

  create_table "contact_entries", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_entries_on_contact_id"
    t.index ["entry_id"], name: "index_contact_entries_on_entry_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name"
    t.string "first_name"
    t.string "last_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notebook", default: "", null: false
    t.index ["name"], name: "index_contacts_on_name"
    t.index ["notebook"], name: "index_contacts_on_notebook"
  end

  create_table "entries", force: :cascade do |t|
    t.string "notebook", null: false
    t.text "body"
    t.text "metadata"
    t.string "kind"
    t.string "source"
    t.string "url"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.datetime "occurred_at", precision: nil
    t.datetime "ended_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "summary"
    t.string "identifier"
    t.string "subject"
    t.string "from"
    t.string "to"
    t.string "in_reply_to"
    t.string "state"
    t.boolean "hide", default: false, null: false
    t.string "thread_identifier"
    t.index ["notebook", "identifier"], name: "index_entries_on_notebook_and_identifier", unique: true
    t.index ["notebook"], name: "index_entries_notebook"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_feature_flags_on_name"
  end

  create_table "i_calendar_entries", force: :cascade do |t|
    t.integer "calendar_import_id", null: false
    t.string "name"
    t.string "uid"
    t.datetime "recurrence_id", precision: nil
    t.string "sequence"
    t.date "start_date"
    t.date "end_date"
    t.datetime "start_time", precision: nil
    t.datetime "end_time", precision: nil
    t.boolean "recurs"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_imported_at", precision: nil
    t.index ["calendar_import_id"], name: "index_i_calendar_entries_on_calendar_import_id"
  end

  create_table "key_values", force: :cascade do |t|
    t.string "namespace"
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace", "key"], name: "index_key_values_on_namespace_and_key"
  end

  create_table "link_entries", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.integer "link_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_link_entries_on_entry_id"
    t.index ["link_id"], name: "index_link_entries_on_link_id"
  end

  create_table "links", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.string "identifier", null: false
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_links_on_identifier"
    t.index ["notebook_id"], name: "index_links_on_notebook_id"
    t.index ["url"], name: "index_links_on_url"
  end

  create_table "notebooks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "colour", default: "#0366d6", null: false
    t.string "import_path"
    t.string "private_key_filename"
    t.string "remote"
    t.text "private_key"
  end

  create_table "saved_searches", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "octicon"
    t.string "name", null: false
    t.string "query", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook"], name: "index_saved_searches_on_notebook"
  end

  create_table "sync_states", force: :cascade do |t|
    t.integer "notebook_id", null: false
    t.string "sha"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sync_states_on_created_at"
    t.index ["notebook_id"], name: "index_sync_states_on_notebook_id"
  end

  create_table "tag_entries", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "entry_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_tag_entries_on_entry_id"
    t.index ["tag_id"], name: "index_tag_entries_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notebook"], name: "index_tags_on_notebook"
  end

  create_table "todo_list_items", force: :cascade do |t|
    t.string "notebook", null: false
    t.integer "entry_id", null: false
    t.integer "todo_list_id", null: false
    t.boolean "checked", default: false
    t.string "source"
    t.datetime "occurred_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checked"], name: "index_todo_list_items_on_checked"
    t.index ["entry_id"], name: "index_todo_list_items_on_entry_id"
    t.index ["notebook"], name: "index_todo_list_items_on_notebook"
    t.index ["occurred_at"], name: "index_todo_list_items_on_occurred_at"
    t.index ["source"], name: "index_todo_list_items_on_source"
    t.index ["todo_list_id"], name: "index_todo_list_items_on_todo_list_id"
  end

  create_table "todo_lists", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entry_id"], name: "index_todo_lists_on_entry_id"
  end

  create_table "view_preferences", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "identifier"
    t.string "key"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["identifier"], name: "index_view_preferences_on_identifier"
    t.index ["key"], name: "index_view_preferences_on_key"
    t.index ["notebook"], name: "index_view_preferences_on_notebook"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contact_email_addresses", "contacts"
  add_foreign_key "contact_entries", "contacts"
  add_foreign_key "contact_entries", "entries"
  add_foreign_key "i_calendar_entries", "calendar_imports"
  add_foreign_key "link_entries", "entries"
  add_foreign_key "sync_states", "notebooks"
  add_foreign_key "todo_list_items", "entries"
  add_foreign_key "todo_list_items", "todo_lists"
  add_foreign_key "todo_lists", "entries"
end
