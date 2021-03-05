# -*- coding: UTF-8 -*-
# librsuicc.rb
# 作者：王政
# 描述：RSU设备的通道接口，以M600T为原型开发，可以支持G60E，M600h,等设备，只要实现了55AA通道协议的理论上都可以
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

require File.dirname(__FILE__)+"/ucore"
require File.dirname(__FILE__)+"/frame"

class RequestFrame < Frame
    attr_accessor :response

    #发送协议数据, 返回 resp frame
    def action(&b)
        if block_given?
            instance_eval(&b)
        end
    end

    def setting()
        if block_given?
            yield
        end
    end

    def working()
        if block_given?
            yield
        end
    end

    def transmit(reqframe)
        command = reqframe.command if reqframe.respond_to?(:command)
        raise "#{reqframe.class.to_s} 没有定义command函数" unless command
        rspframe = reqframe.rspframe if reqframe.respond_to?(:rspframe)
        if rspframe
            hexret = rsuicc_read_write_55aa(command, reqframe.to_hs, true)
            ret = rspframe.new
            if hexret[0..1] == "00" #根据协议，第一个字节是状态码，状态为0，才有后面的内容
                hexret = hexret[2..hexret.length-1]
                ret <= hexret
            else
                puts "!!! #{reqframe.class.to_s} 发送请求后返回状态码不为00，原始数据是：#{hexret}"
            end
            return ret
        else
            rsuicc_read_write_55aa(command, reqframe.to_hs, false)
            return nil
        end
    end

    def request()
        @response = transmit(self)  #transmit函数在子类里面实现，可以被重载
        if block_given?
            yield @response
        end
        return @response
    end

end

class ResponseFrame < Frame
    def working()
        if block_given?
            yield
        end
    end
end

####################################################################################################
class RSCTL
    def self.nextval
        @_rsctl ||= 0
        @_rsctl = (@_rsctl + 1) % 8
    end
end

class Frame55AA < Frame
    def initialize(cmd = 0, hexdata = nil)
        super()
        @fields.stx              = NumField.new(2, "STX", 0x55AA)
        @fields.rsctl            = NumField.new(1, "RSCTL")
        @fields.len              = NumField.new(2, "Length")
        @fields.cmd              = NumField.new(1, "Command", cmd)
        @fields.data             = DatField.new(0, "Data")
        @fields.bcc              = NumField.new(1, "bcc")

        unless hexdata.nil?
            rsctl = RSCTL.nextval

            @fields.data <= hexdata
            @fields.rsctl <= rsctl
            len = hexdata.length / 2
            @fields.len <= len
            ret = sprintf("%.02X%.04X%.02X%s", rsctl, len, cmd, hexdata)
            bcc = get_bcc(hex2bin(ret))

            @fields.bcc <= bcc
        end
    end

    #数据解释，如果能解释成功55aa协议，就返回 true，否则返回 false
    def resolve(bytes)
        unless bytes.is_a?(Array)
            puts "#{self.class.name}.resolve, 参数不是一个数组类型"
            return false
        end
        self.clear
        hexstr = bin2hex(bytes)
        idx = hexstr.index("55AA")
        if idx && (idx % 2 == 0)
            hexstr = hexstr[idx..hexstr.length-1]
            self <= hexstr
            len1 = @fields.len.value
            len2 = @fields.data.length
            if len1 > len2     #少了
                puts "#{self.class.name}.resolve, 解释数据时，实际数据长度比需要的数据长度少#{len1 - len2}个字节，原始数据：#{bin2hex(bytes)}"
                return false
            elsif len1 < len2  #多了
                self.clear
                hexstr = hexstr[0..(hexstr.length-1-((len2-len1)*2))]
            end
            #检查BCC是否正确
            datbytes = hex2bin(hexstr)
            if get_bcc(datbytes) == 0xFF  #55^AA = FF，后面的bcc=00, FF^00=FF
                #没问题
                self <= hexstr
                return true
            else
                puts"#{self.class.name}.resolve, 解释数据时, BBC校验没有通过,原始数据：#{bin2hex(bytes)}"
                return false
            end
        end
        puts "#{self.class.name}.resolve, 解释数据时, 没有找到55AA的标志，原始数据：#{bin2hex(bytes)}"
        return false
    end

    def recv_finished(recvbytes)
        if recvbytes.size >= 5
            idx55 = recvbytes.index(0x55)
            if idx55.nil?
                recvbytes.clear
                puts "接受数据帧55AA前有多余数据，被截取掉---1"
            else
                idxaa = recvbytes.index(0xAA)
                if (idxaa.nil? && (idx55 < recvbytes.size - 1)) || (!idxaa.nil? &&  (idxaa > idx55 + 1))
                    recvbytes.clear
                    puts "接受数据帧55AA前有多余数据，被截取掉---2"
                else
                    if idx55 > 0
                        recvbytes = recvbytes[idx55..recvbytes.size-1]
                        puts "接受数据帧55AA前有多余数据，被截取掉---3"
                    end
                    len = recvbytes[3] * 256 + recvbytes[4]
                    if recvbytes.size >= len + 7
                        return true
                    end
                end
            end
        end
        return false
    end

end

