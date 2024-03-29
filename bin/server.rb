# -*- coding: UTF-8 -*-
#require "utest"

require 'socket'               # 获取socket标准库

require_relative 'trans_protocol'
require_relative 'ebox_frame'
require_relative 'trans_protocol'
require_relative "../lib/utest"
require_relative 'sw_psam'

$g_client = nil

# recdat  bytes from socket io
def rsuetc_read_data(recdat)
	    chkcount = FrameFFFF.ffcount + 1
        puts "原始数， #{bin2hex(recdat)}"
        res = []
        fc = 0
        start = 0
        inx = 0
        while((recdat.size() > 0) && (recdat[0] != 0xFF))
            recdat.delete_at(0)
            puts "收到数据帧的起始数据不是FFFF， 删除无效数据"
        end

        # parse the packet
        while(recdat.size() > 0)
            inx = 0
            while(recdat[inx] == 0xFF)
                inx = inx + 1
            end
            len  = FrameParkingFFFF.peek_len(recdat)
            # n stx, 2 len , 0 data, 2 crc_16，at least
            total_len = inx +  2 + len + 2  # stx +  len + data + crc16
            if total_len <= recdat.size()
                packet = recdat.shift(total_len)
                res << packet
            else
                break
            end
        end

        puts "收到帧数为#{res.size}" if res.size > 1
        return res
end # end of rsuetc_read_data


#FFFF协议 收发函数, 可以重载
def rsuetc_write_data_ebox(socket, hexdata)
    return if hexdata.length == 0
    #get ff frame type myabe 1, normal FFFF Protocol or Its standard FFFF protocol
    ff_type = get_ff_potocol_type()
    reqfrm = ff_type.new(hexdata)
    #puts "final hex data:" + reqfrm.to_hs
    #librsuetc_comm.send_data(reqfrm.to_hs)
    str_data = bytes2str(hex2bin(reqfrm.to_hs))
    socket.send(str_data, 0)
end


def send_frame(frm)
    rsuetc_write_data_ebox($g_client , frm.to_hs)
end 



def handle_frame(recs)
    recs.each{|res|
        if res.size > 5
            ff_type = FrameParkingFFFF
            frm = ff_type.new
            #puts "origin data: #{bin2hex(res)}"
            if frm.resolve(res)
                handle_data(frm.data.to_hs)
            end
        end
    }
end 


def handle_data(hex_str)
    #puts " in handle data #{hex_str}"
    cmd_type = hex_str[0..1]
    if(cmd_type == "E0")
        frme0 = EboxFrameE0.new
        frme0 <= hex_str
        puts frme0.to_ps
        
        frmf0 = EboxFrameF0.new
        puts frmf0.to_hs
        send_frame(frmf0)
    end 
    
    
    if(cmd_type == "E1")
        frme1 = EboxFrameE1.new
        frme1 <= hex_str
        puts frme1.to_ps
        
        frmf1= EboxFrameF1.new
        puts frmf1.to_hs
        send_frame(frmf1)
    end 
    
    if(cmd_type == "E2")
        frme2 = EboxFrameE2.new
        frme2 <= hex_str
        puts frme2.to_ps
        
        frmf2 =EboxFrameF2.new
        puts frmf2.to_hs
        send_frame(frmf2)
    end 
    
    if(cmd_type == "E6")
        frme6 = EboxFrameE6.new
        frme6 <= hex_str
        puts frme6.to_ps
        
        frmf6 =EboxFrameF6.new
        puts frmf6.to_hs
        send_frame(frmf6)
    end 
    

    
    cmd_type = cmd_type.downcase
    
    func_name = "on_frame_#{cmd_type}"
    if respond_to?(func_name)
        #调用具体的处理函数
        #send(func_name)
        #调用完了看有没有要发的数据，如果有就发出去
    end 

end 



def start_svc()

set_ff_potocol_type(FrameParkingFFFF)
recv_finished = nil

recv_finished = lambda{|recvbytes|
            #这判断是否结束。
            #n stx, 2 len , 0 data, 2 crc_16，at least
            #根据协议，只有据长度大于等于 4 + FrameFFFF.ffcount 才有可能是完整的数据帧
            if recvbytes.size >= (4 + FrameFFFF.ffcount)
                data_len = FrameParkingFFFF.peek_len(recvbytes)
                # data_len 必须小于0xFFFF, 如果收到数据大于datalen 加上帧头和帧尾crc长度，才有可能是完整数据帧
                return true if (data_len < 0xFFFF)&& (recvbytes.size >=  (4 + FrameFFFF.ffcount + data_len))
            end
            return false
        }

    
