# -*- coding: UTF-8 -*-
# ebox_frame.rb
# 作者：dongtc
# 描述：Ebox测试接口。
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

#require  "utest"
require_relative '../lib/utest'
class EboxFrameE0 < Frame

  def initialize(txpower: 10,channel:0, mode:0)
    super()
    @fields.cmd        = NumField.new(1, "Command Type",                          0xE0)
    @fields.statuscode = NumField.new(1, "Status Code ",                          0x00)
    @fields.rsuswitch  = NumField.new(1, "Rsu Switch",                            0x00)
    @fields.psamstatus = NumField.new(1, "Psam Status",                           0x00)
    @fields.workmode   = DatField.new(0, "Sw Version"                                 )

  end
end


class EboxFrameE1 < Frame
  def initialize(obuid =0)
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xE1)
    @fields.obuid      = NumField.new(4, "Obu ID",         obuid)
    @fields.iccsn      = DatField.new(10, "OBU ICC SN"         )
    @fields.sys_file   = DatField.new(26, "System File"         )
    @fields.veh_file   = DatField.new(79, "Veh  File"         )
    @fields.card_file  = DatField.new(50, "0015  File"         )
    @fields.obu_status = DatField.new(2, "OBU status"         )
    @fields.money      = DatField.new(4, "Cost Moeny"         )
  end
end


class EboxFrameE2 < Frame
  def initialize(obuid =0)
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xE2)
    @fields.obuid      = NumField.new(4, "Obu ID",         obuid)
    @fields.obutype    = NumField.new(1, "OBU Type" ,       0x00)
    @fields.iccstatus    = NumField.new(1, "ICC Exist",           0x00)
    @fields.obustatus    = NumField.new(1, "Obu Status",          0x00)

    @fields.sysinfo      = DatField.new(26, "System Info")
    @fields.vehinfo      = DatField.new(79, "Veh Info")
    @fields.icc0015      = DatField.new(50, "ICC 0015")
    @fields.rest_money   = NumField.new(4, "CardRestMoney",       0x00)
    @fields.last_station = DatField.new(43, "LastStation 0019 file")
    @fields.reserved     = NumField.new(1, "Reservd", 0x00)
    @fields.tradeerr     = NumField.new(1, "Trade Error", 0x00)
    @fields.restmoeny    = NumField.new(4, "Rest Money", 0x00)
    @fields.transtime    = NumField.new(7, "Trans Time", 0x00)
    @fields.keytype      = NumField.new(1, "Key Type", 0x00)
    @fields.psamtradesn  = NumField.new(4, "Psam Trade Sn", 0x00)
    @fields.psamid       = NumField.new(6, "Psam Terminal ID", 0x00)
    @fields.icctradesn   = NumField.new(2, "ICC trade sn", 0x00)
    @fields.tac          = NumField.new(4, "Tac", 0x00)
    @fields.psamsn       = DatField.new(10, "Psam Sn")
    @fields.iccrand      = NumField.new(4, "Icc rand", 0x00)
    @fields.trademoney   = NumField.new(4, "Trade Money", 0x00)
    @fields.entrytime    = NumField.new(7, "Entry Time", 0x00)

  end

end 

class EboxFrameE3 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",     0xE3)
    @fields.status       = NumField.new(1, "Status",           0x00)
    @fields.psam_cnt     = NumField.new(1, "Need Psam Auth count" ,       0x00)
    @fields.psamid       = NumField.new(6, "Psam Terminal ID", 0x00)
    @fields.psamsn       = DatField.new(10, "Psam Sn")
    @fields.keytype      = NumField.new(1, "Key Type",         0x00)
    @fields.psam_ver     = NumField.new(1, "Psam Version",     0x00)
    @fields.area_code    = NumField.new(8, "Area Code",        0x00)
    @fields.random       = NumField.new(8, "Rand Number",      0x00)
    
  end

end 

