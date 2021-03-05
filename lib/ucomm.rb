# -*- coding: UTF-8 -*-
# ucomm.rb
# 作者：王政
# 描述：通讯接口
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

require "fiddle"
require "fiddle/import"
require "win32/registry"

# module UCommApi
#     extend Fiddle::Importer
#     dlload 'utest.dll'
#
#     #设置连接参数，串口：COMMX, 115200, 网口：192.168.x.x, 55890
#     # int  __stdcall open(char *contype, char *constr, int port);
#     extern 'int open(char*, char *, int )'
#
#     # int __stdcall close(int fd);
#     extern 'int close(int )'
#
#     #取得当前缓冲区内的长度
#     # int  __stdcall recv_len(int fd, int timeout);
#     extern 'int recv_len(int , int )'
#
#     # int __stdcall recv_data(int fd, char *buf, int len);
#     extern 'int recv_data(int , char *, int )'
#
#     # int __stdcall send_data(int fd, char *buf, int len);
#     extern 'int send_data(int , char *, int )'
# end

#由于JSON 和C++Builder的vcl有冲突，所以要改一下写法，并且，以后用到selenium的地方，就不能用utest.dll里面的功能

def set_com_latency_timer(comx, value)
    begin
        reg = Win32::Registry::HKEY_LOCAL_MACHINE.open 'system\Controlset001\Enum\FTDIBUS'
    rescue
    end
    return if reg.nil?
    comids = []
    reg.each_key { |key|
        comids << key.to_s
    }
    comids.each{|skey|
        begin
            keyname = "SYSTEM\\ControlSet001\\Enum\\FTDIBUS\\#{skey}\\0000\\Device Parameters"
            reg = Win32::Registry::HKEY_LOCAL_MACHINE.open keyname, Win32::Registry::KEY_READ + Win32::Registry::KEY_WRITE
        rescue
        end
        next if reg.nil?
        portname = reg['PortName']
        if portname == comx.upcase
            begin
                ltime = reg['LatencyTimer', Win32::Registry::REG_DWORD]
                if ltime != value
                    reg['LatencyTimer'] = value
                    sleep 0.01
                end
            rescue
            end
            break
        end
    }
end