##############################这里定义的帧是M600T的非接触IC卡接口##########################
class M600TReaderFrame < Frame
    def initialize(cmd = 0, hexdata = nil)
        super()
        @fields.stx              = NumField.new(1, "STX", 0XFF)
        @fields.rsctl            = NumField.new(1, "RSCTL")
        @fields.cmd              = NumField.new(1, "Command", cmd)
        @fields.len              = NumField.new(1, "Length")
        @fields.data             = DatField.new(0, "Data")
        @fields.bcc              = NumField.new(1, "bcc")

        hexdata = "" if hexdata.nil?

        rsctl = RSCTL.nextval

        @fields.rsctl <= rsctl
        len = hexdata.length / 2
        if len > 255
            len = 255
            hexdata = hexdata[0..len*2-1]
        end
        @fields.data <= hexdata if len > 0
        @fields.len <= len
        ret = sprintf("FF%.02X%.02X%.02X%s", rsctl, cmd, len, hexdata)
        bcc = get_bcc(hex2bin(ret))

        @fields.bcc <= bcc
    end

    def resolve(bytes)
        unless bytes.is_a?(Array)
            puts "#{self.class.name}.resolve, 参数不是一个数组类型"
            return false
        end
        self.clear
        hexstr = bin2hex(bytes)
        idx = hexstr.index("FF")
        if idx && (idx % 2 == 0)
            hexstr = hexstr[idx..hexstr.length-1]
            self <= hexstr
            len1 = @fields.len.value
            len2 = @fields.data.length
            if len1 > len2     #少了
                puts "#{self.class.name}.resolve, 解释数据时，实际数据长度比需要的数据长度少#{len1 - len2}个字,，原始数据：#{bin2hex(bytes)}"
                return false
            elsif len1 < len2  #多了
                self.clear
                hexstr = hexstr[0..(hexstr.length-1-((len2-len1)*2))]
            end
            #检查BCC是否正确
            datbytes = hex2bin(hexstr)
            bcc = get_bcc(datbytes)
            if bcc == 0x00
                #没问题
                self <= hexstr
                return true
            else
                puts"#{self.class.name}.resolve, 解释数据时BBC校验没有通过,原始数据：#{bin2hex(bytes)}"
                return false
            end
        end
        puts "#{self.class.name}.resolve, 解释数据时, 没有找到FF的标志，原始数据：#{bin2hex(bytes)}"
        return false
    end

    def recv_finished(recvbytes)
        if recvbytes.size > 0
            idxff = recvbytes.index(0xFF)
            if idxff.nil?
                recvbytes.clear
                puts "接受数据帧FF前有多余数据，被截取掉---1"
            else
                if idxff > 0
                    recvbytes = recvbytes[idxff..recvbytes.size-1]
                    puts "接受数据帧FF前有多余数据，被截取掉---2"
                end
                if recvbytes.size >= 4
                    len = recvbytes[3]
                    if recvbytes.size >= len + 5
                        return true
                    end
                end
            end
        end
        return false
    end

end

class RSUInitFrame < RequestFrame
    def initialize
        super
        @fields.time    = NumField.new(4, "Unix Time",            utils.get_unix_time_hex)
        @fields.bst     = NumField.new(1, "BST Interval",         15)
        @fields.retry   = NumField.new(1, "Retry Interval",       15)
        @fields.power   = NumField.new(1, "Power",                5)
        @fields.channel = NumField.new(1, "PLL Channel",         0)

        def command
            0xF0
        end

        def rspframe
            RSUInitRespFrame
        end
    end
end

#扩展了两个字段
class RSUInitExtFrame < RequestFrame
    def initialize
        super
        @fields.time       = NumField.new(4, "Unix Time",            utils.get_unix_time_hex)
        @fields.bst        = NumField.new(1, "BST Interval",         15)
        @fields.retry      = NumField.new(1, "Retry Interval",       15)
        @fields.power      = NumField.new(1, "Power",                5)
        @fields.channel    = NumField.new(1, "PLL Channel",          0)
        @fields.bstcount   = NumField.new(1, "bstcount",             150)
        @fields.retrycount = NumField.new(1, "RetryCount",           5)

        def command
            0xF0
        end

        def rspframe
            RSUInitRespFrame
        end
    end
end

class RSUInitRespFrame < ResponseFrame
    def initialize
        super
        @fields.rsuid     = NumField.new(4, "RSU ID",         0)
        @fields.rsuver    = NumField.new(2, "RSU Version",    0)
    end
end

class GBBSTFrame < RequestFrame
    def initialize
        super

        @fields.mac_addr     = NumField.new(4, "MAC Address",         0xFFFFFFFF)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",         0x50)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",         0x03)
        @fields.field_head   = NumField.new(1, "Field Header",        0x91)

        @fields.bst_flag     = BitField.new(4, "BST Flag",            0b1100)
        @fields.opt_nodisp   = BitField.new(1, "Option indicator",    0b0)
        @fields.fill1        = BitField.new(3, "Fill1",               0b000)

        @fields.beaconid     = NumField.new(4, "BeaconID",            0x02000001)
        @fields.unixtime     = NumField.new(4, "UnixTime",            utils.get_unix_time_hex)
        @fields.profile      = NumField.new(1, "Profile",             0x00)
        @fields.mandapps     = NumField.new(1, "MandApplications",    0x01)

        @fields.opt_dsrcdid  = BitField.new(1, "Dsrc-did display",    0b0)
        @fields.opt_param    = BitField.new(1, "Parameter exist",     0b1)
        @fields.opt_apd      = BitField.new(6, "ApplicationEntityID", 0b000001)

        @fields.opt_container= BitField.new(1, "Container exist",     0b1)
        @fields.icctransmode = BitField.new(7, "ICC Transfer Mode",   0b0000011)

        @fields.pertreatparam= NumField.new(1, "PretreatPara",        0x29)

        @fields.opt_0002     = BitField.new(1, "pre read 0002",       0b0)
        @fields.opt_0012     = BitField.new(1, "pre read 0012",       0b0)
        @fields.opt_0015     = BitField.new(1, "pre read 0015",       0b0)
        @fields.opt_0019     = BitField.new(1, "pre read 0019",       0b0)
        @fields.fill2        = BitField.new(4, "Fill2",               0b0000)

        @fields.sysinfolen   = NumField.new(1, "SysInfoFileLen",      0x1A)  #read system file 0x1A Bytes
        @fields.len_0002     = NumField.new(2, "Length of 0002",      0x00, nil, @fields.opt_0002)
        @fields.len_0012     = NumField.new(2, "Length of 0012",      0x00, nil, @fields.opt_0012)
        @fields.len_0015     = NumField.new(2, "Length of 0015",      0x00, nil, @fields.opt_0015)
        @fields.len_0019     = NumField.new(2, "Length of 0019",      0x00, nil, @fields.opt_0019)

        @fields.profilelist  = NumField.new(1, "ProfileList",         0x00)
    end

    def command
        0xF1
    end

    def rspframe
        GBVSTFrame
    end
end

