require 'rake/gempackagetask'

PKG_VERSION = "0.1.0"
PKG_NAME = "slimarray"

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "Modern weblog engine."
  s.has_rdoc = false
  s.files  = Dir.glob('**/*', File::FNM_DOTMATCH).reject do |f|
     [ /\.$/, /sqlite$/, /\.log$/, /^pkg/, /\.svn/, /^vendor\/rails/,
     /^public\/(files|xml|articles|pages|index.html)/,
     /^public\/(stylesheets|javascripts|images)\/theme/, /\~$/,
     /\/\._/, /\/#/ ].any? {|regex| f =~ regex }
  end
  s.require_path = '.'
  s.author = "Bruz Marzolf"
  s.email = "bmarzolf@systemsbiology.org"
  s.homepage = "http://slimarray.systemsbiology.net" 
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end