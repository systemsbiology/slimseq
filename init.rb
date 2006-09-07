at_exit do
  require "irb"
  require "drb/acl"
  require "sqlite"
  require "rubygems"
  require "initializer"
  require "transaction/simple"
  require "thread"
  require "open-uri"
  require "color"
end

load "script/server"