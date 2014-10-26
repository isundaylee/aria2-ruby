# Simple test application

require 'aria2'

dl = Aria2::Downloader.new



gid = dl.download('http://nl.mirror.eurid.eu/centos/7.0.1406/isos/x86_64/CentOS-7.0-1406-x86_64-DVD.iso','/root/tmp.torrent')
begin
        status dl.pause(gid)
        puts status
 rescue
        puts "Error on pause"
end

begin
        puts dl.pauseAll()
end

begin
        puts dl.forcePause(gid)
  rescue
        puts "Error on ForcePause"
end

begin
        puts dl.forcePauseAll
        rescue
end

begin
        puts dl.query_status(gid)
        rescue
end

begin
        puts dl.getUris(gid)
        rescue
end
begin
        puts dl.getFiles(gid)
        rescue
end
begin
        puts dl.getServers(gid)
        rescue
end