server = TCPServer.open('0.0.0.0', 21004)  # Socket 监听端口为 2000
loop {                         # 永久运行服务
  client = server.accept       # 等待客户端连接
  $g_client = client
  tcp_buff = []
  puts "recv client"
  p client
  sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
  puts "connection coming from #{remote_ip} and port #{remote_port}"
  line = 1
  i = 0
  loop { # firstly read out all the request from client.
      #line = client.gets    # here simulate read the client request.
      line = client.recv(1024) # here simulate read the client request.
      #puts line.class
      #p line
          
      if(!line.empty?)
          #p line
          #puts line.class
          #puts "line info:"
         # p line.bytes
         # puts "tcp buff:"
          #p tcp_buff
          tcp_buff = tcp_buff + line.bytes
          if (recv_finished)
             #puts "call recv finished lamda"
              #puts "tcp buff:"
              #p tcp_buff
             if recv_finished.call tcp_buff 
                #puts " recv finished lamda return true"
                res = rsuetc_read_data(tcp_buff)
                handle_frame(res)
                tcp_buff = []
             end              
          end
          
          
          hex = bin2hex(line.bytes.to_a)
          
          #puts hex
          #p hex
          
          
          str2 = bytes2str(hex2bin(hex))
          
          #puts "trans to string again"
          
          #p str2
          
         # puts "#{line.length}" + "size"
         # puts "#{i}" + "times"
          STDOUT.flush
      else
          puts "recv empty string since remote close the socket"
          puts line.class
          p line
          client.close  # close it 
          break         # wait another socket

      end       
      i = i + 1
      
    
  }
  

  client.puts(Time.now.ctime)  # 发送时间到客户端
  client.puts "Closing the connection. Bye!"

  client.close                 # 关闭客户端连接
}

end 


class AbcServer

    def initialize(port, ip="0.0.0.0")         #chkval 是用户接收输入后，检查是否为固定值
        @port          = port
        @ip            = ip
        @frame_type    = nil
        @frame_handler = nil
        @client        = nil
        @recv_buff     = []
        @recv_finished = nil
    end
    
    def set_frametype(frameclass)
        @frame_type = frameclass
    end 
    
    def register_handler(framehandler)
        @frame_handler = framehandler
    end 
    
    
    def start_svc()
    
        server = TCPServer.open(@ip, @port)  # Socket 监听端口为 2000
        loop{
             Thread.start(server.accept) do |client|
                 client.puts(Time.now.ctime) # 发送时间到客户端
                 frame_type = FrameParkingFFFF
                 frame_handler = EboxFrameHandler.new(FrameParkingFFFF)
                 sock_domain, remote_port, remote_hostname, remote_ip = client.peeraddr
                 puts "connection coming from #{remote_ip} and port #{remote_port}"
                 Thread.current[:rport] = remote_port
                 puts client.class
                 puts client.inspect
                 frame_handler.set_sock(client)  #set socket to frame handler.
                 recv_buff = []
                  
                 recv_dat = ''
                 i = 0
                 loop{
                     #line = client.gets    # here simulate read the client request.
                     begin 
                         recv_dat = client.recv(1024) # here simulate read the client request.
                         puts "recv data is #{recv_dat}"
                     rescue Exception => e
     
                         puts "ERROR: connection to server failed"
                         puts e.message
                         puts e.backtrace.inspect
                         client.close 
                         break
                     end
                       
                     if(!recv_dat.empty?)
                         #p tcp_buff
                         recv_buff = recv_buff + recv_dat.bytes
                         if (frame_type.recv_finished)
                             #puts "call recv finished lamda"
                             #puts "tcp buff:"
                             if frame_type.recv_finished.call recv_buff 
                                 #puts " recv finished lamda return true"
                                 res = frame_type.split_frame_data(recv_buff)
                                 puts "AAAAAAAAAAAAAAAAAAAAA recv data from remote port  #{Thread.current[:rport]}"
                                 frame_handler.handle_frame_list(res)
                                 recv_buff = []
                             end              
                         end
                       
                         hex = bin2hex(recv_dat.bytes.to_a)
                         #puts hex
                         str2 = bytes2str(hex2bin(hex))
                       
                         #puts "trans to string again"
                         # puts "#{line.length}" + "size"
                         # puts "#{i}" + "times"
                         STDOUT.flush
                     else
                         puts "recv empty string since remote close the socket ansen ansen "
                         puts "close the socket"
                         #puts line.class
                         #p line
                         begin 
                            client.close  # close it 
                            #client.shutdown(:RDWR) # close it 
                         rescue Exception => e
                            puts "exception found"
                            puts e.message
                            puts e.backtrace.inspect
                            puts "exception end"
                         ensure
                            puts "do some clean work here."
                         end
                         puts "close the socket after close and shutdown"
                         break         # wait another socket
                     end       
                     i = i + 1
                 }  #end of loop client recv.

                 #client.puts "Closing the connection. Bye!"
                 puts "close the socket again final"
                 client.close                # 关闭客户端连接
            end  #end of thread.
        }#end of loop server accept.