class EboxFrameE4 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",     0xE4)
    @fields.status       = NumField.new(1, "Status",           0x00)
    @fields.psam_cnt     = NumField.new(1, "Need Psam Auth count" ,       0x00)
    @fields.auth_status  = NumField.new(2, "Auth Status",      0x00)
  end
end 

class EboxFrameE5 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",     0xE4)
    @fields.status       = NumField.new(1, "Status",           0x00)
  end

end 

class EboxFrameE6 < Frame
  def initialize(obuid =0)
    super()
    @fields.cmd          = NumField.new(1, "Command Type",    0xE2)
    @fields.obuid        = NumField.new(4, "Obu ID",         obuid)
    @fields.sysinfo      = DatField.new(26, "System Info")
    @fields.icc0015      = DatField.new(28, "ICC 0015")
    @fields.keytype      = NumField.new(1, "Key Type",        0x00)
    @fields.veh_length   = NumField.new(1, "Veh Info Length", 0x00)
    @fields.veh_info     = DatField.new(88, "Veh Info")
    #@fields.rand         = NumField.new(4,  "Rand Number",    0x00)
  end
end 


class EboxFrameE7 < Frame
  def initialize
    super()
    @fields.cmd          = NumField.new(1, "Command Type",        0xE7)
    @fields.icc_info     = DatField.new(16, "vendor and number")
    @fields.randnum      = NumField.new(4, "Icc Rand",            0x00)
    @fields.icc_serial   = NumField.new(2, "consume serial",      0x00)
    @fields.money        = NumField.new(4, "Consume Money",       0x00)
    @fields.tran_time    = NumField.new(7, "transfer date and time",    0x00)
    @fields.tran_mode    = NumField.new(1, "trade mode 09",       0x09)
    @fields.key_type     = NumField.new(1, "key type ",        0x00)
    @fields.pyh_id       = NumField.new(2, "Consume Slot ",    0x00)
    @fields.psam_id      = NumField.new(6, "Psam terminal Number ",    0x00)
    @fields.check_mac2   = NumField.new(1, "Check Mac2 or Not ",    0x00)
    @fields.serial       = DatField.new(32, "Serial Num ")
    #@fields.balance      = NumField.new(4, "Balance",              0x00)
    #@fields.version      = NumField.new(1, "Version",              0x00)
    #@fields.alg          = NumField.new(1, "Algorithm",            0x00)
  end
end


class EboxFrameF0 < Frame
  def initialize(obuid =0 )
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xF0)
  end
end

class EboxFrameF1 < Frame
  def initialize(obuid =0 )
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xF1)
    @fields.blacklist  = NumField.new(1, "Black List",   0x00)
  end
end

class EboxFrameF2 < Frame
  def initialize(obuid =0 )
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xF2)
    @fields.status     = NumField.new(1, "Status",         0x00)
  end
end

class EboxFrameF3 < Frame
  def initialize()
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xF3)
  end
end

class EboxFrameF4 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",   0xF4)
    @fields.psam_cnt     = NumField.new(1, "Status",         0x00)
    @fields.random       = NumField.new(8, "Rand Number",    0x00)
    @fields.mac          = NumField.new(8, "Mac",            0x00)
  end
end

class EboxFrameF5 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",   0xF5)
  end
end

class EboxFrameF6 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",            0xF6)
    @fields.status       = NumField.new(1, "Status",                  0x00)
    @fields.is_black     = NumField.new(1, "In Black List",           0x00)
    @fields.pyh_id       = NumField.new(2, "Consume Slot ",           0x00)
    @fields.psam_id      = NumField.new(6, "Psam terminal Number",    0x00)
    @fields.serial       = DatField.new(32, "Consume Sequence Number")
    @fields.veh_length   = NumField.new(1, "Veh Info Length", 0x4F)
    @fields.veh_info     = DatField.new(79, "Veh Info")
  end
end 

