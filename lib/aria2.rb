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
				self.rpc_call('getGlobalStat', [])
				true
			rescue
				false
			end
		end

		def self.download(url, path)
			path = File.expand_path(path)
			self.rpc_call('addUri', [[url], {
				'dir' => File.dirname(path), 
				'out' => File.basename(path),
				'allow-overwrite' => 'true'
			}])
		end

		def self.query_status(gid)
			status = self.rpc_call('tellStatus', [gid, [
				'status', 
				'totalLength', 
				'completedLength', 
				'downloadSpeed', 
				'errorCode'
			]])

			status['totalLength'] = status['totalLength'].to_i
			status['completedLength'] = status['completedLength'].to_i
			status['downloadSpeed'] = status['downloadSpeed'].to_i
			status['errorCode'] = status['errorCode'].to_i

			status['progress'] = status['totalLength'] == 0 ? 
				0 :
				status['completedLength'].to_f / status['totalLength'].to_f

			status['remainingTime'] = status['downloadSpeed'] == 0 ?
				0 :
				(status['totalLength'] - status['completedLength']).to_f / status['downloadSpeed']

			status
		end

		def self.remove(gid)
			self.rpc_call('remove', [gid]) == gid
		end

		private

			def self.rpc_path
				"http://#{@host}:#{@port}/jsonrpc"
			end

			def self.rpc_call(method, params)
				method = "aria2.#{method}"
				id = 'ruby-aria2'
				params_encoded = CGI.escape(Base64.encode64(JSON.generate(params)))

				url = "#{self.rpc_path}?method=#{method}&id=#{id}&params=#{params_encoded}"
				answer = JSON.parse(open(url).read)

				answer['result']
			end

	end

end

