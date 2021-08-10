# -*- coding: UTF-8 -*-
# File       : sw_esam.rb
# Author     ：董铁城
# Descripton ：ESAM software simulator
# History    : init version,  2018/01/02
# Copyright (C), 2010-2020, ShenZhen Genvict Technologies Co.,Ltd
# All rights reserved


require_relative "../lib/utest"
require 'pathname'



VEH_INFO_ENCRYPT_KEY = "AA293AC8A26A79C33F21BF47D5EF47A2"  #车辆信息加解密
VEH_INFO_UPDATE_KEY  = "9C10C654B4D677914CB347AE1DB39942"  #车辆信息更新 , 内部的测试秘钥， 应用维护秘钥， 需要经过 ESAM SN 一次分散
SYS_INFO_UPDATE_KEY  = "038CCE092AA4E021515FF46C17F25CAC"  #系统信息更新 , 内部的测试秘钥， 卡片维护秘钥， 需要经过 ESAM SN 一次分散
            BMPK     = "C3D11CCAD69BE0DFDF19DCD86432AAC7"  #消费主秘钥
            MTK      = "ED66B90CDBF0F71DE2F90A1D89AE000A"  # TAC 主秘钥


CRC_POLYNOM          =  0x1021
CRC_POLYNOM_REVERSE  =  0x8408


def calc_crc16(init_crc=0xFFFF , crc_data_bytes)
    crc = init_crc

    crc_data_bytes.each do |b|
        crc = crc ^ b
        for k in (0..7)
            if((crc & 0x1) != 0)
                crc = (crc >> 1)
                crc = crc ^ CRC_POLYNOM_REVERSE
            else
                crc = (crc >> 1)
            end
        end
    end

    crc = crc & 0xFFFF
    #crc = (~crc) & 0xFFFF
    crc_hex = sprintf("%.04X", crc)
    return crc
end


# PSAM 内部数据定义

PSAM_TERMINAL_ID   = "000000000184"  # PSAM中终端号
PSAM_TRADE_SERIAL  = "0003C5F0"      # PSAM交易序号初始值，每次交易后递增
ALL_ZERO_KEY       = "00000000000000000000000000000000"

