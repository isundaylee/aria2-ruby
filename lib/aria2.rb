require "aria2/version"

module Aria2

	class Downloader

		require 'open-uri'
		require 'json'
		require 'base64'
		require 'cgi'
		require 'net/http'

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

			def self.get(url, params = {})
				uri = URI.parse(url)

				uri.query = URI.encode_www_form(params)

				http = Net::HTTP.new(uri.host, uri.port)
				request = Net::HTTP::Get.new(uri.request_uri)

				response = http.request(request)

				{
					'code' => response.code.to_i, 
					'body' => response.body
				}
			end

			def self.rpc_path
				"http://#{@host}:#{@port}/jsonrpc"
			end

			def self.rpc_call(method, params)
				method = "aria2.#{method}"
				id = 'ruby-aria2'
				params_encoded = Base64.encode64(JSON.generate(params))

				response = get("#{self.rpc_path}", {'method' => method, 'id' => id, 'params' => params_encoded})
				answer = JSON.parse(response['body'])

				if response['code'] == 200
					answer['result']
				else
					raise "AriaDownloader error #{answer['error']['code'].to_i}: #{answer['error']['message']}"
				end
			end

	end

end