class EboxFrameF7 < Frame
  def initialize()
    super()
    @fields.cmd          = NumField.new(1, "Command Type",       0xF7)
    @fields.status       = NumField.new(1, "Status",             0x00)
    @fields.mac1         = NumField.new(4, "Mac1",               0x00)
    @fields.psam_serial  = NumField.new(4, "Psam trade serial",  0x00)
  end
end 

class EboxFrameC2 < Frame
  def initialize(obuid =0, stoptype=1)
    super()
    @fields.cmd        = NumField.new(1, "Command Type",   0xC2)
    @fields.obuid      = NumField.new(4, "Obu ID",         obuid)
  end
end


class EboxFrameC4 < Frame
  def initialize(switch:1)
    super()
    @fields.cmd        = NumField.new(1, "Command Type",      0xC4)
    @fields.switch     = NumField.new(1, switch)
 end
end


class EboxFrameC6 < Frame
  def initialize(obuid = 0, file0019hex = nil)
    super()
    @fields.cmd        = NumField.new(1, "Command Type",       0xC6)
    @fields.obuid      = NumField.new(4, "Obu ID",            obuid)
	@fields.money      = NumField.new(4, "Cost Money",         00  )
    @fields.transtime  = NumField.new(7, "Trans Time",         utils.formatdatetime(utils.datetime_now, "yyyymmddhhnnss"))

    @fields.file0019   = DatField.new(43, "0019 station info")   #过站信息文件0019内容
    @fields.file0019  <= file0019hex if file0019hex
	@fields.entrytime  = NumField.new(7, "Entry Time",         utils.formatdatetime(utils.datetime_now, "yyyymmddhhnnss"))
  end
end


class EboxFrameCA < Frame
  def initialize()
    super()
    @fields.cmd        = NumField.new(1, "Command Type",      0xCA)
  
  end
end

class EboxFrameCB < Frame
  def initialize()
    super()
    @fields.cmd        = NumField.new(1, "Command Type",      0xCA)
	@fields.mac        = NumField.new(8, "MAC Code",            00)
  
  
  end
end





class EboxFrameBA < Frame
  def initialize
    super()
    @fields.cmd        = NumField.new(1, "Command Type",     0xBA)
    @fields.nil        = NumField.new(4, "Command Type",     0x00)
    @fields.anngate    = NumField.new(1, "AnnGate",     0x00)

  end
end

class EboxFrameB0 < Frame
  def initialize
    super()
    @fields.cmd           = NumField.new(1, "Command Type",     0xB0)
    @fields.rsustatus     = NumField.new(1, "RSUStatus",        0x00)
	@fields.rsumanuid     = NumField.new(1, "RSUManuID",        0x00)
	@fields.rsubacuid     = NumField.new(3, "RSU ID",           0x00)
	@fields.sw_version    = NumField.new(2, "SW RSUVersion",    0x00)
	@fields.hw_version    = NumField.new(2, "HW RSUVersion",    0x00)
	@fields.proto_version = NumField.new(2, "Proto Version",    0x00)
    @fields.psam_status   = NumField.new(1, "PSAM Status",      0x00)

  end
end

class EboxFrameB2 < Frame
  def initialize
    super()
    @fields.cmd           = NumField.new(1, "Command Type",     0xB2)
    @fields.statuscode    = NumField.new(1, "RSUStatus",        0x00)
	@fields.rsu_switch    = NumField.new(1, "RSU Switch",       0x00)
	@fields.psam_status   = NumField.new(6, "PSAM Status",      0x00)
  end
end

