require "aria2/version"

module Aria2

	class Downloader

		require 'open-uri'
		require 'json'
		require 'base64'
		require 'cgi'
		require 'net/http'

		def self.new(host = 'localhost', port = 6800, token = '')
			@host = host
			@port = port
			@token = token
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

		def self.remove(gid)
			self.rpc_call('remove', [gid]) == gid
			status
		end

		def self.forceRemove(gid)
			status = self.rpc_call('forceRemove',[gid]) == gid
			status
		end

		def self.pause(gid)
			status = self.rpc_call('pause', [gid]) == gid
			status
		end

		def self.pauseAll()
			status = self.rpc_call('pauseAll', [])
			status
		end

		def self.forcePause(gid)
			status = self.rpc_call('forcePause', [gid]) == gid
			status
		end

		def self.forcePauseAll()
			status = self.rpc_call('forcePauseAll', [])
			status
		end

		def self.unPause(gid)
			status = self.rpc_call('unPause', [gid]) == gid
			status
		end

		def self.unPauseAll()
			status = self.rpc_call('unPauseAll', [])
			status
		end


		def self.download(url, path)
			path = File.expand_path(path)
			self.rpc_call('addUri', [[url], {
				'dir' => File.dirname(path), 
				'out' => File.basename(path),
				'allow-overwrite' => 'true'
			}])
		end


		def self.getUris(gid) 
			uris = self.rpc_call('getUris', [gid]) == gid
			uris

		end

		def self.getFiles(gid)
			files = self.rpc_call('getFiles', [gid]) == gid
			files
		end

		def self.getPeers(gid)
			peers = self.rpc_call('getPeers', [gid]) == gid
			peers
		
		end

		def self.getServers(gid)
			servers = self.rpc_call('getServers', [gid]) == gid
			servers
		end

		def self.getOption(gid)
			option = self.rpc_call('getOption', [gid]) == gid
			option
		end

		def self.purgeDownloadResult()
			status = self.rpc_call('purgeDownloadResult')
			status
		end

		def self.removeDownloadResult(gid)
			status = self.rpc_call('removeDownloadResult', [gid]) == gid
			status
		end

		def self.getVersion()
			version = self.rpc_call('getVersion', [])
			version

		end

		def self.getSessionInfo()
			sessionId = self.rpc_call('getSessionInfo', [])
			sessionId

		end

		def self.shutdown()
			status = self.rpc_call('shutdown', [])
			status
		end

		def self.forceShutdown()
			status = self.rpc_call('forceShutdown', [])
			status
		end

		def self.saveSession()
			status = self.rpc_call('saveSession', [])
			status
		end

		def self.addTorrent(torrent)
			gid = self.rpc_call('addTorrent', [torrent]) == torrent
			gid
		end

		def self.addTorrentFile(filename)
			torrent = Base64.encode64(File.open(filename, "rb").read)
			gid = self.addTorrent(torrent)
			gid
		end

		def self.getActive()
			status = self.rpc_call('tellActive', [])
			status	
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
				if @token != '' then
					response = get("#{self.rpc_path}", {'token' => @token, 'method' => method, 'id' => id, 'params' => params_encoded})
				else
					response = get("#{self.rpc_path}", {'method' => method, 'id' => id, 'params' => params_encoded})
				end
				answer = JSON.parse(response['body'])

				if response['code'] == 200
					answer['result']
				else
					raise "AriaDownloader error #{answer['error']['code'].to_i}: #{answer['error']['message']}"
				end
			end

	end

end

