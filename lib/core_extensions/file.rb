class File
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
end
