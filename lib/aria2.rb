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
		end

		def self.forceRemove(gid)
			self.rpc_call('forceRemove',[gid]) == gid
		end

		def self.pause(gid)
			self.rpc_call('pause', [gid]) == gid
		end

		def self.pauseAll()
			self.rpc_call('pauseAll', [])
		end

		def self.forcePause(gid)
			self.rpc_call('forcePause', [gid]) == gid
		end

		def self.forcePauseAll()
			self.rpc_call('forcePauseAll', [])
		end

		def self.unpause(gid)
			self.rpc_call('unpause', [gid]) == gid
		end

		def self.unpauseAll()
			self.rpc_call('unpauseAll', [])
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
			self.rpc_call('getUris', [gid])
		end

		def self.getFiles(gid)
			self.rpc_call('getFiles', [gid])
		end

		def self.getPeers(gid)
			self.rpc_call('getPeers', [gid])
		end

		def self.getServers(gid)
			self.rpc_call('getServers', [gid])
		end

		def self.getOption(gid)
			self.rpc_call('getOption', [gid])
		end

		def self.purgeDownloadResult()
			self.rpc_call('purgeDownloadResult')
		end

		def self.removeDownloadResult(gid)
			self.rpc_call('removeDownloadResult', [gid])
		end

		def self.getVersion()
			self.rpc_call('getVersion', [])
		end

		def self.getSessionInfo()
			self.rpc_call('getSessionInfo', [])
		end

		def self.shutdown()
			self.rpc_call('shutdown', [])
		end

		def self.forceShutdown()
			self.rpc_call('forceShutdown', [])
		end

		def self.saveSession()
			self.rpc_call('saveSession', [])
		end

		def self.addTorrent(torrent)
			self.rpc_call('addTorrent', [torrent]) == torrent
		end

		def self.addTorrentFile(filename)
			torrent = Base64.encode64(File.open(filename, "rb").read)
			self.addTorrent(torrent)
		end

		def self.getActive()
			self.rpc_call('tellActive', [])
		end

		def self.getStatus(gid, keys = ['status'])
			self.rpc_call('tellStatus', [gid, keys])
		end

		def self.query_status(gid)
			status = self.getStatus(gid, [
				'status',
				'totalLength',
				'completedLength',
				'downloadSpeed',
				'errorCode'
			])

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
			params_encoded = Base64.encode64(JSON.generate(params.unshift("token:#{@token}")))
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

