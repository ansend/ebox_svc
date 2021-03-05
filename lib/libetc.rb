# -*- coding: UTF-8 -*-
# libetc.rb
# 作者：王政
# 描述：RSU设备的集成模式接口，用的是FF协议。
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

#require File.dirname(__FILE__)+"/ucore"
require "statemachine"
require File.dirname(__FILE__)+"/frame"
#继续交易
class BZFrameEmpty < Frame
    def initialize
        super()
    end
end

class BZFrameC0 < Frame
    def initialize(lanmode: 3, waitetime: 15, txpower: 10)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",   0xC0)

        @fields.seconds    = NumField.new(4, "Unix Time seconds",  utils.get_unix_time_hex)
        @fields.datetime   = NumField.new(7, "Formated Datetime",  utils.formatdatetime(utils.datetime_now, "yyyymmddhhnnss"))
        @fields.lanemode   = NumField.new(1, "lane mode",     lanmode)
        @fields.waittime   = NumField.new(1, "wait time",     waitetime)
        @fields.txpower    = NumField.new(1, "tx poawer",     txpower)
        @fields.channel    = NumField.new(1, "Pll Channel",   0)
    end
end

#继续交易
class BZFrameC1 < Frame
    def initialize(obuid = 0)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",   0xC1)
        @fields.fill       = NumField.new(1, "Fill",    0x01)
        @fields.obuid      = NumField.new(4, "Obu ID",  obuid)
    end
end

#停止交易
class BZFrameC2 < Frame
    def initialize(obuid = 0)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",   0xC2)
        @fields.obuid      = NumField.new(4, "Obu ID",  obuid)
        @fields.stoptype   = NumField.new(4, "stop type",   1)  #固定值，表示重新搜索OBU
    end
end

#对指定OBU的电子钱包扣费，并向指定的OBU写站信息
class BZFrameC6 < Frame
    def initialize(obuid = 0, money = 0, file0019hex = nil)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",      0xC6)
        @fields.obuid      = NumField.new(4, "Obu ID",            obuid)
        @fields.money      = NumField.new(4, "ConsumeMoney",      money)
        @fields.file0019   = DatField.new(43, "0019 station info")   #过站信息文件0019内容
        #BCD码 yyyymmddhhmmss 该时间由车道程序将出口时间提供给RSU，RSU根据此时间计算TAC
        @fields.datetime   = NumField.new(7, "Formated Datetime",  utils.formatdatetime(utils.datetime_now, "yyyymmddhhnnss"))

        @fields.file0019 <= file0019hex if file0019hex
    end
end

=begin
特殊处理指令－C7本指令是针对卡片已经扣款完毕但是天线并未收到回复的情况所添加的补充帧，
车道程序在获取到B4帧并比对判定为已扣款的卡片后，将发送该帧给天线，
此时，天线应发送指令去获取该卡片上次的TAC码，并在B5中回复给车道软件。
=end
class BZFrameC7 < Frame
    def initialize(obuid = 0)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",      0xC7)
        @fields.obuid      = NumField.new(4, "Obu ID",            obuid)
    end
end

#写本次交易信息指令
class BZFrameC8 < Frame
    def initialize(obuid = 0)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",      0xC8)
        @fields.obuid      = NumField.new(4, "Obu ID",            obuid)
        @fields.data       = DatField.new(48, "000A write info")   #000A文件内容
    end
end

#RSU状态
class BZFrameB0 < Frame
    def initialize
        super()
        @fields.cmd        = NumField.new(1, "Command Type",     0xB0)

        @fields.rsustatus  = NumField.new(1, "RSUStatus",        0x00)
        @fields.rsutermid  = NumField.new(6, "PSAM ID",          0x00)
        @fields.rsualgid   = NumField.new(1, "RSUAlgId",         0x00)
        @fields.rsumanuid  = NumField.new(1, "RSUManuID",        0x00)
        @fields.rsubacuid  = NumField.new(3, "RSUIndividualID",  0x00)
        @fields.version    = NumField.new(2, "RSUVersion",       0x00)
        @fields.reserved   = NumField.new(5, "Reserved",         0x00)
    end
end

#地感信息
class BZFrameB1 < Frame
    def initialize
        super()
        @fields.cmd        = NumField.new(1, "Command Type",     0xB1)

        @fields.iostatus   = NumField.new(1, "RsuIoStatus",      0x00)
        @fields.iocount    = NumField.new(1, "RsuIoChgSum",      0x00)
    end
