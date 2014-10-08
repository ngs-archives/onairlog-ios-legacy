require "rubygems/version"
require "rake/clean"
require "date"
require 'dotenv/tasks'
require 's3sync/sync'

APP_NAME = "OnAirLog"
SDK = "iphoneos"
WORKSPACE = File.expand_path "#{APP_NAME}.xcworkspace"
CERTIFICATES_PATH = File.expand_path 'Certificates'
PROFILES_PATH = File.expand_path 'MobileProvisionings'
BUILD_DIR = File.expand_path 'build'
KEYCHAIN_NAME = 'ios-build.keychain'

def app_type
  ENV['APP_TYPE'] || '813'
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

def run_cupertino command
  system %Q{bundle exec ios #{command} -u #{ENV['APPLE_USER']} -p #{ENV['APPLE_PASSWORD']}}
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
  system "xctool -scheme OnAirLogTests -workspace #{WORKSPACE} -sdk iphonesimulator -configuration Debug clean test -freshSimulator -freshInstall ONLY_ACTIVE_ARCH=NO"
end


namespace :ipa do
  desc 'Build .ipa file'
  task :build => :dotenv do
    system %Q{bundle exec ipa --verbose -t build -w #{WORKSPACE} -c Release -s #{scheme} --sdk iphoneos -d #{BUILD_DIR} -m #{provisioning_profile}}
  end
end

namespace :profiles do
  desc 'Download all mobileprovision files'
  task :download => :dotenv do
    system %Q{rm -rf #{PROFILES_PATH} && mkdir -p #{PROFILES_PATH}}
    Dir.chdir(PROFILES_PATH) do
      run_cupertino "profiles:download:all --type distribution"
    end
  end
  desc 'Cleans mobileprovision files'
  task :clean do
    system %Q{rm -f #{PROFILES_PATH}/*.mobileprovision}
  end
end

namespace :certificate do
  def s3path
    "#{ENV['S3_CERTIFICATE_BUCKET']}:"
  end
  def sync src, dest
    system %Q{bundle exec s3sync sync #{src} #{dest}}
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
    passphrase = ENV['CERTIFICATE_PASSPHRASE']
    %x{security create-keychain -p travis #{KEYCHAIN_NAME}}
    %x{security import #{CERTIFICATES_PATH}/apple.cer -k #{KEYCHAIN_NAME} -T /usr/bin/codesign}
    %x{security import #{CERTIFICATES_PATH}/ios_distribution.cer -k #{KEYCHAIN_NAME} -T /usr/bin/codesign}
    %x{security import #{CERTIFICATES_PATH}/ios_distribution.p12 -k #{KEYCHAIN_NAME} -P #{passphrase} -T /usr/bin/codesign}
    %x{security default-keychain -s #{KEYCHAIN_NAME}}
  end
  desc 'Remove certificates'
  task :remove => :dotenv do
    sh "security delete-keychain #{KEYCHAIN_NAME}"
  end
end

task :setup => ['pod:install', 'env:export']