class SwPsam


    attr_reader :psam_term_id
    attr_reader :psam_trade_sn
    attr_reader :mac2
    attr_reader :div_times   # 需要分散的次数 0 代表不需要分散

    def initialize(region_code, serial_num, div_times = 2)
        init_keys()
        @region_code = region_code
        @serial_num  = serial_num
        @mac2        = ''
        @div_times   = div_times
        @psam_trade_sn = "0003C5F0"
        @psam_term_id  = "000000000184"
        if (@div_times == 2)
            tmp_key =  utils.des_diversify(@region_code, @VEH_INFO_ENCRYPT_KEY)
            tmp_key =  utils.des_diversify(@serial_num, tmp_key )
            @obu_key = tmp_key
        elsif (@div_times == 1)
            tmp_key =  utils.des_diversify(@serial_num, @VEH_INFO_ENCRYPT_KEY )
            @obu_key = tmp_key
        elsif
            @obu_key = @VEH_INFO_ENCRYPT_KEY
        end
        puts "derived key is #{@obu_key}"

    end

    def init_keys()
        @VEH_INFO_ENCRYPT_KEY = "AA293AC8A26A79C33F21BF47D5EF47A2"
        @BMPK                 = "C3D11CCAD69BE0DFDF19DCD86432AAC7"
        @LOAD_KEY             = "C3D11CCAD69BE0DFDF19DCD86432AAC7"
    end
    def set_div_times(times)
        @div_times = times
    end

    # desc : 车辆信息解密
    # para1: 车辆信息密文， 包含长度， MAC， 车辆信息明文 和填充
    # ret  : 车辆信息明文， 包含长度， MAC， 车辆信息明文 和填充
    def decrypt_veh_info(hex_vehinfo_cipher)

        hex_vehinfo_plaint = utils.des_decrypt(hex_vehinfo_cipher, @obu_key)
        #puts "veh info plaint #{hex_vehinfo_plaint}"
        return hex_vehinfo_plaint
    end

    # desc :  计算车辆信息MAC（交通部MAC 8字节）
    # para1:  RSU下发随机数
    # para2:  车辆信息明文， 不含MAC和填充信息
    # ret  :  车辆信息MAC
    def calc_esam_vehicle_mac(hex_rand, veh_info)
        assert(0x10, hex_rand.size(),"rand data size should be 8 bytes")
        crc_val = calc_crc16(hex2bin(veh_info))
        crc_hex = sprintf("%.04X", crc_val)
        hex_data = crc_hex[2..3] + crc_hex[0..1] +  hex_rand[4..15]
        hex_mac = utils.des_encrypt(hex_data , @obu_key )
        puts "hex_mac : #{hex_mac}"
        return hex_mac
    end



    # desc : 车辆MAC信息校验
    # para1: 车辆信息密文，包含长度, MAC和填充
    # para2: RSU下发的随机数
    # ret  :  NA
    def verify_vehcile_cipher(hex_vehinfo_cipher, hex_rand)
        hex_veh_plaint = decrypt_veh_info(hex_vehinfo_cipher)
        veh_len = hex_veh_plaint[0..1].to_i(16) - 8
        veh_info = hex_veh_plaint[18..(18 + veh_len*2 - 1)]
        hex_mac = calc_esam_vehicle_mac(hex_rand, veh_info)
        puts "hex mac: #{hex_mac}"
        assert(hex_mac, hex_veh_plaint[2..17],"车辆MAC信息校验应该一致")
    end


    # desc : 模拟PSAM计算MAC1
    # hexrand      :  CPU卡返回的4字节随机数
    # tradetype    :  交易类型
    # hexpayserial :  CPU卡返回的2字节脱机交易序号
    # imomey       :  消费金额
    # hexocttime   :  OCT 交易时间,7字节， YYYYMMDDHHMMSS
    # hexkeyversion ： 秘钥版本， 真实PSAM用来确定主交易秘钥，软算法用不到
    # hexalgorithm  ： 算法标识， 真实PSAM用来确定主交易秘钥，软算法用不到
    # hexcardid     :  CPU卡序列号，  分散因子
    # hexissueid    :  发行省份代码， 分散因子
    def mix_purchase_mac1(hexrand, tradetype, hexpayserial, imoney, hexocttime, hexkeyversion, hexalgorithm, hexcardid, hexissureid)
        dpk =  @BMPK
        if (@div_times == 2)
            mpk = utils.des_diversify(hexissureid, @BMPK)
            puts "MPK is : #{mpk}"
            dpk = utils.des_diversify(hexcardid, mpk)
            puts "DPK is : #{dpk}"
        elsif (@div_times == 1)
            dpk = utils.des_diversify(hexcardid, @BMPK)
        end

        psam_trade_serial_2bytes =  @psam_trade_sn[4..7]
        session_key = utils.single_des_diversify(hexrand + hexpayserial + psam_trade_serial_2bytes,  dpk )

        session_key = session_key[0..15]
        puts "Session Key is : #{session_key}"
        mac_origin = imoney + tradetype + @psam_term_id + hexocttime
        puts "mac origin  : #{mac_origin}"
        # init_vector, all zero.
        out = utils.mac_calculate("0000000000000000",  mac_origin, session_key )

        puts "MAC1 out is : #{out}"

        mac2_hex =  utils.mac_calculate("0000000000000000", imoney,  session_key )

        puts "MAC2 out is : #{mac2_hex}"
        @mac2 = mac2_hex

        return out

    end




    # desc : 模拟PSAM计算MAC2
    def calc_mac2(hexrand, tradetype, hexpayserial, imoney, hexocttime, hexkeyversion, hexalgorithm, hexcardid,
               hexissureid)
        dpk =  @BMPK
        if (@div_times == 2)
            mpk = utils.des_diversify(hexissureid, @BMPK)
            puts "MPK is : #{mpk}"
            dpk = utils.des_diversify(hexcardid, mpk)
            puts "DPK is : #{dpk}"
        elsif (@div_times == 1)
            dpk = utils.des_diversify(hexcardid, @BMPK)
        end
        puts "DPK is : #{dpk}"
        term_id = "000000000184"
        psam_trade_serial_2bytes = @psam_trade_sn[4..7]
        session_key = utils.single_des_diversify(hexrand + hexpayserial + psam_trade_serial_2bytes,  dpk )

        session_key = session_key[0..15]
        # init vector is all zero.(8 bytes)
        mac2_hex =  utils.mac_calculate("0000000000000000", imoney,  session_key )
        puts "MAC2 out is : #{mac2_hex}"
        @mac2 = max2_hex

        return @mac2

    end

    def get_mac2()

        return @mac2
    end

    def get_term_id()
        return @psam_term_id
    end

    def get_trade_sn()
        return @psam_trade_sn
    end



    # SM4 过程秘钥计算
    #1 In || ~In,  输入（8字节）取反， 并按照 In || ~In 串在一起
    #2 将DPK 作为加密秘钥
    #3 用DPK 对 In || ~In 进行加密， 结果作为过程秘钥

    def calc_sm4_sesskey(hexindata, hexdkey)
        binhexdata = hex2bin(hexindata)
        revsdata = []
        for i in 0..7
            revsdata[i] = binhexdata[i] ^ 0xFF   # 取反等于异或0xFF
        end
        hexresdata = bin2hex(revsdata)
        allindata = hexindata + hexresdata
        # 1 for 加密， 0 for 解密
        sesskey = SM4.sm4_ecb_enc_dec(1, hexdkey, allindata)
        return sesskey
    end



    #计算圈存MAC1
    # para hexissureid : 发行商代码
    # para hexcardid   : IC卡 ID
    # para hexrand     : IC 卡随机数
    # para hexpayserial : IC 卡交易序列号
    # para restmoney:  IC卡余额     4字节
    # para hexmoney:  交易金额     4字节
    # para tradetype: 交易类型     1字节    圈存 "02"
    # para terminalid:  终端机编号 6字节
    # para tradedatetime:  交易日期和交易时间   7字节
    def calc_load_mac1(hexissureid, hexcardid, hexrand , hexpayserial, restmoney, hexmoney, tradetype, terminalid )
        # derived load key. 分散的圈存子秘钥
        dlk =  @LOAD_KEY
        if (@div_times == 2)
            mlk = utils.des_diversify(hexissureid, @LOAD_KEY)
            puts "MPK is : #{mpk}"
            dlk = utils.des_diversify(hexcardid, mpk)
            puts "DPK is : #{dpk}"
        elsif (@div_times == 1)
            dlk = utils.des_diversify(hexcardid, @LOAD_KEY)
        end
        puts "DPK is : #{dlk}"

        #session_key = utils.single_des_diversify(hexrand + hexpayserial + "8000",  dpk )
        session_key = calc_sm4_sesskey(hexrand + hexpayserial + "8000",  dlk )

        session_key = session_key[0..32]
        puts "session key is #{session_key}"
        load_mac1_data = restmoney + hexmoney + tradetype + terminalid
        # init vector is all zero.(8 bytes)
        mac1_hex =  SM4.sm4_mac(session_key, load_mac1_data, "0000000000000000" * 2)
        puts "MAC1 out is : #{mac1_hex}"
        @load_mac1 = mac1_hex

        return @load_mac1

    end






    #计算圈存MAC2
    # para hexissureid : 发行商代码
    # para hexcardid   : IC卡 ID
    # para hexrand     : IC 卡随机数
    # para hexpayserial : IC 卡交易序列号
    # para hexmoney: 交易金额      4字节
    # para tradetype: 交易类型     1字节    圈存 "02"
    # para terminalid:  终端机编号 6字节
    # para tradedatetime:  交易日期和交易时间   7字节
    def calc_load_mac2(hexissureid, hexcardid, hexrand , hexpayserial, hexmoney, tradetype, terminalid, tradedatetime )
        # derived load key. 分散的圈存子秘钥
        dlk =  @LOAD_KEY
        if (@div_times == 2)
            mlk = utils.des_diversify(hexissureid,  @LOAD_KEY)
            puts "MPK is : #{mpk}"
            dlk = utils.des_diversify(hexcardid, mpk)
            puts "DPK is : #{dpk}"
        elsif (@div_times == 1)
            dlk = utils.des_diversify(hexcardid,  @LOAD_KEY)
        end
        puts "DPK is : #{dlk}"

        #session_key = utils.single_des_diversify(hexrand + hexpayserial + "8000",  dpk )
        session_key = calc_sm4_sesskey(hexrand + hexpayserial + "8000",  dlk )

        session_key = session_key[0..32]
        puts "session key is #{session_key}"
        load_mac2_data = hexmoney + tradetype + terminalid + tradedatetime
        # init vector is all zero.(8 bytes)
        mac2_hex =  SM4.sm4_mac(session_key, load_mac2_data, "0000000000000000" * 2)
        puts "MAC2 out is : #{mac2_hex}"
        @load_mac2 = mac2_hex

        return @load_mac2

    end