end

#OBU系统信息帧
class BZFrameB2 < Frame
    def initialize
        super()
        @fields.cmd          = NumField.new(1, "Command Type",        0xB2)

        @fields.obuid        = NumField.new(4, "OBU ID",              0x00)
        @fields.errcode      = NumField.new(1, "ErrorCOde",           0x00)

        @fields.contprovider = NumField.new(4, "ContractProvider",    0x00)
        @fields.conttype     = NumField.new(2, "ContractType",        0x00)
        @fields.contver      = NumField.new(2, "ContractVersion",     0x00)
        @fields.contsn       = NumField.new(8, "ContractSerialNumber",0x00)
        @fields.contsigdate  = NumField.new(4, "ContractSignedDate",  0x00)
        @fields.contexpdate  = NumField.new(4, "ContractExpiredDate", 0x00)

        @fields.hwstatus     = NumField.new(1, "obu hardware version",0x00)
        @fields.obustatus    = NumField.new(2, "obu status",          0x00)
    end
end

#OBU车辆信息帧
class BZFrameB3 < Frame
    def initialize
        super()
        @fields.cmd              = NumField.new(1, "Command Type",   0xB3)

        @fields.obuid            = NumField.new(4, "OBU ID",         0x00)
        @fields.errcode          = NumField.new(1, "ErrorCOde",      0x00)

        @fields.platenumber      = DatField.new(12, "Plate Number")
        @fields.platecolor       = NumField.new(2, "Plate Color")
        @fields.vehtype          = NumField.new(1, "Veh Type")
        @fields.usertype         = NumField.new(1, "User Type")
        @fields.length           = NumField.new(2, "Veh Length")
        @fields.width            = NumField.new(1, "Veh Width")
        @fields.heigth           = NumField.new(1, "Veh Height")
        @fields.wheels           = NumField.new(1, "Veh Wheels")
        @fields.axles            = NumField.new(1, "Axles")
        @fields.axledistance     = NumField.new(2, "Axles Distance")
        @fields.weitghtlimits    = NumField.new(3, "Load/User Limits")
        @fields.specificinfo     = DatField.new(16, "Specific Infomation")
        @fields.enginenumber     = DatField.new(16, "Engine Number")
    end
end

#IC卡信息
class BZFrameB4 < Frame
    def initialize
        super()
        @fields.cmd              = NumField.new(1, "Command Type",       0xB4)

        @fields.obuid            = NumField.new(4, "OBU ID",             0x00)
        @fields.errcode          = NumField.new(1, "ErrorCOde",          0x00)

        @fields.restmoney        = NumField.new(4, "CardRestMoney",      0x00)

        @fields.file0015         = DatField.new(43, "File 0015")
        @fields.file0019         = DatField.new(43, "File 0019")
        @fields.fill             = DatField.new(0,  "File 000A")
    end
end

#成功交易帧
class BZFrameB5 < Frame
    def initialize
        super()
        @fields.cmd          = NumField.new(1, "Command Type",           0xB5)

        @fields.obuid            = NumField.new(4, "OBU ID",             0x00)
        @fields.errcode          = NumField.new(1, "ErrorCOde",          0x00)

        @fields.transtime        = NumField.new(7, "TransTime",          0x00)
        @fields.psamserial       = NumField.new(4, "PSAMTransSerial",    0x00)
        @fields.icctradeno       = NumField.new(2, "ETCTradNo",          0x00)
        @fields.transtype        = NumField.new(1, "TransType",          0x00)
        @fields.restmoney        = NumField.new(4, "CardRestMoney",      0x00)
        @fields.tac              = NumField.new(4, "TAC",                0x00)
        @fields.writetime        = NumField.new(4, "WrFileTime",         0x00)
    end
end

#写IC卡信息结果帧
class BZFrameB8 < Frame
    def initialize
        super()
        @fields.cmd          = NumField.new(1, "Command Type",           0xB8)

        @fields.obuid            = NumField.new(4, "OBU ID",             0x00)
        @fields.errcode          = NumField.new(1, "ErrorCOde",          0x00)
    end
end