class EboxFrameB4 < Frame
  def initialize
    super()
    @fields.cmd          = NumField.new(1, "Command Type",        0xB4)

    @fields.obuid        = NumField.new(4, "OBU ID",              0x00)
	@fields.obutype      = NumField.new(1, "OBU Type",            0x00)
    @fields.iccstatus    = NumField.new(1, "ICC Exist",           0x00)
    @fields.obustatus    = NumField.new(1, "Obu Status",          0x00)

    @fields.sysinfo      = DatField.new(26, "System Info")
    @fields.vehinfo      = DatField.new(79, "Veh Info")
    @fields.icc0015      = DatField.new(50, "ICC 0015")
    @fields.rest_money   = NumField.new(4, "CardRestMoney",       0x00)
    @fields.last_station = DatField.new(43, "LastStation 0019 file")
    @fields.blacklist    = NumField.new(1, "Black List Status", 0x00)
	@fields.reserved     = DatField.new(63, "Reserved Info")

  end
  
end

class EboxFrameB5 < Frame
  def initialize
    super()
    @fields.cmd          = NumField.new(1, "Command Type",        0xB5)

    @fields.obuid        = NumField.new(4, "OBU ID",              0x00)
	@fields.obutype      = NumField.new(1, "OBU Type",            0x00)
    @fields.errcode      = NumField.new(1, "Error Code",          0x00)
    @fields.traderecord  = DatField.new(64, "Trade Record")
  end
  
end


=begin
class EboxFrameF6 < Frame
  def initialize
    super()
    @fields.cmd          = NumField.new(1, "Command Type",        0xF6)
    @fields.obuid        = NumField.new(4, "OBU ID",              0x00)
    @fields.errcode      = NumField.new(1, "ErrorCOde",           0x00)
    @fields.iccrand      = NumField.new(4, "ICC card random",     0x00)

    @fields.iccoffsn     = NumField.new(2, "ICC card off trans sn",    0x00)
    @fields.costmoney    = NumField.new(4, "trans cost moeny",    0x00)
    @fields.tran_type    = NumField.new(1, "trans_type",          0x00)
    @fields.tran_time    = NumField.new(7, "trans date and time", 0x00)
    @fields.key_ver      = NumField.new(1, "key version ",        0x00)
    @fields.key_idx      = NumField.new(1, "key index",           0x01)
   
  end
  
end
=end


class EboxFrameC8 < Frame
    def initialize(obuid = 0,cardtran=0)
        super()
        @fields.cmd        = NumField.new(1, "Command Type",      0xC8)
        @fields.obuid      = NumField.new(4, "Obu ID",            obuid)
		@fields.costmoney  = NumField.new(4, "Card cost Money",   0x00)
        @fields.psamno     = NumField.new(6, "PsamNo",            0x00)
    end
end


class Frame_Cpucard_0015 < Frame
    def initialize
        super()
        @fields.vendor_id              = NumField.new(8, "Vendor ID",           0x00)
        @fields.card_type              = NumField.new(1, "Card Type",           0x00)
        @fields.card_ver               = NumField.new(1, "Card Version",        0x00)
        @fields.card_net_num           = NumField.new(2, "Card Net Num",        0x00)
        @fields.card_internal_num      = NumField.new(8, "Card Internal Num",   0x00)
	@fields.begin_time             = NumField.new(4, "Begin Time",          0x00)
	@fields.expire_time            = NumField.new(4, "Expire Time",         0x00)
	@fields.plate_num              = DatField.new(12, "Plate Number")
	@fields.user_type              = NumField.new(1, "User Type",           0x00)
	@fields.plate_color            = NumField.new(1, "Plate Color",         0x00)
	@fields.vehicle_type           = NumField.new(1, "Vehicle Type",        0x00)
	    

    end
end


class Frame_ESAM_SysInfo < Frame
    def initialize
        super()
        @fields.vendor_id              = NumField.new(8, "发行方标识",           0x00)
        @fields.card_type              = NumField.new(1, "协约类型",             0x00)
        @fields.card_ver               = NumField.new(1, "合同版本,1xH:旧国标,4xH:新国标,5xH:国密卡  ",  0x00)
        @fields.contractsn             = NumField.new(8, "合同序列号",           0x00)
        @fields.signdate               = NumField.new(4, "签署日期",             0x00)
        @fields.expiredate             = NumField.new(4, "到期日期",             0x00)
		

    end
end



