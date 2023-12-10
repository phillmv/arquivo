class ChecksumDetector
  def self.do_the_thing
  end
end

# files = Dir["/data/notebooks/*/*/*/*/*/*/file*yaml"]
def check_all_the_checksums()
  files = Dir["/Users/phillmv/Documents/arquivo/work/*/*/*/*/files/file*yaml"]
  match_fail = []
  match_match = []
  cmds = []
  files.each do |file|
    puts file
    file_attr = YAML.load_file(file, permitted_classes: Arquivo::PERMITTED_YAML, aliases: true)
    checksum = file_attr["checksum"]
    entry_files_path = File.dirname(file)
    attachment_filepath = File.join(entry_files_path, file_attr["filename"])

    new_checksum = compute_checksum_in_chunks(File.open(attachment_filepath))
    if new_checksum != checksum
      match_fail << [file, attachment_filepath]
      puts "failed for #{file}, rewriting:"
      blob = ActiveStorage::Blob.find_by(key: file_attr["key"])
      if blob

        File.open(attachment_filepath,  "wb") do |io|
          io.print blob.download
        end

        cmds << "cp #{blob.service.path_for(blob.key)} '#{attachment_filepath}'"
      else
        puts "NO REWRITE\n\n\n\n"
      end
    else
      match_match << [file, attachment_filepath]
    end
  end

  puts "#{match_fail.size} / #{files.size} checks failed. the following need to be looked at:"
  match_fail.each do |f, a|
    puts a
  end

  puts "-----\n\nthese were ok:"
  match_match.each do |f, a|
    puts a
  end

  puts "omg"
  cmds.each do |c|
    puts c
  end
end


def compute_checksum_in_chunks(io)
  OpenSSL::Digest::MD5.new.tap do |checksum|
    while chunk = io.read(5.megabytes)
      checksum << chunk
    end

    io.rewind
  end.base64digest
end