class GBVSTFrame < ResponseFrame
    def initialize
        super

        @fields.mac_addr     = NumField.new(4, "MAC Address",         0x00)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",         0xC0, 0xC0)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",         0x03, 0x03)

        @fields.field_head   = NumField.new(1, "Field Header",        0x91, 0x91)

        @fields.vst_flag     = BitField.new(4, "VST Flag",            0b1101, 0b1101)
        @fields.fill1        = BitField.new(4, "Fill1",               0b0000, 0b0000)

        @fields.profile      = NumField.new(1, "Profile",             0x00)
        @fields.applist      = NumField.new(1, "ApplicationList",     0x01)

        @fields.opt_dsrcdid  = BitField.new(1, "Dsrc-did display",    0b1, 0b1)
        @fields.opt_appctxmk = BitField.new(1, "Parameter exist",     0b1, 0b1)
        @fields.opt_aid      = BitField.new(6, "Aid",                 0b000001, 0b000001)

        @fields.did          = NumField.new(1, "PretreatPara",        0x01, 0x01)

        @fields.opt_rndobe   = BitField.new(1, "RndOBE exist",        0b0, 0b0)
        @fields.opt_privinfo = BitField.new(1, "privateInfo exist",   0b0, 0b0)
        @fields.opt_gbiccinfo= BitField.new(1, "gbiccinfo exist",     0b1, 0b1)
        @fields.fill2        = BitField.new(5, "Fill2",               0b00000, 0b0000)

        @fields.sysinfoflag  = NumField.new(1, "SysInfo Container",   0x20)  #or 0x27
        @fields.contprovider = NumField.new(8, "ContractProvider",    0x00)
        @fields.conttype     = NumField.new(1, "ContractType",        0x00)
        @fields.contver      = NumField.new(1, "ContractVersion",     0x00)
        @fields.contsn       = NumField.new(8, "ContractSerialNumber",0x00)
        @fields.contsigdate  = NumField.new(4, "ContractSignedDate",  0x00)
        @fields.contexpdate  = NumField.new(4, "ContractExpiredDate", 0x00)

        @fields.iccinfoflag  = NumField.new(1, "ICCInfo Container",   0x00, nil, @fields.opt_gbiccinfo)
        @fields.iccinfo      = DatField.new(0, "ICC PreRead Info",    @fields.opt_gbiccinfo) #预读文件内容，顺序 0015 0012 0019 0002

        @fields.obuid        = NumField.new(4, "ObuConfigMacID",      0x00)

        @fields.equclass     = BitField.new(4, "EquipmentClass",      0b0001)
        @fields.equversion   = BitField.new(4, "EquipmentVersion",    0b0000)

        #obustatus 2 bytes
        @fields.iccpresent   = BitField.new(1, "Icc Present",         0b0)
        @fields.icctype      = BitField.new(3, "Icc Type",            0b000)
        @fields.iccstatus    = BitField.new(1, "Icc Status",          0b0)
        @fields.obulocked    = BitField.new(1, "Obu Locked",          0b0)
        @fields.obutampered  = BitField.new(1, "Obu Tampered",        0b0)
        @fields.battery      = BitField.new(1, "Battery Status",      0b0)

        @fields.counter      = NumField.new(1, "counter",             0x00)
    end
end

class GBGetSecureFrame < RequestFrame
    def initialize(obuid = 0)
        super()
        @fields.need_ack     = NumField.new(1, "Need to Ack",        1)  #是否需要返回，透明传输F2指令里面的字段，不属于帧协议里面的内容
        #-------------------------------------------------------------------
        @fields.mac_addr     = NumField.new(4, "MAC Address",        obuid)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",        0x40)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",        0x77)
        @fields.field_head   = NumField.new(1, "Field Header",       0x91)

        @fields.actionreq    = BitField.new(4, "Action.request",     0b0000)
        @fields.opt_acccredt = BitField.new(1, "AccessCredentialsOp",0b0)
        @fields.actionparam  = BitField.new(1, "Have parameter",     0b1)
        @fields.iid          = BitField.new(1, "Action.request",     0b0)
        @fields.ack_mod      = BitField.new(1, "Answer Mode",        0b1)

        @fields.did          = NumField.new(1, "DID",                0x01) #DID, ETC应用为1, 标识站应用为2
        @fields.actiontype   = NumField.new(1, "Action Type",        0x00)
        @fields.acccredt     = NumField.new(8, "accessCredentials",  0x00, nil, @fields.opt_acccredt)
        @fields.getsecurerq  = NumField.new(1, "GetSecureRq",        0x14)

        @fields.opt_kidenc   = BitField.new(1, "KeyIDforEncryptOp", 0b1)
        @fields.fiell1       = BitField.new(7, "Fill",              0b0000000)

        @fields.fid          = NumField.new(1, "ETC File ID",       0x01)
        @fields.offset       = NumField.new(2, "Read Offset",       0x00)
        @fields.length       = NumField.new(1, "Read Length",       59)
        @fields.random       = NumField.new(8, "Ramdom for MAC",    0x00)
        @fields.kid4auth     = NumField.new(1, "KeyID for Gen MAC", 0x00)
        @fields.kid4enc      = NumField.new(1, "KeyID for Encrypt", 0x00, nil, @fields.opt_kidenc)
    end

    def command
        0xF2
    end

    def rspframe
        GBGetSecureRespFrame
    end
end

class GBGetSecureRespFrame < ResponseFrame
    def initialize
        super

        @fields.mac_addr     = NumField.new(4, "MAC Address",     0x00)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",     0xE0, 0xE0)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",     0xF7, 0xF7)
        @fields.field_status = NumField.new(1, "Field Status",    0x00, 0x00)
        @fields.field_head   = NumField.new(1, "Field Header",    0x91, 0x91)

        @fields.actionresp   = BitField.new(8, "Action.response", 0b00011000, 0b00011000)

        @fields.did          = NumField.new(1, "DID",             0x01, 0x01)
        @fields.getsecureresp= NumField.new(1, "GetSecureRs",     0x15, 0x15)
        @fields.fid          = NumField.new(1, "ETC File ID",     0x01, 0x01)

        @fields.filecontent  = DatField.new(0, "File Content")

        @fields.authenticator= NumField.new(8, "Authenticator",   0x00, 0x00)
        @fields.retstatus    = NumField.new(1, "ReturnStatus",    0x00)
    end
