require 'rake/gempackagetask'

PKG_VERSION = "0.1.0"
PKG_NAME = "slimseq"

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "SLIMseq microarray facility management software."
  s.has_rdoc = false
  s.files  = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f|
     [ /\.$/, /\.log$/, /^pkg/, /\.svn/,
     /^public\/(files|xml|articles|pages|index.html)/,
     /^public\/(stylesheets|javascripts|images)\/theme/, /\~$/,
     /\/\._/, /\/#/, /^db\/schema.rb/, /^config\/database\.yml/,
     /^tmp/, /^log/ ].any? {|regex| f =~ regex }
  end
  s.require_path = '.'
  s.author = "Bruz Marzolf"
  s.email = "bmarzolf@systemsbiology.org"
  s.homepage = "http://slimseq.systemsbiology.net" 
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end