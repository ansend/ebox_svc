#! /usr/bin/ruby -w 
# -*- coding: UTF-8 -*-

require 'socket'      # Sockets 是标准库
$LOAD_PATH << '.'

hostname = 'localhost'
port = 21006

s = TCPSocket.open(hostname, port)

s.puts "hello world"
#s.close               # 关闭 socket
sleep (10)
while line = s.gets   # 从 socket 中读取每行数据
  puts line.chop      # 打印到终端
end
#s.close               # 关闭 socket



=begin
#req = EtcRequest.new("read_A1.xml", 900)
#req = BuffReadEtcRequest.new("write_B13.xml", 900)
req = BuffReadEtcRequest.new("common_B21.xml", 900)
#req = BuffReadEtcRequest.new("write_B13.xml", 900)
#req = EtcRequest.new("read_B1.xml", 900)
#req = EtcRequest.new("CMakeLists.txt", 900)
#req = FragSendEtcRequest.new("read_A1.xml", 900)
req.run_case()

=end 