end

ICC_CHANNEL_ID = 1  #IC卡通道编号
ESAM_CHANNEL_ID = 2 #ESAM通道编号

class GBObuChannelFrame < RequestFrame
    def initialize(obuid = 0, channelid = ICC_CHANNEL_ID)
        super()
        @fields.need_ack     = NumField.new(1, "Need to Ack",        1)  #是否需要返回, 透明传输F2指令里面的字段，不属于帧协议里面的内容
        #-------------------------------------------------------------------
        @fields.mac_addr     = NumField.new(4, "MAC Address",        obuid)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",        0x40)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",        0x77)
        @fields.field_head   = NumField.new(1, "Field Header",       0x91)

        @fields.actionreq    = BitField.new(4, "Action.request",     0b0000)
        @fields.opt_acccredt = BitField.new(1, "AccessCredentialsOp",0b0)
        @fields.actionparam  = BitField.new(1, "Have parameter",     0b1)
        @fields.iid          = BitField.new(1, "Action.request",     0b0)
        @fields.ack_mod      = BitField.new(1, "Answer Mode",        0b1)

        @fields.did          = NumField.new(1, "DID",                0x01) #DID, ETC应用为1, 标识站应用为2
        @fields.actiontype   = NumField.new(1, "Action Type",        0x03)
        @fields.channelrq    = NumField.new(1, "Channel Rq",         0x18)
        @fields.channelid    = NumField.new(1, "Channel id",         channelid)

        @fields.apdulist     = ApduList.new("Apdu List")
    end

    def command
        0xF2
    end

    def rspframe
        GBObuChannelRespFrame
    end
end

class GBObuChannelRespFrame < ResponseFrame
    def initialize
        super

        @fields.mac_addr     = NumField.new(4, "MAC Address",     0x00)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",     0xE0, 0xE0)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",     0xF7, 0xF7)
        @fields.field_status = NumField.new(1, "Field Status",    0x00)
        @fields.field_head   = NumField.new(1, "Field Header",    0x91, 0x91)

        @fields.actionres    = BitField.new(8, "Action.response", 0b00011000, 0b00011000)

        @fields.did          = NumField.new(1, "DID",             0x01, 0x01) #DID, ETC应用为1, 标识站应用为2
        @fields.channelrs    = NumField.new(1, "ChannelRq",       0x19, 0x19)
        @fields.channelid    = NumField.new(1, "Channel id",      0x01) #icc=1, esam=2

        @fields.apdulist     = ApduList.new("Apdu List")
        @fields.retstatus    = NumField.new(1, "ReturnStatus",    0x00)
    end
end

class GBPsamResetFrame < RequestFrame
    def initialize(slot = 0)
        super()
        @fields.slot     = NumField.new(1, "Slot Number", slot)
    end

    def command
        0xF8
    end

    def rspframe
        GBPsamResetRespFrame
    end
end

class GBPsamResetRespFrame < ResponseFrame
    def initialize
        super
        @fields.slot     = NumField.new(1, "Slot Number", 0)
        @fields.len      = NumField.new(1, "Data len",    0)  # = 6 if has response
        @fields.psamno   = NumField.new(6, "PSAM No",     0)
    end
end

class GBSetMMIFrame < RequestFrame
    def initialize(obuid = 0)
        super()
        @fields.need_ack     = NumField.new(1, "Need to Ack",        1)  #是否需要返回, 透明传输F2指令里面的字段，不属于帧协议里面的内容
        #-------------------------------------------------------------------
        @fields.mac_addr     = NumField.new(4, "MAC Address",         obuid)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",         0x40)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",         0x77)
        @fields.field_head   = NumField.new(1, "Field Header",        0x91)

        @fields.actionreq    = BitField.new(4, "Action.request",      0b0000)
        @fields.opt_acccredt = BitField.new(1, "AccessCredentialsOp", 0b0)
        @fields.actionparam  = BitField.new(1, "Have parameter",      0b1)
        @fields.iid          = BitField.new(1, "Action.request",      0b0)
        @fields.ack_mod      = BitField.new(1, "Answer Mode",         0b1)

        @fields.did          = NumField.new(1, "DID",                 0x01)

        @fields.actiontype   = NumField.new(1, "Action Type",         0x04)

        @fields.setmmirq     = NumField.new(1, "SetMMI.rq",           0x1A)
        @fields.mmiparam     = NumField.new(1, "MMI Parameter",       0x00) #0 - OK, 1- NOK, 2....
    end

    def command
        0xF2
    end

    def rspframe
        GBSetMMIRespFrame
    end
end

class GBSetMMIRespFrame < ResponseFrame
    def initialize
        super

        @fields.mac_addr     = NumField.new(4, "MAC Address",     0x00)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",     0xE0, 0xE0)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",     0xF7, 0xF7)
        @fields.field_status = NumField.new(1, "Field Status",    0x00, 0x00)
        @fields.field_head   = NumField.new(1, "Field Header",    0x91, 0x91)

        @fields.actionres    = BitField.new(8, "Action.response", 0b00011000, 0b00011000)

        @fields.did          = NumField.new(1, "DID",             0x01, 0x01)

        @fields.setmmirs     = NumField.new(1, "SetMMI.rs",       0x1B, 0x1B)
        @fields.retstatus    = NumField.new(1, "ReturnStatus",    0x00) #OBU give this value
    end
end


