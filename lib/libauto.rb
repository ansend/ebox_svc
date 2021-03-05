#encoding: gb2312

# libauto.rb
# 作者：王政
# 描述：自动化测试接口
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

#require File.dirname(__FILE__)+"/ucore"
require File.dirname(__FILE__)+"/ucomm"

AUTO_CMD_READ  = 1
AUTO_CMD_WRITE = 2

AUTO_CRC_0000 = 1
AUTO_CRC_FFFF = 0

#金溢DSRC自动化测试接口类函数
#这个类的函数没什么好说的，所有的函数，都是按照接口协议文档来做的
#如果不清楚，查看接口协议文档即可。
#要用这个接口时，设备要先进入自动化测试模式。

def libauto_comm
    ucomm
end


def dsrcauto_read_write_55aa(rw, type, hexdata, needretrun = true)
    frm = Frame55AA.new(rw, sprintf("%.02X%s", type, hexdata))
    if needretrun
        ret = libauto_comm.send_recv(frm)
        if frm.resolve(ret)
            str = frm.data.to_hs
            if str[0..1] == sprintf("%.02X", type)  #OBU自动化的协议，跟RSU 55AA协议有一点不一样，DATA域的第一个字节是 type，而RSU 的 DATA域就是全数据
                return str[2..str.length-1]
            else
                puts "返回数据解释type字节与发送的字节不匹配"
                return ""
            end
        else
            puts "返回数据解释错误，或者没有返回数据"
            return ""
        end
    else
        ret = libauto_comm.send_data(frm)
        return ""
    end
end


class DsrcAuto
protected
    ###############################两个基本函数###########################
    #读取命令
	def read(type, hexdata='00')
        dsrcauto_read_write_55aa(AUTO_CMD_READ, type, hexdata)
    end

	#写入命令
	def write(type, hexdata, needretrun = true)
        dsrcauto_read_write_55aa(AUTO_CMD_WRITE, type, hexdata, needretrun)
	end
end

class ObuAuto < DsrcAuto

    #执行一条COS指令, 返回{:resp=>'xxxx', :sw12=>'xxxx'}格式
    #channel: 1 是 IC卡， 2是 ESAM
    #hexcmd，16进制字符串，COS指令
    def cos_command(channel, hexcmd)
        s = channel.to_s(16)
        s = '0' + s if s.length == 1
        hexdata = s + hexcmd
        res = write(0x08, hexdata)
        if res.length > 4
            return split_sw12(res)
        else
            return {:resp=>'', :sw12=>res}
        end
        return {}
    end

    #取设备版本号字符串
    def get_version
        hexout = read(0x00)
        bin = hex2bin(hexout)
        return bin2str(bin)
    end

    #复位IC卡,返回卡片复位信息
    def icc_reset
        res = cos_command(0x81, '0000')
        return res[:resp]+res[:sw12]
    end

    #复位ESAM，返回芯片的复位信息，按国标
    def esam_reset
        res = cos_command(0x82, '0000')
        return res[:resp]+res[:sw12]
    end

    #执行IC卡命令，一条命令，16进制命令字符串
    def icc_command(hexcmd)
        cos_command(0x01, hexcmd)
    end

    #执行ESAM命令，一条命令，16进制命令字符串
    def esam_command(hexcmd)
        cos_command(0x02, hexcmd)
    end

    #取id, sn号
    #返回{:id=>"", :sn=>""}
    def get_macid_sn()
        ret = read(0x03)
        if(ret.length == 12*2)
            {:id=>ret[0..7], :sn=>ret[8..ret.length-1]}
        else
            return {}
        end
    end

    #设置id, sn
    #返回{:id=>"", :sn=>""}
    def set_macid_sn(hash_mac_sn)
        hexid = hash_mac_sn[:id]
        hexsn = hash_mac_sn[:sn]
        while hexid.length < 8
            hexid = '0' + hexid
        end
        while hexsn.length < 8
            hexsn = '0' + hexsn
        end
        ret = write(0x03, hexid + hexsn)
        if(ret.length == 12*2)
            {:id=>ret[0..7], :sn=>ret[8..ret.length-1]}
        else
            return []
        end
    end

    #set mmi
    def set_mmi(mmiparam)
        write(0x0A, sprintf("%.02X", mmiparam))
    end

    #设置计算CRC的方式，0 = FFFF， 1=0000
    def set_crc(crctype)
        stype = sprintf("%.02X", crctype)
        ret = write(0x31, stype)
        return stype == ret
    end

    #打开通道模式
    def open_channel
        scmd = sprintf("%.02X", 1)
        ret = write(0x40, scmd)
        return "01" == ret
    end

    #接收通道数据。
    def recv_channel_data
        read(0x41, "01")
    end

    #发送通道数据，没有返回的。
    def send_channel_data(hexdata)
        write(0x42, hexdata, false)
    end


    def self.inst
        @obu_auto ||= ObuAuto.new
    end
end

#下面这些常量是 set_mmi 的控制参数
MMI_BEEP      = 0x01
MMI_LCD       = 0x02
MMI_RED       = 0x04
MMI_GREEN     = 0x08

PWR_ON        = 0x01
PWR_OFF       = 0x00

def obu_auto
    ObuAuto.inst
end

alias outo obu_auto
