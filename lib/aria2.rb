require "aria2/version"

module Aria2

	class Downloader

		def self.new(host = 'localhost', port = 6800)
			@host = host
			@port = port
		end

	end

end

