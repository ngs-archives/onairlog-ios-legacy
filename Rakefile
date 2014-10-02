require "rubygems/version"
require "rake/clean"
require "date"
require 'dotenv/tasks'

APP_NAME = "OnAirLog"

namespace :pod do
  desc 'Install CocoaPods libraries'
  task :install => :dotenv do
    require 'cocoapods'
    Pod::Command.run %w{install}
  end
end

namespace :env do
  desc 'Generate Environment.swift'
  task :export => :dotenv do
    prefix = "#{APP_NAME.upcase}_"
    code = ''
    ENV.each{|k, v|
      if k.start_with?(prefix)
        code += %Q{let #{k.sub prefix, ''} = "#{v}"\n}
      end
    }
    file = File.join __dir__, APP_NAME, 'Environment.swift'
    File.write file, code
  end
end

task :setup => ['pod:install', 'env:export']

