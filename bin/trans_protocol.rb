# -*- coding: UTF-8 -*-
#require "utest"
require 'pathname'
require_relative '../lib/utest'


def cal_crc16 (bytes)
   crc_polynom = 0x8408
   crc = 0xFFFF
   bytes.each do |b|
       #puts "curr uint8: "  + sprintf("%0.02X", b)
       crc = crc ^ b
       for i in 0..7
           if crc & 0x01 == 0x01
               crc = (crc >> 1) ^ crc_polynom
           else
               crc = crc >> 1
           end
       end

   end
   crc = (~crc) & 0xFFFF
   return crc
end
def hex2bin(hexstr)
    return nil if(hexstr.length % 2 != 0)
    res = []
    while hexstr.length > 0
        s = hexstr[0..1]
        hexstr = hexstr[2..hexstr.length - 1]
        res << s.to_i(16)
    end
    return res
end

def bin2hex(binary)
    res = ""
    binary.each{|b| res = res + sprintf("%.02X", b)}
    return res
end

def bin2str(binary, stopwith0 = false)
    s = ''
    binary.each{ |a| break if stopwith0 && (a == 0); s = s + a.chr;}
    return s
end

def bytes2str(binary)
    s = ''
    binary.each{ |a| s = s + a.chr;}
    return s
end


def hex2str(hexstr)
    bin2str(hex2bin(hexstr))
end
def hex2bin(hexstr)
    return nil if(hexstr.length % 2 != 0)
    res = []
    while hexstr.length > 0
        s = hexstr[0..1]
        hexstr = hexstr[2..hexstr.length - 1]
        res << s.to_i(16)
    end
    return res
end

def bin2hex(binary)
    res = ""
    binary.each{|b| res = res + sprintf("%.02X", b)}
    return res
end

def bin2str(binary, stopwith0 = false)
    s = ''
    binary.each{ |a| break if stopwith0 && (a == 0); s = s + a.chr;}
    return s
end

def bytes2str(binary)
    s = ''
    binary.each{ |a| s = s + a.chr;}
    return s
end


def hex2str(hexstr)
    bin2str(hex2bin(hexstr))
end


class FrameParkingFFFF < Frame

    def initialize(hexdata = nil)
        super()
        init_data(hexdata)
    end

    # overide init_data to add version and data
    def init_data(hexdata)
        #开始标志，有可能是一个FF，也有可能是2个FF，个地区不同，构造时从参数传进来，默认是两个
        @fields.stx              = FrameFFFF.ffcount == 1 ? NumField.new(1, "STX", 0xFF) : NumField.new(2, "STX", 0xFFFF)
        @fields.len              = NumField.new(2, "Len")
        @fields.data             = DatField.new(0, "Data")
        #bcc也有可能是FF
        @fields.crc16            = NumField.new(2, "CRC16")
        #结束标志，是一个FF
        #@fields.etx              = NumField.new(1, "ETX", 0xFF)

        unless hexdata.nil?
            @fields.len    <= (hexdata.length / 2)
            #puts "number of data is #{(hexdata.length / 2)}"
            @fields.data   <= hexdata
            @fields.crc16  <= 0x0000
        end
    end

    #因为 FFFF 协议里面，CRC有可能需要重新计算。
    def to_hs
        str = super()
        low  = 0 + FrameFFFF.ffcount * 2
        high = str.length() -1 -4  # remove  crc（4）
        # from version to data including version, rsctl, len , data,
        raw_data = str[low..high]
        #puts "raw data :" + raw_data
        crc = cal_crc16(hex2bin(raw_data))
        crc  = sprintf("%.04X", crc)
        ret = "FF" * FrameFFFF.ffcount + raw_data + crc
        puts "frame FFFF ITSSTD:" + ret
        return ret
    end


    #数据解释，如果能解释成功FF协议，就返回 true，否则返回 false
    def resolve(bytes)
        unless bytes.is_a?(Array)
            puts "#{self.class.name}.resolve, 参数不是一个数组类型"
            return false
        end
        self.clear
        tmpbytes = []
        idxl = 0
        while(bytes[idxl] == 0xFF)
            idxl += 1
        end

        if (bytes.size > 8) &&  !idxl.nil?
            tmpbytes = bytes[idxl..(bytes.size()-1)]
        end
        if tmpbytes.size == 0
            puts "#{self.class.name}.resolve, 解释数据时, 没有找到足够的FF的标志，原始数据：#{bin2hex(bytes)}"
            return false
        end
        #puts tmpbytes.inspect
        #检查CRC是否正确
        crc = cal_crc16(tmpbytes[0..(tmpbytes.size() -3)])
        crc_hex = sprintf("%0.04X", crc)
        data_hex = bin2hex(tmpbytes)

        if(crc_hex == data_hex[-4..-1])
            puts "ansen test" +  "FF" * FrameFFFF.ffcount + data_hex
            self <= "FF" * FrameFFFF.ffcount + data_hex
            return true
        else
            puts "#{self.class.name}.resolve, 解释数据时, CRC16校验没有通过,原始数据：#{bin2hex(bytes)}"
            return false
        end
    end
	
	def self.rsuetc_read_data()
	    chkcount = FrameFFFF.ffcount + 1
        recv_finished = lambda{|recvbytes|
            #这判断是否结束。
            #n stx, 2 len , 0 data, 2 crc_16，at least
            #根据协议，只有据长度大于等于 4 + FrameFFFF.ffcount 才有可能是完整的数据帧
            if recvbytes.size >= (4 + FrameFFFF.ffcount)
                data_len = peek_len(recvbytes)
                # data_len 必须小于0xFFFF, 如果收到数据大于datalen 加上帧头和帧尾crc长度，才有可能是完整数据帧
                return true if (data_len < 0xFFFF)&& (recvbytes.size >=  (6 + FrameFFFF.ffcount + data_len))
            end
            return false
        }

        #可能数据里面包含有多帧，所以要分开，保存到一个数组里面返回,数组里面每一个元素也是一个数组
        recdat = librsuetc_comm.recv_data(recv_finished)
        #puts "原始数， #{bin2hex(recdat)}"
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
                inx = inx +1
            end
            len  = peek_len(recdat)
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
    
    
    def self.peek_len(bytes)
        # peek the length of the its std protocol length of the data
        inx = 0
        while(bytes[inx] == 0xFF)
            inx = inx +1
        end
        packet_len = bytes[(inx), 2]
        len_hex = bin2hex(packet_len)
        len = len_hex.to_i(16)
        return len
    end
	 
    #class variable to judge the recv end of the frame.
    @@recv_finished = lambda{|recvbytes|
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
        
    def self.recv_finished()
    
        return @@recv_finished
    end 
        
    def self.split_frame_data(recdat)
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
    
    end
end
