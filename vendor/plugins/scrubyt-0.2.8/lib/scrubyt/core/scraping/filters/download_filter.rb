require 'net/http'
require 'fileutils'

module Scrubyt
  class DownloadFilter < BaseFilter

    def evaluate(source)
      download_file(source)
    end #end of method

    def to_sexp
      [:str, @example]
    end #end of method to_sexp

private
    def download_file(source)
      host_name = @parent_pattern.evaluation_context.extractor.get_host_name
      outfile = nil
      base_url = host_name.scan(/http:\/\/(.+?)\//)[0][0]
      return '' if source.size < 4
      file_name = source.scan(/.+\/(.*)/)[0][0]
      Net::HTTP.start(base_url) { |http|
        resp = http.get(source)
        outfile = DownloadFilter.find_nonexisting_file_name(File.join(@example, file_name))
        FileUtils.mkdir_p @example
        open(outfile, 'wb') {|f| f.write(resp.body) }
       }
       outfile.scan(/.+\/(.*)/)[0][0]
    end

   def self.find_nonexisting_file_name(file_name)
      already_found = false
      loop do
        if File.exists? file_name
          if already_found
            last_no = file_name.scan(/_(\d+)\./)[0][0]
            file_name.sub!(/_#{last_no}\./) {"_#{(last_no.to_i+1).to_s}."}
          else
            file_name.sub!(/\./) {"_1\."}
            already_found = true
          end
        else
          break
        end
      end
      file_name
   end #end of method
  end #End of class DownloadFilter
end #End of module Scrubyt