#开关天线指令
class BZFrame4C < Frame
    def initialize(operate) #0=关，1=开
        super()
        @fields.cmd          = NumField.new(1, "Command Type",           0x4C)

        @fields.anngate      = NumField.new(1, "AnnGate",                operate)
    end
end

#FF协议是由设备主动发出，RSCTL要取反。
#在resolve是，记下rsctl, 发出时再取反
class RSCTLFF
    def self.nextval
        @_rsctl ||= 0
        @_rsctl = (@_rsctl + 1) % 10
        return @_rsctl + 0x80
    end

    def self.set_rtscl(v)
        @saved_rtsl = v
    end

    def self.use_rtsl
        if @saved_rtsl.nil? || @saved_rtsl == -1
            rsctl = nextval
        else
            rsctl = @saved_rtsl
            rsctl = ((rsctl / 16) | (rsctl * 16)) & 0xFF
        end
        @saved_rtsl = -1
        return rsctl
    end
end


#FF协议是由设备主动发出，RSCTL要取反。
#在resolve是，记下rsctl, 发出时再取反
#ITS
# RSU: 01 ~ 09
# PC : 10 ~ 90
class RSCTLFFITS
    def self.nextval
        @_rsctl ||= 1
        @_rsctl = (@_rsctl + 1) % 10
        if @_rsctl == 0   # PC sequence number can not be 00. should start from 01.
           @_rsctl = 1
        end
        return @_rsctl * 16
    end

    def self.set_rtscl(v)
        @saved_rtsl = v
    end

    def self.use_rtsl
        if @saved_rtsl.nil? || @saved_rtsl == -1
            rsctl = nextval
        else
            rsctl = @saved_rtsl
            rsctl = ((rsctl / 16) | (rsctl * 16)) & 0xFF
        end
        @saved_rtsl = -1
        return rsctl
    end
end


class FrameFFFF < Frame
    def self.ffcount=(v)
        @ffcount = v
    end

    def self.ffcount
        @ffcount
    end

    def initialize(hexdata = nil)
        super()
        init_data(hexdata)
    end

    def init_data(hexdata)
        #开始标志，有可能是一个FF，也有可能是2个FF，个地区不同，构造时从参数传进来，默认是两个
        @fields.stx              = FrameFFFF.ffcount == 1 ? NumField.new(1, "STX", 0xFF) : NumField.new(2, "STX", 0xFFFF)
        @fields.rsctl            = NumField.new(1, "RSCTL")
        @fields.data             = DatField.new(0, "Data")
        #bcc也有可能是FF
        @fields.bcc              = NumField.new(1, "BCC")
        #结束标志，是一个FF
        @fields.etx              = NumField.new(1, "ETX", 0xFF)

        unless hexdata.nil?
            rsctl = RSCTLFF.use_rtsl
            rsctl = RSCTLFF.nextval if rsctl.nil?

            tmpstr = ""
            i = 0
            while i < hexdata.length
                s = hexdata[i..i+1]
                a = s.to_i(16)
                if a == 0xFF
                    tmpstr = tmpstr + "FE01"
                elsif a == 0xFE
                    tmpstr = tmpstr + "FE00"
                else
                    tmpstr = tmpstr + s
                end
                i += 2
            end
            bcc = get_bcc(hex2bin(tmpstr))  #先算后面的
            bcc = bcc ^ rsctl               #再加上第一个字节

            @fields.rsctl <= rsctl
            @fields.data <= tmpstr
            @fields.bcc <= bcc
        end
    end
    #因为 FFFF 协议里面，BCC也是要转义的，所以要重载这个函数
    def to_hs
        str = super
        if @fields.bcc.value == 0XFF
            str = str[0..str.length-5] + "FE01FF"
        elsif @fields.bcc.value == 0XFE
            str = str[0..str.length-5] + "FE00FF"
        end
        return str
    end

    #数据解释，如果能解释成功FF协议，就返回 true，否则返回 false
    def resolve(bytes)
        unless bytes.is_a?(Array)
            puts "#{self.class.name}.resolve, 参数不是一个数组类型"
            return false
        end
        self.clear

        tmpbytes = []
        idxl = bytes.index(0xFF)
        idxr = bytes.rindex(0xFF)
        if (bytes.size > 5) &&  !idxl.nil? && !idxr.nil?
            if (FrameFFFF.ffcount == 2) && (idxr > idxl + 1) && (bytes[idxl + 1] == 0xFF)
                tmpbytes = bytes[idxl+2..idxr-1]
            elsif (idxr > idxl)
                tmpbytes = bytes[idxl+1..idxr-1]
            end
        end
        if tmpbytes.size == 0
            puts "#{self.class.name}.resolve, 解释数据时, 没有找到足够的FF的标志，原始数据：#{bin2hex(bytes)}"
            return false
        end

        #检查BCC是否正确
        bcc = get_bcc(tmpbytes)
        if bcc == 0x00
            for i in 0..tmpbytes.size - 1
                if tmpbytes[i] == 0xFE
                    tmpbytes[i] = tmpbytes[i] + tmpbytes[i+1]
                    tmpbytes.delete_at(i + 1)
                end
            end
            self <= "FF" * FrameFFFF.ffcount + bin2hex(tmpbytes) + "FF"
            RSCTLFF.set_rtscl(self.rsctl.value)  #记录收到的序列号
            return true
        else
            puts "#{self.class.name}.resolve, 解释数据时, BBC校验没有通过,原始数据：#{bin2hex(bytes)}"
            return false
        end
    end

    def self.rsuetc_read_data()
        chkcount = FrameFFFF.ffcount + 1
        recv_finished = lambda{|recvbytes|
            #这判断是否结束。
            #n stx, 1 rsctl, 0 data, 1 bcc, 1 etx,，至少这么多个数据
            #根据协议，连BCC字节都要进行转义，所以，只要在数据中找到 1 + FrameFFFF.ffcount 个FF，即表示结束
            if recvbytes.size >= 3 + FrameFFFF.ffcount
                ffcnt = recvbytes.count{|a| a == 0xFF}

                #有些帧是连续发上来的，比如d0和b2，那么就有可能一次收到两个帧，所以要这么来判断
                return true if (ffcnt % chkcount == 0) && (ffcnt >= chkcount)
            end
            return false
        }
        #可能数据里面包含有多帧，所以要分开，保存到一个数组里面返回,数组里面每一个元素也是一个数组
        recdat = librsuetc_comm.recv_data(recv_finished)

        res = []
        fc = 0
        start = 0
        recdat.each_with_index { |a, i|
            fc = fc + 1 if a == 0xFF
            if (fc > 0) && (fc % chkcount == 0)
                res << recdat[start..i]
                fc = 0
                start = i + 1
            end
        }
        puts "收到帧数为#{res.size}" if res.size > 1
        return res
    end
