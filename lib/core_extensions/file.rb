class File
  # don't use this! use File.read instead
  def self.slurp(path)
    old_irs=$/
    $/=nil                      # read the whole file with one gets
    contents=''
    File.open(path) {|file| contents=file.gets } # slurp!
    $/=old_irs
    contents
  end

  def self.spit(path,contents)
    File.open(path,"w") do |f|
      f.puts contents
    end
  end

  def self.chop_ext(path)
    File.join(File.dirname(path),File.basename(path,File.extname(path)))
  end

  def self.replace_ext(path,ext)
    [chop_ext(path),ext].join('.')
  end

end
