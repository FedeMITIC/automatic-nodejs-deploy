require 'sinatra'
require 'json'
require 'sys/proctable'
require 'dotenv'
include Sys

post '/payload' do
	request.body.rewind
  	payload_body = request.body.read
  	Dotenv.load
  	verify_signature(payload_body)
  	push = JSON.parse(payload_body)
	stop_application
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
  		if(p.name.eql? 'node')
  			puts %x`kill 18555`
  			sleep 10
  		end
  	end
end

def verify_signature(payload_body)
  	signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
  	return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end