require "aria2/version"

module Aria2

	class Downloader

		require 'open-uri'
		require 'json'
		require 'base64'
		require 'cgi'

		def self.new(host = 'localhost', port = 6800)
			@host = host
			@port = port
			self
		end

		def self.check
			begin
				self.rpc_call('getGlobalStat', {})
				true
			rescue
				false
			end
		end

		private

			def self.rpc_path
				"http://#{@host}:#{@port}/jsonrpc"
			end

			def self.rpc_call(method, params)
				method = "aria2.#{method}"
				id = 'ruby-aria2'
				params_encoded = 
					(params && !params.empty?) ? 
					CGI.escape(Base64.encode64(JSON.generate(params))) :
					''

				url = "#{self.rpc_path}?method=#{method}&id=#{id}&params=#{params_encoded}"
				answer = JSON.parse(open(url).read)

				answer['result']
			end

	end

end