class GBEventReportFrame < RequestFrame
    def initialize(obuid = 0)
        super()
        @fields.need_ack     = NumField.new(1, "Need to Ack",        0)  #是否需要返回, 不用. 透明传输F2指令里面的字段，不属于帧协议里面的内容
        #-------------------------------------------------------------------
        @fields.mac_addr     = NumField.new(4, "MAC Address",         obuid)
        @fields.mac_ctrl     = NumField.new(1, "MAC Control",         0x40)
        @fields.llc_ctrl     = NumField.new(1, "LLC Control",         0x03)
        @fields.field_head   = NumField.new(1, "Field Header",        0x91)

        @fields.reportreq    = BitField.new(4, "vent_Report.request", 0b0110)
        @fields.opt_acccredt = BitField.new(1, "AccessCredentialsOp", 0b0)
        @fields.actionparam  = BitField.new(1, "Have parameter",      0b0)
        @fields.iid          = BitField.new(1, "Action.request",      0b0)
        @fields.ack_mod      = BitField.new(1, "Answer Mode",         0b0)  #无需应答

        @fields.did          = NumField.new(1, "DID",                 0x00) #与应用无关

        @fields.eventtype    = NumField.new(1, "Event Type",          0x00)
    end

    def command
        0xF2
    end

    # EventReport不需要返回，所以不要定义这个函数
    # def rspframe
    #
    # end
end


class GBPsamChannelFrame < RequestFrame
    def initialize(slot = 0)
        super()
        @fields.slot         = NumField.new(1, "Psam Slot",         slot)
        @fields.apdulist     = ApduList.new("Apdu List")
    end

    def command
        0xF9
    end

    def rspframe
        GBPsamChannelRespFrame
    end
end

class GBPsamChannelRespFrame < ResponseFrame
    def initialize()
        super()
        @fields.apdulist     = ApduList.new("Apdu List")
    end
end
########################################################################
#读取RSUIP的协议
class RSUGetIPFrame < RequestFrame
    def initialize()
        super()
        @fields.optype     = NumField.new(1, "Read IP Command", 1)
        @fields.ip         = NumField.new(4, "IP addr",         0)
    end

    def command
        0xF4
    end

    def rspframe
        RSUGetIPRespFrame
    end
end

class RSUGetIPRespFrame < ResponseFrame
    def initialize()
        super()
        @fields.optype     = NumField.new(1, "Read IP Command", 1)
        @fields.ip         = NumField.new(4, "IP addr",         0)
    end
end

#设置RSUIP的协议
class RSUSetIPFrame < RequestFrame
    def initialize()
        super()
        @fields.optype     = NumField.new(1, "Write IP Command", 0)
        @fields.ip         = NumField.new(4, "IP addr",          0)
    end

    def command
        0xF4
    end

    def rspframe
        RSUSetIPRespFrame
    end
end

class RSUSetIPRespFrame < ResponseFrame
    def initialize()
        super()
        #如果设置成功，ip字段为所设ip，所以我这里预设 0
        @fields.optype     = NumField.new(1, "Write IP Command", 0)
        @fields.ip         = NumField.new(4, "IP addr",          0)
    end
end

##########################################################################
#读取CRC的协议
class RSUGetCRCFrame < RequestFrame
    def initialize()
        super()
        @fields.optype     = NumField.new(1, "Read CRC Command", 1)
        @fields.crc        = NumField.new(1, "CRC init",         0)
    end

    def command
        0xF5
    end

    def rspframe
        RSUGetCRCRespFrame
    end
end

class RSUGetCRCRespFrame < ResponseFrame
    def initialize()
        super()
        @fields.optype     = NumField.new(1, "Read CRC Command", 1)
        @fields.crc        = NumField.new(1, "CRC init",        0xFF)
    end
end

#设置CRC的协议
class RSUSetCRCFrame < RequestFrame
    def initialize()
        super()
        @fields.optype     = NumField.new(1, "Write CRC Command", 0)
        @fields.crc        = NumField.new(1, "CRC init",     0)
    end

    def command
        0xF5
    end

    def rspframe
        RSUSetCRCRespFrame
    end
end

class RSUSetCRCRespFrame < ResponseFrame
    def initialize()
        super()
        #如果设置成功，ip字段为所设ip，所以我这里预设 0
        @fields.optype     = NumField.new(1, "Write CRC Command", 0)
        @fields.crc        = NumField.new(1, "CRC init",     0xFF)
    end
end

#########################################################################


#国标系统信息文件结构
class GBSystemFile < Frame
    def initialize
        super
        @fields.contprovider = NumField.new(8, "ContractProvider",    0x00)
        @fields.conttype     = NumField.new(1, "ContractType",        0x00)
        @fields.contver      = NumField.new(1, "ContractVersion",     0x00)
        @fields.contsn       = NumField.new(8, "ContractSerialNumber",0x00)
        @fields.contsigdate  = NumField.new(4, "ContractSignedDate",  0x00)
        @fields.contexpdate  = NumField.new(4, "ContractExpiredDate", 0x00)
        @fields.counter      = NumField.new(1, "Tear Counter",        0x00)
    end
end

#国标车辆信息文件
class GBVehicleFile < Frame
    def initialize
        super
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

class GBUserCard0015 < Frame
    def initialize
        super
        @fields.contprovider     = NumField.new(8, "ContractProvider")
        @fields.cardtype         = NumField.new(1, "Card ")
        @fields.cardversion      = NumField.new(1, "Card Version")
        @fields.network          = NumField.new(2, "Network")
        @fields.cardid           = NumField.new(8, "Card ID")
        @fields.contsigdate      = NumField.new(4, "SignedDate")
        @fields.contexpdate      = NumField.new(4, "ExpiredDate")
        @fields.platenumber      = DatField.new(12, "Plate Number")
        @fields.usertype         = NumField.new(1, "User Type")
        @fields.platecolor       = NumField.new(1, "Plate Color")
        @fields.vehtype          = NumField.new(1, "Vehicle Type")
        #新国标才有后面这两个字段，旧国标43字节，新国标50字节
        # @fields.reserved1        = NumField.new(3, "Reserved1")
        # @fields.reserved2        = NumField.new(4, "Reserved2")
    end
end