end

class FrameItsStdFFFF < Frame

    def initialize(hexdata = nil)
        super()
        init_data(hexdata)
    end

    # overide init_data to add version and data
    def init_data(hexdata)
        #开始标志，有可能是一个FF，也有可能是2个FF，个地区不同，构造时从参数传进来，默认是两个
        @fields.stx              = FrameFFFF.ffcount == 1 ? NumField.new(1, "STX", 0xFF) : NumField.new(2, "STX", 0xFFFF)
        @fields.ver              = NumField.new(1, "Version", 0x00)
        @fields.rsctl            = NumField.new(1, "RSCTL")
        @fields.len              = NumField.new(4, "Len")
        @fields.data             = DatField.new(0, "Data")
        #bcc也有可能是FF
        @fields.crc16            = NumField.new(2, "CRC16")
        #结束标志，是一个FF
        #@fields.etx              = NumField.new(1, "ETX", 0xFF)

        unless hexdata.nil?
            rsctl = RSCTLFFITS.use_rtsl
            rsctl = RSCTLFFITS.nextval if rsctl.nil?
            @fields.ver    <= 0x00
            @fields.rsctl  <= rsctl
            @fields.len    <= (hexdata.length / 2)
            #puts "number of data is #{(hexdata.length / 2)}"
            @fields.data   <= hexdata
            @fields.crc16  <= 0x0000
        end
    end

    #因为 FFFF 协议里面，BCC也是要转义的，所以要重载这个函数
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
            self <= "FF" * FrameFFFF.ffcount + data_hex
            RSCTLFFITS.set_rtscl(self.rsctl.value)  #记录收到的序列号
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
            #n stx, 1 versin, 1 rsctl, 4 len , 0 data, 2 crc_16，at least
            #根据协议，只有据长度大于等于 8 + FrameFFFF.ffcount 才有可能是完整的数据帧
            if recvbytes.size >= 8 + FrameFFFF.ffcount
                data_len = peek_len(recvbytes)
                # data_len 必须小于0xFFFF, 如果收到数据大于datalen 加上帧头和帧尾crc长度，才有可能是完整数据帧
                return true if (data_len < 0xFFFF)&& (recvbytes.size >=  (8 + FrameFFFF.ffcount + data_len))
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
            total_len = inx + 2 + 4 + len + 2  # stx + rtctl + len + data + crc16
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
        inx = 0
        while(bytes[inx] == 0xFF)
            inx = inx +1
        end
        packet_len = bytes[(inx+2), 4]
        len_hex = bin2hex(packet_len)
        len = len_hex.to_i(16)
        return len
    end

