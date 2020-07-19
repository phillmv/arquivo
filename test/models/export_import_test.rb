require 'test_helper'

class ExportImportTest < ActiveSupport::TestCase
  test "exporting smokescreen test" do
    # set up entries in two diff notebooks
    notebooks = ["test1", "test2"]

    # TODO: vary these entries over diff months & years
    # TODO: figure out how to add attachment
    # TODO: reminder about attachment filename class for sanitizing
    # identifiers
    entry_sets = {
      "test1" => create_list(:entry, 10, notebook: "test1"),
      "test2" => create_list(:entry, 10, notebook: "test2"),
    }

    Dir.mktmpdir do |export_path|
      Exporter.new(export_path).export!

      # confirm one folder per notebook
      exported_notebooks = Dir[export_path + "/*"].
        map { |s| File.basename(s) }.to_set

      assert_equal notebooks.to_set, exported_notebooks

      notebooks.each do |name|
        exported_yaml = Dir[export_path + "/#{name}*/**/*yaml"]

        # basic sanity check, one file per entry
        assert_equal entry_sets[name].size, exported_yaml.size

        hash = {}
        exported_yaml.each do |ey|
          yaml = YAML.load_file(ey)
          hash[yaml["identifier"]] = yaml

          # path should have identifier in its name
          assert_includes ey, yaml["identifier"]
        end

        # every entry should be present
        entry_sets[name].each do |entry|
          assert hash[entry.identifier]
        end
      end
    end
  end

  test "importing smokescreen test" do
    notebooks = ["work", "journal", "dev"]

    entries = notebooks.map do |notebook|
      create_list(:entry, 3, notebook: notebook)
    end.flatten

    assert_equal Entry.count, 9
    # assert 0 to confirm notebooks are created on import
    assert_equal Notebook.count, 0

    Dir.mktmpdir do |export_import_path|
      Exporter.new(export_import_path).export!

      Entry.destroy_all
      assert_equal Entry.count, 0

      Importer.new(export_import_path).import!

      assert_equal Entry.count, 9
      assert_equal Notebook.count, 3

      entries.each do |entry|
        e = Entry.where(notebook: entry.notebook,
                        identifier: entry.identifier).first

        # not nil
        assert e

        # same values!
        assert_equal e.export_attributes, entry.export_attributes

        # TODO: also do something with attachments
        # TODO: handle two entries with the same identifier but different notebooks
      end
    end
  end
end
