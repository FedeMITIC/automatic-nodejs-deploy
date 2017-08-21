# Run as SUDO in case of permissions problems

require 'sinatra'			# gem install sinatra
require 'sys/proctable'		# gem install sys-proctable --platform platform_name (see https://github.com/djberg96/sys-proctable)
require 'dotenv'			# gem install dotenv
require 'json'
include Sys

# Change the URL route according to your need. See (https://github.com/sinatra/sinatra#routes) for documentation about routing.
# This route receives ONLY webhooks with 'Content type' set to 'application/json'.
post '/payload' do
  return halt 500, unless Rack::Utils.secure_compare('push', request.env['HTTP_X_GITHUB_EVENT'])
  request.body.rewind
  payload_body = request.body.read
  Dotenv.load
  verify_signature(payload_body)
  push = JSON.parse(payload_body)
  stop_application
  # Edit the .env file in the root according to your needs
  Dir.chdir ENV['APP_FOLDER']
  %x`git pull`
  sleep 30
  thread = Thread.new{start_application}
  start_build(thread)
end

def start_build(thread)
  %x`npm install`
  thread.run
end

def start_application
  Thread.stop
  %x`npm start`
end

def stop_application
  process = ProcTable.ps
  process.each do |p|
    # Edit the name of the process that will be stopped according to your needs
    if(p.name.eql? 'node')
      puts %x`kill #{p.pid}`
  	  sleep 10
    end
  end
end

def verify_signature(payload_body)
  # Edit the .env file in the root adding your secret token (the token inserted in the GitHub hook)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end