end



class AllZeroSwPsam < SwPsam



    def initialize()
        super("", "", 0)
        @mac2    = ''
        puts "derived obu key is #{@obu_key}"
        puts "in all zero psam , veh key: #{@VEH_INFO_ENCRYPT_KEY}"
    end

    def init_keys()
        @ALL_ZERO_KEY         = "00000000000000000000000000000000"
        @VEH_INFO_ENCRYPT_KEY = @ALL_ZERO_KEY
        @BMPK                 = @ALL_ZERO_KEY
        @LOAD_KEY             = @ALL_ZERO_KEY
    end

end










################################
#Testing Data
################################

#车辆信息明文
VEH_INFO    = "D4C141323534333600000000000101020177120D040200110001904141410000000000000000000000000042424200000000000000000000000000"
#ESAM序列号
SERIAL_NUM  = "1122334455667788"
#发行省份编码
REGION_CODE = "BDF0D2E7BDF0D2E7"
#车辆信息密文 包含 长度 + MAC + 车辆信息明文 + 填充
VEH_INFO_CIPHER = "1E228C3AD145862E21368963A72E9A73F955FB289798A6E2166DDF81CD6543534AC865B6FCC293AD8B79FC99D6BA07F3688518B46E1D24818B79FC99D6BA07F356A7DF73FDF68153"
#车辆信息明文 包含 长度 + MAC + 车辆信息明文 + 填充
VEH_INFO_PLAINT = "43288C47B50805FF02D4C141323534333600000000000101020177120D04020011000190414141000000000000000000000000004242420000000000000000000000000080000000"
#RSU 随机数用于计算交通部MAC
RSU_RAND = "40EB7DADB87F5E0E"