=begin

        loop {                                     # 永久运行服务
            @client = server.accept                # 等待客户端连接

            timeval = timeval = [0, 1].pack("l_2")
            @client.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, timeval)

            puts @client.getsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO).inspect
            @frame_handler.set_sock(@client)
            @recv_buff = []
            sock_domain, remote_port, remote_hostname, remote_ip = @client.peeraddr
            puts "connection coming from #{remote_ip} and port #{remote_port}"
            puts @client.class
            puts @client.inspect
            recv_dat = ''
            i = 0
            loop { # firstly read out all the request from client.
                #line = client.gets    # here simulate read the client request.
                begin 
                    recv_dat = @client.recv(1024) # here simulate read the client request.
                rescue Exception => e

                    puts "ERROR: connection to server failed"
                    puts e.message
                    puts e.backtrace.inspect
                    @client.close 
                    break
                end
                  
                if(!recv_dat.empty?)
                    #p line
                    #puts line.class
                    #puts "line info:"
                    # p line.bytes
                    # puts "tcp buff:"
                    #p tcp_buff
                    @recv_buff = @recv_buff + recv_dat.bytes
                    if (@frame_type.recv_finished)
                        #puts "call recv finished lamda"
                        #puts "tcp buff:"
                        #p tcp_buff
                        if @frame_type.recv_finished.call @recv_buff 
                            #puts " recv finished lamda return true"
                            res = @frame_type.split_frame_data(@recv_buff)
                            @frame_handler.handle_frame_list(res)
                            @recv_buff = []
                        end              
                    end
                  
                  
                    hex = bin2hex(recv_dat.bytes.to_a)
                  
                    #puts hex
                    #p hex
                  
                  
                    str2 = bytes2str(hex2bin(hex))
                  
                    #puts "trans to string again"
                  
                    #p str2
                  
                    # puts "#{line.length}" + "size"
                    # puts "#{i}" + "times"
                    STDOUT.flush
                else
                    puts "recv empty string since remote close the socket"
                    puts line.class
                    p line
                    client.close  # close it 
                    break         # wait another socket

                end       
                i = i + 1
              
            
            }
    
        }
=end 
    end 
    
end 