#0019文件第一条记录文件结构。
class GBUserCard0019 < Frame
    def initialize
        super
        @fields.flag             = NumField.new(1, "App Flag", 0xAA)
        @fields.reclen           = NumField.new(1, "Record Length ", 0x29)
        @fields.locked           = NumField.new(1, "is Locked",0x00)
        @fields.network          = NumField.new(2, "Network")
        @fields.station          = NumField.new(2, "Station")
        @fields.lane             = NumField.new(1, "Lane")         #车道编号
        @fields.unixtime         = NumField.new(4, "Unix Time")
        @fields.vehtype          = NumField.new(1, "Vehicle Type") #车型
        @fields.entrystatus      = NumField.new(1, "Entry Status") #出入口状态
        @fields.resvered1        = NumField.new(9, "Reserved1")
        @fields.stuffid          = NumField.new(3, "Stuff ID")     #收费员工号
        @fields.workid           = NumField.new(1, "Work Time ")   #收费员班次
        @fields.plateno          = NumField.new(12, "Plate No")
        @fields.resvered2        = NumField.new(4, "Reserved2")
    end
end

CMD_MAKE_CONNECT          = 0x71
CMD_RSU_TRANSFER_CHANNEL  = 0x85

class XTPacket < Frame
    def initialize(cmd = 0, hexdata = nil)
        super()
        @fields.commandid        = NumField.new(4, "Command ID",   cmd)
        @fields.commanddata      = NumField.new(4, "Command Data", 0x00)
        @fields.bodylength       = NumField.new(4, "Body Length",  0x00)
        @fields.packetbody       = DatField.new(0, "Packet Data")

        unless hexdata.nil?
            @fields.bodylength <= hexdata.length / 2
            @fields.packetbody <= hexdata
        end
     end
    def resolve(bytes)
        unless bytes.is_a?(Array)
            puts "XTPacket.resolve, 参数不是一个数组类型"
            return false
        end
        self.clear
        hexstr = bin2hex(bytes)
        self <= hexstr
        len1 = @fields.bodylength.value
        len2 = @fields.packetbody.length
        if len1 > len2     #少了
            puts "XTPacket.resolve, 解释数据时，实际数据长度比需要的数据长度少#{len1 - len2}个字节"
            return false
        elsif len1 < len2  #多了
            self.clear
            hexstr = hexstr[0..(hexstr.length-1-((len2-len1)*2))]
            self <= hexstr
        end
        return true
    end

    def recv_finished(recvbytes)
        if recvbytes.size >= 12
            len = recvbytes[8] * 1703936 + recvbytes[9] * 65536 + recvbytes[10] * 256 + recvbytes[11]
            if recvbytes.size >= len + 12
                true
            else
                false
            end
        else
            false
        end
    end
end

def librsuicc_comm
    ucomm
end

#55AA协议
def rsuicc_read_write_55aa_orgi(cmd, hexdata, needretrun = true)
    reqfrm = Frame55AA.new(cmd, hexdata)
    if needretrun
        ret = librsuicc_comm.send_recv(reqfrm)
        respfrm = Frame55AA.new
        if respfrm.resolve(ret)
            if cmd == (respfrm.cmd.value + 0x10)
                return respfrm.data.to_hs
            else
                puts "返回数据解释cmd字节与发送的字节不匹配"
                return ""
            end
        else
            puts "返回数据解释错误，或者没有返回数据"
            return ""
        end
    else
        librsuicc_comm.send_data(reqfrm.to_hs)
        return ""
    end
end

def rsuicc_read_write_55aa_pxml(cmd, hexdata, needretrun = true)
    f55aa = Frame55AA.new(cmd, hexdata)
    head = '<?xml version="1.0" encoding="gb2312"?><grid><titles><chl_data/></titles><records><r0><c0>'
    tail = '</c0></r0></records></grid>  '
    xmlstr = head + f55aa.to_hs + tail
    xmlhex = sprintf("%.08X%s", xmlstr.length, bin2hex(xmlstr.bytes))
    reqfrm = XTPacket.new(CMD_RSU_TRANSFER_CHANNEL, xmlhex)
    if needretrun
        ret = librsuicc_comm.send_recv(reqfrm)
        respfrm = XTPacket.new
        if respfrm.resolve(ret)
            xmlhex = respfrm.packetbody.to_hs
            xmlhex = xmlhex[8..xmlhex.length-1]
            xmlret = bin2str hex2bin(xmlhex)
            p1 = xmlret.index("<c0>")
            p2 = xmlret.index("</c0>")
            if !p1.nil? && !p2.nil?
                hex55aa = xmlret[p1+4..p2-1]
                respfrm = Frame55AA.new
                respfrm <= hex55aa
                if cmd == (respfrm.cmd.value + 0x10)
                    return respfrm.data.to_hs
                else
                    puts "返回数据解释cmd字节与发送的字节不匹配"
                    return ""
                end
            end
        else
            puts "返回数据解释错误，或者没有返回数据"
            return ""
        end
        return ""
    else
        librsuicc_comm.send_data(reqfrm.to_hs)
        return ""
    end
end

def rsuicc_read_write_55aa(cmd, hexdata, needretrun = true)
    if librsuicc_comm.ptxml?
        rsuicc_read_write_55aa_pxml(cmd, hexdata, needretrun)
    else
        rsuicc_read_write_55aa_orgi(cmd, hexdata, needretrun)
    end
end

#ic卡读写器协议

def rsuicc_read_write_iccreader(cmd, hexdata)
    reqfrm = M600TReaderFrame.new(cmd, hexdata)
    rsctl = reqfrm.rsctl.value
    ret = librsuicc_comm.send_recv(reqfrm)
    respfrm = M600TReaderFrame.new
    if respfrm.resolve(ret)
        if rsctl == respfrm.rsctl.value
            return respfrm.data.to_hs
        else
            puts "返回数据rtscl字节与发送的字节不匹配"
            return ""
        end
    else
        puts "返回数据解释错误，或者没有返回数据"
        return ""
    end
end