end

$ff_pro_type = FrameFFFF

def get_ff_potocol_type
    return $ff_pro_type
end

def set_ff_potocol_type(type)
    $ff_pro_type = type
end


FrameFFFF.ffcount = 2

def set_ffcount(c)
    FrameFFFF.ffcount = c
end

def librsuetc_comm
    ucomm
end

#FFFF协议 收发函数, 可以重载
def rsuetc_write_data(hexdata)
    return if hexdata.length == 0
    #get ff frame type myabe 1, normal FFFF Protocol or Its standard FFFF protocol
    ff_type = get_ff_potocol_type()
    reqfrm = ff_type.new(hexdata)
    #puts "final hex data:" + reqfrm.to_hs
    librsuetc_comm.send_data(reqfrm.to_hs)
end


def rsuetc_read_data
    pro_type = get_ff_potocol_type()
    #puts pro_type.inspect
=begin
    if (pro_type == FrameFFFF)
        return rsuetc_read_data_ff()
    elsif(pro_type == FrameItsStdFFFF )
        return rsuetc_read_data_itsff()
    else
        return []
    end
=end
    if (pro_type != nil )
        return pro_type.rsuetc_read_data()
    else
        return[]
    end

end

# Its Std FF protocol recv function
# it's use packet len for split packet
# from tcp bytes fow.
def rsuetc_read_data_itsff
    chkcount = FrameFFFF.ffcount + 1
    recv_finished = lambda{|recvbytes|
        #这判断是否结束。
        #n stx, 1 versin, 1 rsctl, 4 len , 0 data, 2 crc_16，at least
        #根据协议，只有据长度大于等于 8 + FrameFFFF.ffcount 才有可能是完整的数据帧
        if recvbytes.size >= 8 + FrameFFFF.ffcount
            data_len = peek_len(recvbytes)
            # data_len 必须小于0xFFFF, 如果收到数据大于datalen 加上帧头和帧尾crc长度，才有可能是完整数据帧
            return true if (data_len < 0xFFFF)&& (recvbytes.size >=  (8 + FrameFFFF.ffcount + data_len))
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
        total_len = inx + 2 + 4 + len + 2  # stx + rtctl + len + data + crc16
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

=begin
# peek the length of the its std protocol length of the data
def peek_len(bytes)
    inx = 0
    while(bytes[inx] == 0xFF)
        inx = inx +1
    end
    packet_len = bytes[(inx+2), 4]
    len_hex = bin2hex(packet_len)
    len = len_hex.to_i(16)
    return len
end
=end
def rsuetc_read_data_ff
    chkcount = FrameFFFF.ffcount + 1
    recv_finished = lambda{|recvbytes|
        #这判断是否结束。
        #n stx, 1 rsctl, 0 data, 1 bcc, 1 etx,，至少这么多个数据
        #根据协议，连BCC字节都要进行转义，所以，只要在数据中找到 1 + FrameFFFF.ffcount 个FF，即表示结束
        if recvbytes.size >= 3 + FrameFFFF.ffcount
            ffcnt = recvbytes.count{|a| a == 0xFF}

            #有些帧是连续发上来的，比如d0和b2，那么就有可能一次收到两个帧，所以要这么来判断
            return true if (ffcnt % chkcount == 0) && (ffcnt >= chkcount)
        end
        return false
    }
    #可能数据里面包含有多帧，所以要分开，保存到一个数组里面返回,数组里面每一个元素也是一个数组
    recdat = librsuetc_comm.recv_data(recv_finished)

    res = []
    fc = 0
    start = 0
    recdat.each_with_index { |a, i|
        fc = fc + 1 if a == 0xFF
        if (fc > 0) && (fc % chkcount == 0)
            res << recdat[start..i]
            fc = 0
            start = i + 1
        end
    }
    puts "收到帧数为#{res.size}" if res.size > 1
    return res
end
#交易交易状态机，
#初始状态为 :start(一般式), 结束状态为 :finished(过去式), 记住，是有 finished(过去式)
class EtcTradeMachineBase
private
    TR_NOERROR       = 0
    TR_KEEP_STATE    = 1
    TR_BREAK_TRADE   = 2
    TR_RESET_MACHINE = 3
    TR_STOP_MACHINE  = 4

public

    attr_accessor :receivehexdat
    attr_accessor :tosendhexdat
    attr_accessor :trade_result

    def is_continue_trade?
        @trade_result == TR_NOERROR
    end

    def keep_state
        @trade_result = TR_KEEP_STATE
    end

    def is_keep_state?
        @trade_result == TR_KEEP_STATE
    end

    def break_trade
        @trade_result = TR_BREAK_TRADE
    end

    def is_break_trade?
        @trade_result == TR_BREAK_TRADE
    end

    def stop_machine
        @trade_result = TR_STOP_MACHINE
    end

    def is_stop_machine?
        @trade_result == TR_STOP_MACHINE
    end

    def reset_machine
        @trade_result = TR_RESET_MACHINE
    end

    def is_reset_machine?
        @trade_result == TR_RESET_MACHINE
    end

    def send_frame(frm)
        @tosendhexdat << frm.to_hs
    end

    def get_command_byte
        @receivehexdat[0..1]
    end

    def do_trade
        curr_state = state.to_s
        #考虑到有些命令是数字开头的，不能用作变量名，所以处理时，可以前面加下横线，这里先去掉。
        curr_state = curr_state[1..curr_state.length-1] if curr_state.start_with?("_")
        #数据已经是剥离了FF协议的真内容数据，第一个字节是命令字节
        recv_cmd = get_command_byte
		recv_cmd = '' if recv_cmd.nil?
        if recv_cmd && ((recv_cmd.upcase == curr_state.upcase) or (curr_state == "start"))
            #初始状态时，没有接收数据，直接发C0帧
            func_name = "on_trade_#{curr_state}"
            if respond_to?(func_name)
                #调用具体的处理函数
                send(func_name)
                #调用完了看有没有要发的数据，如果有就发出去
                @tosendhexdat.each{|hexdat| rsuetc_write_data(hexdat)}
                @tosendhexdat.clear
                return
            else
                puts "---!!!---当前状态：#{curr_state}, 但是没有定义函数：#{func_name}---!!!---, 处理方法，stop_machine"
                stop_machine
            end
        else
            on_exp = "on_trade_flowexception"
            if respond_to?(on_exp)
                send(on_exp)
                #临时调试模式
                #调用完了看有没有要发的数据，如果有就发出去
                @tosendhexdat.each{|hexdat| rsuetc_write_data(hexdat)}
                @tosendhexdat.clear
                return
            else
                puts "---!!!---当前状态：#{curr_state}, 但是收到的帧命令字节是：#{recv_cmd}---!!!---, 处理方法，break_trade"
                break_trade
            end
        end
        return
    end

    def init_trade_data(receivehexdat)
        #清除错误状态，和待发数据，设置接收待处理数据
        @tosendhexdat = []
        @receivehexdat = receivehexdat
        @trade_result = TR_NOERROR
    end

    def no_error?
        is_continue_trade?
    end
end


class RsuEtc
private
    def run_machine_next_step(machine, receivehexdat)
        machine.init_trade_data(receivehexdat)
        machine.do_trade      #在这个函数里面，根据当前状态调用目标函数，
        if machine.no_error?  #如果正常处理完毕，发送交易事件给状态机，改变当前正常状态
            machine.send :ev_trade
        else                  #如果交易有异常，
            if machine.respond_to?(:ev_control)
                #第一种写法，不好看，不好理解，已经取消,但是还是保留这
                machine.send :ev_control
            else
                #现在用这种写法了。
                if machine.is_break_trade?
                    machine.send :ev_break
                elsif machine.is_reset_machine?
                    machine.send :ev_reset
                elsif machine.is_stop_machine?
                    machine.send :ev_stop
                end
            end
        end
    end
public
    def run_machine(machine, condf = nil)
        if machine.state.to_s == "start"
            #如果是初始状态，是PC端先发起初始化设备
            run_machine_next_step(machine, "")
        end
        uloop(condf) do
            recs = rsuetc_read_data
            recs.each{|res|
                if res.size > 5
                    ff_type = get_ff_potocol_type
                    frm = ff_type.new
                    #puts "origin data: #{bin2hex(res)}"
                    if frm.resolve(res)
                        run_machine_next_step(machine, frm.data.to_hs)
                    end
                end
            }
            break if machine.state.to_s == "finished"
        end
        if machine.respond_to?(:on_trade_finished)
            sleep 0.01
            machine.init_trade_data ""
            machine.send :on_trade_finished
            machine.tosendhexdat.each { |hexdat| rsuetc_write_data(hexdat)}
            machine.tosendhexdat.clear
        end
        if machine.respond_to?(:on_testcase_done)
            sleep 5
            machine.send :on_testcase_done
            librsuetc_comm.close()
            librsuetc_comm.open()
            librsuetc_comm.clear()
        end
    end


# 并行交易分为控制帧和交易数据帧
# 如C0 B0 B1 这些作为控制帧, 使用控制状态机执行
    def run_machine_paralell(machine_cls, condf = nil)
=begin
        if machine.state.to_s == "start"
            #如果是初始状态，是PC端先发起初始化设备
            run_machine_next_step(machine, "")
        end
=end
        # key obuid, value state_machine, in this case , a obu will use a state machine instance.
        @machine_list = {}
        @machine_list["control_ms"] = machine_cls.new
        run_machine_next_step(@machine_list["control_ms"], "")#init contrl machine state.
        uloop(condf) do
            recs = rsuetc_read_data
            recs.each{|res|
                if res.size > 5
                    ff_type = get_ff_potocol_type
                    frm = ff_type.new
                    #puts "origin data: #{bin2hex(res)}"
                    if frm.resolve(res)
                        #control state frame such as B0 B1, send to control state machine.
                        if(frm.data.to_hs[0..1] == "B0" || (machine_cls.respond_to?(:is_control_frame?))&&(machine_cls.is_control_frame?(frm.data.to_hs[0..1])))
                            run_machine_next_step(@machine_list["control_ms"], frm.data.to_hs)
                        elsif # trade flow Frame , except B1 B0
                            obuid_hex = frm.data.to_hs[2..9]
                            if (frm.data.to_hs[0..1] == "B2")
                                # if no obuid found in current hash
                                 if(!@machine_list.has_key?(obuid_hex)) # add obu state machine if not exist
                                     @machine_list[obuid_hex] = machine_cls.new
                                     puts "allocate machine for obu:#{obuid_hex}"
                                     if @machine_list[obuid_hex].state.to_s == "start"
                                        #如果是初始状态，是PC端先发起初始化设备
                                         run_machine_next_step(@machine_list[obuid_hex], "") # initialize the state
                                         #run_machine_next_step(@machine_list[obuid_hex], frm.data.to_hs)
                                     end
                                 end
                            end
                            run_machine_next_step(@machine_list[obuid_hex], frm.data.to_hs)
                         end
                    end
                end
            }
            break if @machine_list["control_ms"].state.to_s == "finished"
        end
        if @machine_list["control_ms"].respond_to?(:on_trade_finished)
            sleep 0.01
            @machine_list.values.each do |machine| #loop all machines in list to send data out.
                machine.init_trade_data ""
                machine.tosendhexdat.each { |hexdat| rsuetc_write_data(hexdat)}
                machine.tosendhexdat.clear
            end

            @machine_list["control_ms"].init_trade_data ""
            @machine_list["control_ms"].send :on_trade_finished
            @machine_list["control_ms"].tosendhexdat.each { |hexdat| rsuetc_write_data(hexdat)}
        end
        if @machine_list["control_ms"].respond_to?(:on_testcase_done)
            sleep 5
            @machine_list["control_ms"].send :on_testcase_done
            librsuetc_comm.close()
            librsuetc_comm.open()
            librsuetc_comm.clear()
        end
    end
end

def rsuetc
    @rsuetc ||= RsuEtc.new
end