class EboxFrameHandler

    def initialize(frame_type)         #chkval 是用户接收输入后，检查是否为固定值
        @sock          =  nil    #TcpSocket return from TCPServer, used to send data out.
        @frame_type    =  frame_type
    end

    def on_msg_e0(hex_str)
        puts "on_msg_e0 called"
        frme0 = EboxFrameE0.new
        frme0 <= hex_str
        puts frme0.to_ps
        
        frmf0 = EboxFrameF0.new
        puts frmf0.to_hs
        send_frame(frmf0)
    end 
    
    
    def set_sock(sock)
    
        @sock = sock
    end 
    
    def on_msg_e1(hex_str)
        frme1 = EboxFrameE1.new
        frme1 <= hex_str
        puts frme1.to_ps
        
        frmf1= EboxFrameF1.new
        puts frmf1.to_hs
        send_frame(frmf1)
    end
    
    def on_msg_e2(hex_str)
        frme2 = EboxFrameE2.new
        frme2 <= hex_str
        puts frme2.to_ps
        
        frmf2 =EboxFrameF2.new
        puts frmf2.to_hs
        send_frame(frmf2)
    end 

    def on_msg_e6(hex_str)
        puts "called on_msg_e6"
        frme6 = EboxFrameE6.new
        frme6 <= hex_str
        puts frme6.to_ps
        
        frm_esam_sys = Frame_ESAM_SysInfo.new
        frm_esam_sys <= frme6.sysinfo.to_hs
        puts frm_esam_sys.to_ps

        con_provider = frm_esam_sys.vendor_id.to_hs[0..7] * 2
        contract_sn  = frm_esam_sys.contractsn.to_hs

        @sw_psam = SwPsam.new(con_provider, contract_sn)
        
        veh_plaint =  @sw_psam.decrypt_veh_info(frme6.veh_info.to_hs)
        veh_len = veh_plaint[0..1].to_i(16) - 8
        veh_info = veh_plaint[18..(18 + veh_len*2 - 1)]
        
        frmf6 = EboxFrameF6.new
        frmf6.set_field_values(:serial => "FF" * 32)
        frmf6.set_field_values(:psam_id => @sw_psam.get_term_id)
        frmf6.set_field_values(:veh_info => veh_info)
        puts frmf6.to_ps
        puts frmf6.to_hs
        send_frame(frmf6)
    end 

    def on_msg_e7(hex_str)
        puts "called on_msg_e7"
        frme7 = EboxFrameE7.new
        frme7 <= hex_str
        puts frme7.to_ps
        
        puts frme7.to_hs
        puts frme7.cmd.to_hs
        #hexmoney = sprintf("%.08X", @conf.consume_money)
        
        #rand_num       = frme7.randnum.to_hs
        icc_serial     = frme7.icc_serial.to_hs
        money          = frme7.money.to_hs
        tran_time      = frme7.tran_time.to_hs
        icc_sn         = frme7.icc_info.to_hs[16..31]
        issue_id       = frme7.icc_info.to_hs[0..15]

        mac1 = @sw_psam.mix_purchase_mac1(frme7.randnum.to_hs, "09", frme7.icc_serial.to_hs, frme7.money.to_hs, 
                                          frme7.tran_time.to_hs, "01", "00",  frme7.icc_info.to_hs[16..31], 
                                          frme7.icc_info.to_hs[0..15])
        frmf7 = EboxFrameF7.new
        frmf7.set_field_values(:mac1 => mac1)
        frmf7.set_field_values(:psam_serial => @sw_psam.get_trade_sn)
        puts frmf7.to_ps
        puts frmf7.to_hs
        send_frame(frmf7)
    end 


   
    def handle_frame_list(frame_list)

      begin
        frame_list.each{|frame|
            if frame.size > 5
               
                frm = @frame_type.new
                #puts "origin data: #{bin2hex(res)}"
                if frm.resolve(frame)
                    handle_frame(frm.data.to_hs)
                end
            end
        }
      rescue
         expmsg = $!.to_s
         str = '<ept>' + $!.to_s + "\n"
         $@.each{ |line| str = str + 'from ' + line.encode("gb2312") + "\n" }
         str = str + '</ept>'
         puts str
      end
    
    end 
    
    def handle_frame(hex_data)
        cmd_type = hex_data[0..1]
        cmd_type = cmd_type.downcase
        func_name = "on_msg_#{cmd_type}"
        puts "func name is #{func_name}"
        if respond_to?(func_name)
            #调用具体的处理函数
            puts "call #{func_name}"
            puts self.inspect
            #send(func_name, hex_data)
            self.send(func_name, hex_data)

        end 
    
    end 
    
    
    def send_frame(frm)
        
        return if frm.to_hs.length == 0
        #get ff frame type myabe 1, normal FFFF Protocol or Its standard FFFF protocol
        reqfrm = @frame_type.new(frm.to_hs)
        #puts "final hex data:" + reqfrm.to_hs
        #librsuetc_comm.send_data(reqfrm.to_hs)
        str_data = bytes2str(hex2bin(reqfrm.to_hs))
        if(@sock)
            num_sent = @sock.send(str_data, 0)
            puts "send number is #{num_sent}"
        else
            puts "No socket avalable no data will send out !!!!!"
        end 
    end 
end 



=begin
class EboxServer < TestSuit

  def suit_desc
    'EBOX 模拟后台程序'
  end

  def suit_options
    #设置选项
  end

  def test_ebox_service(desc="模拟EBOX后台服务程序")

    # function call mode
    #start_svc()
    
    # class mode
    
    server = AbcServer.new(21004, '0.0.0.0')
    server.set_frametype(FrameParkingFFFF)
    ebox_frm_handler = EboxFrameHandler.new(FrameParkingFFFF)
    server.register_handler(ebox_frm_handler)
    server.start_svc()


  end
  
end

=end 
    server = AbcServer.new(21004, '0.0.0.0')
    server.set_frametype(FrameParkingFFFF)
    ebox_frm_handler = EboxFrameHandler.new(FrameParkingFFFF)
    server.register_handler(ebox_frm_handler)
    server.start_svc()

























