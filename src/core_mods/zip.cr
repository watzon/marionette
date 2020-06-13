require "file_utils"
require "compress/zip"

class Compress::Zip::File
  def extract(entry, dest_path = Dir.current, perms = nil)
    if entry.is_a?(String)
      entry = self.[entry]
    end
    extract_entry(entry, dest_path, perms)
  end

  def extract_all(dest_path = Dir.current, perms = nil)
    @entries.each do |entry|
      extract_entry(entry, dest_path, perms)
    end
  end

  private def extract_entry(entry : Entry, dest_path, perms = nil)
    dest_path = ::File.join(dest_path, entry.filename)
    if entry.dir?
      create_directory(dest_path)
    else
      create_file(entry, dest_path, perms)
    end
  end

  private def create_directory(dest_path)
    unless ::File.directory?(dest_path)
      ::FileUtils.mkdir_p(dest_path)
    end
  end

  private def create_file(entry, dest_path, perms = nil)
    if ::File.exists?(dest_path)
      raise Error.new("File #{dest_path} already exists")
    end
    entry.open { |io| ::File.write(dest_path, io, perms) }
  end
end