class RsuIcc
public
    attr_accessor :obuid

    def initialize
        @obuid = 0x02000001
    end

    #设置设备参数，params 可用的参数包括 :bst, :retry, :power, :channel
    #默认 :bst => 15, :retry => 15, :power => 5, :channel => 0, time = {currenttime}
    def dev_set_param(params={})
        init = RSUInitFrame.new
        init.set_field_values(params)
        ret = init.request
        if ret.rsuid.value == 0 #设置失败，返回空的东西
            return {}
        else
            tmp = {}
            ret.get_field_values(tmp)   #返回结果保存到要临时变量
            init.get_field_values(tmp)  #把设置的参数也保存到临时变量，方便上层处理
            return tmp
        end
    end

    ########################################----OBU类功能-参数都是16进制字符串-------------------------------
    #发送BST，并搜索OBU，返回OBU系统信息
    #其中，options可以包含以下参数
    #:rsuid = [x,x,x,x]    如果没有设定rsuid, 则使用默认的方法，02开头，每次都变
    #:df01 = true,false    如果true，则最后进入DF01，false，则停留在3F00
    def gb_obu_search(option={})
        obuinfo = {}
        #发送BST，搜索OBU
        GBBSTFrame.new().action do
            setting do
                #原始参数设置就按GBBSTFrame的字段设置。
                set_field_values(option)

                #还有另外处理一下，方便一点，比如beaconid有时候也写做rsuid
                #当写了rsuid 并且没写 beaconid 时，认为它是习惯问题。
                beaconid <= option[:rsuid] if option[:beaconid].nil? and !option[:rsuid].nil?

                #预读顺序：0015,0012, 0019,0002
                opt_0015 <= 1  if !option[:len_0015].nil? and option[:opt_0015].nil?
                opt_0012 <= 1  if !option[:len_0012].nil? and option[:opt_00102].nil?
                opt_0019 <= 1  if !option[:len_0019].nil? and option[:opt_0019].nil?
                opt_0002 <= 1  if !option[:len_0002].nil? and option[:opt_0002].nil?
            end
            request do |vst|
                if vst.mac_addr.value != 0
                    #原始返回参数
                    vst.get_field_values(obuinfo)

                    #获取分散因子, 方便上层处理
                    str = vst.contprovider.to_hs[0..7]
                    obuinfo[:divid] = vst.contsn.to_hs + str * 2  #序列号 + 运营商代码前4个字节（两遍）

                    # #获取预读信息，上层应用可以自己处理，也可以直接取这里的结果
                    str = vst.iccinfo.to_hs
                    gnext = {}
                    obuinfo[:f0015] = hex_get_next(str, option[:len_0015], gnext) if !option[:len_0015].nil?
                    obuinfo[:f0012] = hex_get_next(str, option[:len_0012], gnext) if !option[:len_0012].nil?
                    obuinfo[:f0019] = hex_get_next(str, option[:len_0019], gnext) if !option[:len_0019].nil?
                    obuinfo[:f0002] = hex_get_next(str, option[:len_0002], gnext) if !option[:len_0002].nil?
                    obuinfo[:balance] = obuinfo[:f0002].to_i(16) if !obuinfo[:f0002].nil?

                    #这里要注意，不能再这里用一下的句子设置@obuid，等出去以后再设置，至于为什么，我也不知道，还没研究清楚哦
                    # @obuid = vst.obuid.value
                end
            end
        end

        @obuid = obuinfo[:obuid].to_i(16)

        if option[:df01] == true
            gb_obu_esam_command(coss.entry_dir("DF01"))
        end

        return obuinfo
    end

    #获取车辆信息文件内容
    #hexrand 从PSAM取，随机数，
    #offset 起始位置，默认是从0开始
    #length 长度，默认是-1，取全部长度59个字节，取值>=0时，按实际取，但是返回什么，<0时，默认就取59个字节
    #offset + length 组合，回返回什么，完全看COS
    #返回的内容，是加密的，回头还要用PSAM解密
    def gb_obu_get_secure(hexrand, voffset = 0, vlength = -1)
        #GetSecure 取车辆信息,
        GBGetSecureFrame.new(obuid).action{
            setting{
                random <= hexrand
                offset <= voffset
                length <= vlength if vlength > 0
            }
            request do | ret |
                return ret.filecontent.to_hs #返回文件内容, 加密
            end
        }
    end

    #OBU通道，所发指令为COS指令，APDU格式，用add_apdu函数组装
    #其中channel=1为IC卡，2为ESAM
    #  papdulist 是指令，APDU格式，用add_apdu函数封装, 返回也是apdulist格式
    #  也可以用["HEXCMD1", "HEXCMD2"] 返回也是[{:resp, :sw12}, {:resp, :sw12}, {:resp, :sw12}]式
    def gb_obu_transfer_channel(channel, papdulist)
        GBObuChannelFrame.new(obuid, channel).action{
            setting {
                if papdulist.is_a?(Hash)
                    while (cmd = get_apdu(papdulist)) != ""
                        apdulist << cmd
                    end
                else
                    papdulist.each { |cmd| apdulist << cmd}
                end
            }
            request {|resp|
                if papdulist.is_a?(Hash)
                    str = resp.apdulist.to_hs
                    apduret = {}
                    apduret[:count] = str[0..1].to_i(16)
                    apduret[:apdus] = str[2..str.length-1]
                    apduret[:index] = 0
                    apduret[:point] = 0
                    return apduret
                else
                    i = 0
                    ret = []
                    begin
                        res = resp.apdulist.get_apdu_sw12(i)
                        i = i + 1
                        ret << res unless res.empty?
                    end while !res.empty?
                    return ret
                end
            }
        }
    end

    #OBU.ESAM通道，所发指令为COS指令，APDU格式，用add_apdu函数组装
    def gb_obu_esam_channel(apdulist)
        gb_obu_transfer_channel(2, apdulist)
    end

    #OBU.ICC通道，所发指令为COS指令，APDU格式，用add_apdu函数组装
    def gb_obu_icc_channel(apdulist)
        gb_obu_transfer_channel(1, apdulist)
    end

    #OBU.ESAM通道，所发指令为COS指令，是16进制字符串的一条指令
    #返回的是{:resp=>"xxxx", :sw12=>"xxxx"}格式
    def gb_obu_esam_command(hexcmd)
        apdulist = add_apdu(hexcmd)
        apduret = gb_obu_transfer_channel(2, apdulist)
        hexapdu = get_apdu(apduret)
        split_sw12(hexapdu)
    end

    #OBU.ICC通道，所发指令为COS指令，APDU格式，是16进制字符串的一条指令
    #返回的是{:resp=>"xxxx", :sw12=>"xxxx"}格式
    def gb_obu_icc_command(hexcmd)
        apdulist = add_apdu(hexcmd)
        apduret = gb_obu_transfer_channel(1, apdulist)
        hexapdu = get_apdu(apduret)
        split_sw12(hexapdu)
    end

    #obu set mmi, 参数就不用写了用默认即可，因为OBU似乎只写了一个接口。
    #params :action=>0 ,ok, 1,error, 2,请联系运营商, 其他自定义,
    def gb_obu_set_mmi(params={})
        mmf = GBSetMMIFrame.new(obuid)
        mmf.set_field_values(params)
        mmf.mmiparam <= params[:action] if !params[:action].nil? && params[:mmiparam].nil?
        mmf.request
    end

    #gb_obu_event_report
    def gb_obu_event_report
        evf = GBEventReportFrame.new(obuid)
        evf.request
    end

    ########################################----PSAM类功能--------------------------------
    #设备的psam通道函数，其中
    #  slot = PSAM卡卡槽，1 为卡槽1， 2为卡槽2，注意，不同设备的卡槽开始可能不一样。一般是从1开始，也有些从0开始。
    #  papdulist 是指令，APDU格式，用add_apdu函数封装, 返回也是apdulist格式
    #  也可以用["HEXCMD1", "HEXCMD2"] 返回也是[{:resp, :sw12}, {:resp, :sw12}, {:resp, :sw12}]式
    def dev_psam_channel(slot, papdulist)
        GBPsamChannelFrame.new(slot).action do
            setting do
                if papdulist.is_a?(Hash)
                    while (cmd = get_apdu(papdulist)) != ""
                        apdulist << cmd
                    end
                else
                    papdulist.each { |cmd| apdulist << cmd}
                end
            end
            request { |resp|
                if papdulist.is_a?(Hash)
                    str = resp.apdulist.to_hs
                    apduret = {}
                    apduret[:count] = str[0..1].to_i(16)
                    apduret[:apdus] = str[2..str.length-1]
                    apduret[:index] = 0
                    apduret[:point] = 0
                    return apduret
                else
                    i = 0
                    ret = []
                    begin
                        res = resp.apdulist.get_apdu_sw12(i)
                        i = i + 1
                        ret << res unless res.empty?
                    end while !res.empty?
                    return ret
                end
            }
        end
    end

    #对dev_psam_channel进行封装，但是只执行一条命令,hexcmd是16进制命令字符串
    # 返回{:resp=>"xxxx", :sw12=>"xxxx"}
    def dev_psam_command(slot, hexcmd)
        apdulist = add_apdu(hexcmd)
        apduret = dev_psam_channel(slot, apdulist)
        hexapdu = get_apdu(apduret)
        split_sw12(hexapdu)
    end

    #取终端编号，也可以用指令读PSAM卡的3F00目录下的0016文件前6个字节
    #国标规定，PSAM复位的时候，自动返回0016文件内容
    def dev_psam_reset(slot)
        resinfo = {}
        GBPsamResetFrame.new(slot).action do
            request do |resp|
                if resp.len.value == 6
                    resp.get_field_values(resinfo)
                end
            end
        end
        resinfo[:psamno] = "" if resinfo[:psamno].nil?
        return resinfo
    end

    #m600t,g60e设置ip
    def dev_set_ip(strip)
        if true
            ipbytes = utils.ip2bytes(strip)
            ret = false
            if ipbytes.size > 0
                RSUSetIPFrame.new.action do
                    setting do
                        ip <= bin2hex(ipbytes)
                    end
                    request do |resp|
                        ret = true if resp.ip.to_hs == bin2hex(ipbytes)
                    end
                end
            else
                puts "dev_set_ip函数的参数ip: #{ip} 不是一个合法地址" if ipbytes.size == 0
            end
            return ret
        else
            ipbytes = utils.ip2bytes(strip)
            ret = false
            if ipbytes.size > 0
                req = RSUSetIPFrame.new
                req.ip <= bin2hex(ipbytes)
                resp = req.request
                ret = true if resp.ip.to_hs == bin2hex(ipbytes)
            else
                puts "dev_set_ip函数的参数ip: #{ip} 不是一个合法地址" if ipbytes.size == 0
            end
            return ret
        end
    end

    #m600t,g60e获取ip
    def dev_get_ip
        req = RSUGetIPFrame.new
        resp = req.request
        utils.bytes2ip(hex2bin(resp.ip.to_hs))
    end

    def dev_set_crc(crctype)  #crc = 0 or 1, 0=国标全FF， 1=全0
        ret = false
        RSUSetCRCFrame.new.action do
            setting do
                crc <= crctype
            end
            request do |resp|
                ret = true if resp.crc.value == crctype
            end
        end
        return ret
    end

    #m600t,g60e获取ip
    def dev_get_crc
        req = RSUGetCRCFrame.new
        resp = req.request
        return resp.crc.value if resp.crc.value == 0 || resp.crc.value == 1
        raise "dev_get_crc 失败，可能设备不支持该功能"
    end


    #M600T才能使用，打开非接触界面的卡片，返回16进制字符串的卡片ID
    #用网口时不支持此功能
    def dev_open_card
        ret = rsuicc_read_write_iccreader(0x84, "")
        return ret[0..ret.length-1-2]
    end

    #关闭M600T的13.56M  RF
    def dev_close_rf
        ret = rsuicc_read_write_iccreader(0x90, "")
        return ret[0..ret.length-1-2]
    end

    #M600T才能使用，执行卡片TimeCoS指令
    #用网口时不支持此功能
    #返回{:resp=>"", :sw12=>""}
    def dev_pro_command(hexcmd)
        ret = rsuicc_read_write_iccreader(0x60, hexcmd)
        split_sw12(ret)
    end

    def self.inst
        @rsuicc ||= RsuIcc.new
    end
end

def rsuicc
    RsuIcc.inst
end

alias g60e rsuicc
alias g60h rsuicc
alias m600t rsuicc