class UComm
    attr_accessor :conntype
    attr_accessor :connstr
    attr_accessor :connport
    attr_accessor :connfd

    def ptxml? #在网络连接时，M600T等设备，用的是转成XML的字符串。
        @ptxml
    end

    # 创建时设置连接参数，
    # 串口  COM:1:115200
    # HID  HID:1:04835750
    # TCP  TCP:ipaddr:port
    # UDP  UDP:ipaddr:port
    def initialize(strtype, strconn, strport)
        libutils = Fiddle.dlopen('utest.dll')
        @open       = Fiddle::Function.new(libutils['open'],      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],  Fiddle::TYPE_INT)
        @close      = Fiddle::Function.new(libutils['close'],     [Fiddle::TYPE_INT],                                          Fiddle::TYPE_INT)
        @recv_len   = Fiddle::Function.new(libutils['recv_len'],  [Fiddle::TYPE_INT, Fiddle::TYPE_INT],                        Fiddle::TYPE_INT)
        @recv_data  = Fiddle::Function.new(libutils['recv_data'], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],    Fiddle::TYPE_INT)
        @send_data  = Fiddle::Function.new(libutils['send_data'], [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],    Fiddle::TYPE_INT)


        @ptxml = false
        @connfd = -1
        @conntype = strtype
        if strtype == "COM"
            set_com_latency_timer(sprintf("COM%s", strconn), 2)
            port = 0
            port = strport.to_i if strport
            port = 115200 if strport.nil?
            @connstr = strconn
            @connport = port
            self.open
        elsif strtype == "HID"
            strport = "04835750" if strport.nil? #m600t's default
            port = strport.to_i(16)
            @connstr = strconn
            @connport = port
            self.open
        elsif strtype == "TCP"
            aport = -1
            if strport.is_a?(String) && (strport.upcase == "M600T" || strport.upcase == "M600H")
                @ptxml = true
                aport = 55890
            elsif strport.is_a?(String) && (strport.upcase == "G2" || strport.upcase == "G60E" || strport.upcase == "P30" || strport.upcase == "P60")
                aport = 21003
            elsif strport.nil? || (strport.is_a?(Fixnum) && strport == 0)  #默认55890
                aport = 55890
            else
                aport = strport.to_i
            end

            @connstr = strconn
            @connport = aport
            self.open
            sleep(0.025)  #刚连接上先不要收，等一下，设备可能自己返回一些数据，清掉，如果不行的话，用户自己清
            clear
        elsif strtype == "UDP"
            aport = strport.to_i
            @connstr = strconn
            @connport = aport
            self.open
            sleep(0.025)  #刚连接上先不要收，等一下，设备可能自己返回一些数据，清掉，如果不行的话，用户自己清
            clear
        end
        ObjectSpace.define_finalizer self, Proc.new{
            @closec.call(@connfd) if @connfd != -1
        }
    end

    def close
        @close.call(@connfd) if @connfd != -1
        @connfd = -1
        puts "关闭连接"
    end

    def open
        return if @connfd != -1
        @connfd = @open.call(@conntype, @connstr, @connport)
        if(@connfd != -1)
            puts "连接打开成功：#{@conntype} : #{@connstr} : #{@connport}"
        else
            puts "连接打开失败：#{@conntype} : #{@connstr} : #{@connport}"
        end
    end

    #发送和接收, frame.recv_finished函数用于判断是否接收完毕，需要根据具体协议制定
    def send_recv(frame_or_hexdata_or_bytes, timeout = 2000)
        ret = []
        if @connfd == -1
            puts "通讯接口没有打开"
            sleep(2)
        else
            cmdbytes = frame_or_hexdata_or_bytes
            cmdbytes = hex2bin(frame_or_hexdata_or_bytes.to_hs) if frame_or_hexdata_or_bytes.is_a?(Frame)
            cmdbytes = hex2bin(frame_or_hexdata_or_bytes) if frame_or_hexdata_or_bytes.is_a?(String)
            len = @send_data.call(@connfd, bytes2str(cmdbytes), cmdbytes.size)
            if len == -1
                puts "数据传输的时候连接已经断开，交易中断"
                close
            end
            times = (timeout / 15) + 10
            i = 0
            while i < times
                len = @recv_len.call(@connfd, 15)
                if len > 0
                    i = 0
                    buf = ' ' * len
                    readed = @recv_data.call(@connfd, buf, len)
                    if readed != 1
                        puts "没有读到数据，可能连接已经断开"
                        close
                        break
                    end
                    ret = ret + buf.bytes
                    if frame_or_hexdata_or_bytes.is_a?(Frame)
                        break if frame_or_hexdata_or_bytes.respond_to?(:recv_finished) && frame_or_hexdata_or_bytes.recv_finished(ret)
                    else
                        if block_given?
                            break if yield ret
                        end
                    end
                elsif len == -1
                    puts "数据传输的时候连接已经断开，交易中断"
                    close
                    ret = []
                    break
                else
                    i = i + 1
                    #已经读到了，后面又连续n次都没读到，那也不用等了
                    if ret.size > 0 && i >= 2
                        break
                    end
                end
            end
        end
        return ret
    end

    #发送，不接收，立刻返回
    def send_data(frame_or_hexdata_or_bytes)
        if @connfd == -1
            puts "通讯接口没有打开"
            sleep(2)
        else
            cmdbytes = frame_or_hexdata_or_bytes
            cmdbytes = hex2bin(frame_or_hexdata_or_bytes.to_hs) if frame_or_hexdata_or_bytes.is_a?(Frame)
            cmdbytes = hex2bin(frame_or_hexdata_or_bytes) if frame_or_hexdata_or_bytes.is_a?(String)
            len = @send_data.call(@connfd, bytes2str(cmdbytes), cmdbytes.size)
            if len == -1
                puts "数据传输的时候连接已经断开，交易中断"
                close
            end
        end
        return []
    end

    #只接收数据，没有发送
    # recv_finished 是一个 lambda 匿名函数, 匿名函数，有多种，一定要lambda, 不能用Proc
    # 比如
    # recv_finished = lambda{|bytes|
    #     if bytes.size > 100
    #         return true
    #     else
    #         return false
    #     end
    # }
    #
    #
    def recv_data( recv_finished = nil)
        ret = []
        if @connfd == -1
            puts "通讯接口没有打开"
            sleep(2)
        else
            timeout = 10000
            times = (timeout / 15) + 10
            i = 0
            while i < times
                len = @recv_len.call(@connfd, 15)
                if len > 0
                    i = 0
                    buf = ' ' * len
                    readed = @recv_data.call(@connfd, buf, len)
                    if readed != 1
                        puts "没有读到数据，可能连接已经断开"
                        close
                        break
                    end
                    ret = ret + buf.bytes
                    if recv_finished
                        break if recv_finished.call ret
                    elsif block_given?
                        break if yield ret
                    end

                elsif len == -1
                    puts "数据传输的时候连接已经断开，交易中断"
                    close
                    ret = []
                    break
                else
                    i = i + 1
                    #已经读到了，后面又连续n次都没读到，那也不用等了
                    if ret.size > 0 && i >= 2
                        break
                    end
                end
            end
        end
        return ret
    end

    def clear
        if @connfd == -1
            puts "通讯接口没有打开"
        else
            begin
                len = @recv_len.call(@connfd, 15)
                if len > 0
                    buf = ' ' * len
                    @recv_data.call(@connfd, buf, len)
                end
            end while len > 0
        end
    end

    #这里必须这样写，参看 dev_set_ip 的两种写法，在以前的函数里面效果会不同
    #如果在下面那个 ucomm函数里面做，就会有不同效果
    def self.inst
        if @ucomm.nil?
            ARGV.each do |arg|
                if arg[0..4] == 'conn='
                    param = arg[5..(arg.length-1)].split(":")
                    type = param[0]
                    conn = param[1]
                    port = param[2]
                    @ucomm = UComm.new type, conn, port
                    break
                end
            end
        end
        puts "ucomm 创建失败！没有获得[conn=]参数" if @ucomm.nil?
        return @ucomm
    end

end

def ucomm
    UComm.inst
end
