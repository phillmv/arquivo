# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_13_024023) do

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "calendar_imports", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "title"
    t.string "url", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "last_imported_at"
    t.index ["notebook"], name: "index_calendar_imports_on_notebook"
  end

  create_table "contact_email_addresses", force: :cascade do |t|
    t.integer "contact_id", null: false
    t.string "handle"
    t.string "address"
    t.string "label"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["contact_id"], name: "index_contact_email_addresses_on_contact_id"
  end

  create_table "contact_entries", force: :cascade do |t|
    t.integer "entry_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["contact_id"], name: "index_contact_entries_on_contact_id"
    t.index ["entry_id"], name: "index_contact_entries_on_entry_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name"
    t.string "first_name"
    t.string "last_name"
    t.text "notes"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.datetime "occurred_at"
    t.datetime "ended_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "summary"
    t.string "identifier"
    t.string "subject"
    t.string "from"
    t.string "to"
    t.string "in_reply_to"
    t.string "state"
    t.boolean "hide", default: false, null: false
    t.index ["notebook", "identifier"], name: "index_entries_on_notebook_and_identifier", unique: true
    t.index ["notebook"], name: "index_entries_notebook"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.string "name"
    t.boolean "active", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_feature_flags_on_name"
  end

  create_table "i_calendar_entries", force: :cascade do |t|
    t.integer "calendar_import_id", null: false
    t.string "name"
    t.string "uid"
    t.datetime "recurrence_id"
    t.string "sequence"
    t.date "start_date"
    t.date "end_date"
    t.datetime "start_time"
    t.datetime "end_time"
    t.boolean "recurs"
    t.text "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "last_imported_at"
    t.index ["calendar_import_id"], name: "index_i_calendar_entries_on_calendar_import_id"
  end

  create_table "key_values", force: :cascade do |t|
    t.string "namespace"
    t.string "key"
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["namespace", "key"], name: "index_key_values_on_namespace_and_key"
  end

  create_table "notebooks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "saved_searches", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "octicon"
    t.string "name", null: false
    t.string "query", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["notebook"], name: "index_saved_searches_on_notebook"
  end

  create_table "tag_entries", force: :cascade do |t|
    t.integer "tag_id"
    t.integer "entry_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["entry_id"], name: "index_tag_entries_on_entry_id"
    t.index ["tag_id"], name: "index_tag_entries_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["notebook"], name: "index_tags_on_notebook"
  end

  create_table "view_preferences", force: :cascade do |t|
    t.string "notebook", null: false
    t.string "identifier"
    t.string "key"
    t.string "value"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["identifier"], name: "index_view_preferences_on_identifier"
    t.index ["key"], name: "index_view_preferences_on_key"
    t.index ["notebook"], name: "index_view_preferences_on_notebook"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "contact_email_addresses", "contacts"
  add_foreign_key "contact_entries", "contacts"
  add_foreign_key "contact_entries", "entries"
  add_foreign_key "i_calendar_entries", "calendar_imports"
end