=begin





sw_esam = SwPsam.new(VEH_INFO, REGION_CODE, SERIAL_NUM)
sw_esam.decrypt_veh_info(VEH_INFO_CIPHER)
sw_esam.calc_esam_vehicle_mac(RSU_RAND, VEH_INFO )

sw_esam.calc_esam_vehicle_mac("DB46D54625901243", "D4C141313233343500000000C0B600020E74120D040200110001904141410000000000000000000000000042424200000000000000000000000000" )

sw_esam.verify_vehcile_cipher("C9AF52860367D5D2DD8DE948B349919356172FEA35E0BB722F94EA3D507719394AC865B6FCC293AD8B79FC99D6BA07F3688518B46E1D24818B79FC99D6BA07F356A7DF73FDF68153", "DB46D54625901243")



hexrand       = "0AC4CB69"  # CPU card return rand
tradetype     = "09"        # Trade Type
hexpayserial  = "AB31"      # CPU卡脱机交易序列号
imoney        = "00000001"  # 消费金额
hexocttime    = "20180122095312"  # 交易时间
hexkeyversion = "01"        # key type
hexalgorithm  = "00"        # alg version  00 for 3des , 40 for SM4
hexcardid     = "0000000000000142"  # cpu card sequence num
hexissureid   = "BDF0D2E7BDF0D2E7"  # vendor code.

sw_esam.mix_purchase_mac1(hexrand, tradetype, hexpayserial, imoney, hexocttime, hexkeyversion, hexalgorithm, hexcardid, hexissureid)
=end

=begin
sw_esam = SwPsam.new( REGION_CODE, SERIAL_NUM)
sw_esam.decrypt_veh_info(VEH_INFO_CIPHER)
sw_esam.calc_esam_vehicle_mac(RSU_RAND, VEH_INFO )


zero_psam = AllZeroSwPsam.new
zero_psam.decrypt_veh_info(VEH_INFO_CIPHER)
zero_psam.calc_esam_vehicle_mac(RSU_RAND, VEH_INFO )

=end


zero_psam = AllZeroSwPsam.new
