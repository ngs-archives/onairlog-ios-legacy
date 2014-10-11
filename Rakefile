require "rubygems/version"
require "rake/clean"
require "date"
require 'dotenv/tasks'
require 'command-builder'

APP_NAME = "OnAirLog"
SDK = "iphoneos"
WORKSPACE = File.expand_path "#{APP_NAME}.xcworkspace"
CERTIFICATES_PATH = File.expand_path 'Certificates'
PROFILES_PATH = File.expand_path 'MobileProvisionings'
BUILD_DIR = File.expand_path 'build'
KEYCHAIN_NAME = 'ios-build.keychain'

class CommandBuilder
  def system!
    system to_s
    exit $?.exitstatus if $?.exitstatus > 0
  end
end

def app_type
  ENV['APP_TYPE'] || '813'
end

def bundle_exec command, args = {}
  cmd = CommandBuilder.new :bundle
  command = command.to_s.split ' ' unless command.is_a? Array
  cmd << 'exec'
  command.each{|c| cmd << c.to_s }
  args.each {|k, v| cmd[k.to_sym] = v }
  cmd
end

def scheme
  "#{APP_NAME}#{app_type}"
end

def production?
  false
end

def provisioning_profile
  "#{PROFILES_PATH}/#{scheme}#{production? ? 'Distribution' : 'AdHoc'}"
end

def cupertino command, args = {}
  bundle_exec([:ios, command], args.merge(
    username: ENV['APPLE_USER'],
    password: ENV['APPLE_PASSWORD']
  )).system!
end

def shenzhen command, args = {}
  cmd = bundle_exec :ipa
  cmd << :trace
  cmd << :verbose
  cmd << command.to_s
  args.each {|k, v| cmd[k.to_sym] = v }
  cmd.system!
end

def security command, args = {}
  cmd = CommandBuilder.new :security
  command = command.to_s.split ' ' unless command.is_a? Array
  command.each {|c| cmd << c.to_s }
  args.each {|k, v| cmd[k.to_sym] = v }
  cmd
end

def xctool command, args = {}
  cmd = CommandBuilder.new :xctool, '- - '.split('')
  command = command.to_s.split ' ' unless command.is_a? Array
  args = {
    scheme: 'OnAirLogTests',
    workspace: WORKSPACE,
    sdk: 'iphonesimulator',
    configuration: 'Debug'
  }.merge args
  args.each {|k, v| cmd[k.to_sym] = v }
  command.each {|c| cmd << c.to_s }
  cmd
end

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

task :test do
  xctool 'build test'
end


namespace :ipa do
  desc 'Build .ipa file'
  task :build => :'env:export' do
    shenzhen :build, {
      workspace: WORKSPACE,
      configuration: 'Release',
      scheme: scheme,
      sdk: 'iphoneos',
      destination: BUILD_DIR,
      embed: provisioning_profile
    }
  end
  namespace :distribute do
    desc 'Publish .ipa file to Amazon S3'
    task :s3 do
      shenzhen 'distribute:s3', {
        file: File.join(BUILD_DIR, "#{scheme}.ipa"),
        dsym: File.join(BUILD_DIR, "#{scheme}.dsym.zip"),
        acl: 'private'
      }
    end
  end
end

namespace :profiles do
  desc 'Download all mobileprovision files'
  task :download => :clean do
    mkpath PROFILES_PATH
    Dir.chdir(PROFILES_PATH) do
      cupertino 'profiles:download:all', type: :distribution
    end
  end
  desc 'Install mobileprovision files'
  task :install => :dotenv do
    cmd = CommandBuilder.new :'/bin/sh'
    cmd << File.expand_path('install-mobileprovisioning.sh', 'Scripts')
    cmd.system!
  end

  desc 'Clean mobileprovision files'
  task :clean => :dotenv do
    rmtree PROFILES_PATH
  end
end

namespace :certificate do
  def s3path
    "#{ENV['S3_CERTIFICATE_BUCKET']}:"
  end
  def sync src, dest
    bundle_exec([:s3sync, :sync, src, dest]).system!
  end
  desc 'Download certificates from S3'
  task :download => :dotenv do
    sync s3path, CERTIFICATES_PATH
  end
  desc 'Upload certificates from S3'
  task :upload => :dotenv do
    sync CERTIFICATES_PATH, s3path
  end
  desc 'Add certificates'
  task :add => :download do
    def import name, args = {}
      security ['import', "#{CERTIFICATES_PATH}/#{name}"], {
        k: KEYCHAIN_NAME,
        T: '/usr/bin/codesign'
      }.merge(args).system!
    end
    cmd = security 'create-keychain', p: 'travis'
    cmd << KEYCHAIN_NAME
    cmd.system!
    import 'apple.cer'
    import 'ios_distribution.cer'
    import 'ios_distribution.p12', P: ENV['CERTIFICATE_PASSPHRASE']
    security('default-keychain', s: KEYCHAIN_NAME).system!
  end
  desc 'Remove certificates'
  task :remove => :dotenv do
    security(['delete-keychain', KEYCHAIN_NAME]).system!
  end
end

task :setup => ['pod:install', 'env:export', 'certificate:download']

