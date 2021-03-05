# -*- coding: UTF-8 -*-
# coss.rb
# 作者：王政
# 描述：提供COS命令的制作工具，只制作命令，执行应该去调用具体的设备接口
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

#require 'ucore'

class Coss

    #取随机数, 比如：get_rand(8)
    def get_rand(count)
        return '00840000'+sprintf('%.02X', count)
    end

    #进入目录， 比如: entry_dir("3F00") or entry_dir("DF01")
    def entry_dir(dir)
        '00A4000002'+dir
    end

    alias select_file entry_dir

    #外部认证
    def auth_ext(hexencdata, hexkeyid='00')
        '008200'+hexkeyid+'08'+hexencdata[0..15]
    end

    #PSAM DES, MAC 初始化
    def psam_des_init(hexkeyid, hexdata)
        len = hexdata.length / 2
        sprintf("801A%s%.02X%s", hexkeyid, len, hexdata)
    end

    #PSAM DES 运算
    def psam_des_cala(hexdata)
        len = hexdata.length / 2
        sprintf("80FA8000%.02X%s", len, hexdata)
    end

    #PSAM MAC 运算
    def psam_mac_cala(hexrand, hexdata)
        str  = (hexrand + hexdata)
        len = str.length / 2
        sprintf("80FA0800%.02X%s", len, str)
    end

    #用户卡， 复合消费初始化
    def mix_purchase_init(imoney, hexpsamno, ikeyid = 1)
        sprintf("805003020B%.02X%.08X%s", ikeyid, imoney, hexpsamno)
    end

    #PSAM，复合消费计算MAC1
    def mix_purchase_mac1(hexrand, hexpayserial, imoney, hexocttime, hexkeyversion, hexalgorithm, hexcardid, hexissureid)
        hextradetype = "09"
        hexmoney = sprintf("%.08X", imoney)
        data = [hexrand, hexpayserial, hexmoney, hextradetype, hexocttime, hexkeyversion, hexalgorithm, hexcardid, hexissureid]
        hexdata = data.join("")
        sprintf("80700000%.02X%s", hexdata.length / 2, hexdata)
    end

    #用户卡， 复合消费
    def mix_purchase(hexpayserial, hexocttime, hexmac1)
        s = sprintf("805401000F%s%s%s", hexpayserial, hexocttime, hexmac1)
    end

    #PSAM，复合消费验证MAC2
    def mix_purchase_mac2(hexmac2)
        sprintf("80720000%.02X%s", hexmac2.length / 2, hexmac2)
    end

    #用户卡，复合消费更新应用，即0019文件
    def mix_purchase_update(hexdata)
        sprintf("80DCAAC8%.02X%s", hexdata.length / 2, hexdata)
    end

    #读二进制文件，普通方式读取
    #fid为0015文件时，可以写"15"或"0015", 为16进制字符串
    #offset, length，是整数类型
    def read_binfile(hexfid, offset, length)
        a = hex2bin(hexfid)
        return "" if a.size == 0
        f = a.size == 1 ? a[0].to_i : a[1].to_i
        f = 0x80 | (f & 0x1F)
        sprintf("00B0%.02X%.02X%.02X", f, offset, length)
    end

    #写二进制文件
    #fid为0015文件时，可以写"15"或"0015", 为16进制字符串
    #offset, 是整数类型, hexdata是要写入的内容, hexmac是线路保护写方式时的mac码，要先通过psam计算
    #1: 写EF01:
    #   要先select_file(EF01)，再write_binfile("00", 0, "AABB")
    #2: 写0015,
    #   只需要wirte_binfile("0015", 0, "AABB")
    def write_binfile(hexfid, offset, hexdata, hexmac = nil)
        a = hex2bin(hexfid)
        return "" if a.size == 0
        f = a.size == 1 ? a[0].to_i : a[1].to_i
        f = 0x80 | (f & 0x1F) if f > 0  #f==0表示第一种方法
        if hexmac
            alldata = hexdata + hexmac
            sprintf("04D6%.02X%.02X%.02X%s", f, offset, alldata.length / 2, alldata)
        else
            sprintf("00D6%.02X%.02X%.02X%s", f, offset, hexdata.length / 2, hexdata)
        end
    end

    #读钱包文件，余额
    def read_balance
        "805C000204"
    end

    #读取记录文件，
    #fid为0019文件时，可以写"19"或"0019", 为16进制字符串
    #默认是读取第一条记录，并且是该记录的全部字节数
    def read_record(hexfid, recno = 1)
        a = hex2bin(hexfid)
        return "" if a.size == 0
        f = a.size == 1 ? a[0].to_i : a[1].to_i
        f = ((f & 0x1F) * 8) | 0x04
        sprintf("00B2%.02X%.02X00", recno, f)
    end

    #写记录文件，
    #默认是写第一条记录，并且是该记录的全部字节数
    #不知道为什么不用写文件标识？难道一个目录只有一个记录文件，默然就当前目录下的记录文件？
    def write_record(hexdata, recno = 1)
        sprintf("00DC%.02X%.02X%.02X%s", recno, "04", hexdata.length / 2, hexdata)
    end

    #国标交易用到的基本上就是以上这些函数，其他如果想要的话，可以自己写。我以后也会不定时地增加
    #可以在你自己的TestSuit.rb里面写 class Coss
    #根据 sw12 错误代码 --> 汉字字符串
    def errstr(hexcode)
        hexcode = hexcode.upcase
        retstr = ''
        case hexcode
            when '9000'
                retstr =  '正常 成功执行'
            when '6200'
                retstr =  '警告 信息未提供'
            when '6281'
                retstr =  '警告 回送数据可能出错'
            when '6282'
                retstr =  '警告 文件长度小于Le'
            when '6283'
                retstr =  '警告 选中的文件无效'
            when '6284'
                retstr =  '警告 FCI格式与P2指定的不符'
            when '6300'
                retstr =  '警告 鉴别失败'
            when '6400'
                retstr =  '出错 状态标志位没有变'
            when '6581'
                retstr =  '出错 内存失败'
            when '6700'
                retstr =  '出错 长度错误'
            when '6882'
                retstr =  '出错 不支持安全报文'
            when '6981'
                retstr =  '出错 命令与文件结构不相容，当前文件非所需文件'
            when '6982'
                retstr =  '出错 操作条件（AC）不满足，没有校验PIN'
            when '6983'
                retstr =  '出错 认证方法锁定，PIN被锁定'
            when '6984'
                retstr =  '出错 随机数无效，引用的数据无效'
            when '6985'
                retstr =  '出错 使用条件不满足'
            when '6986'
                retstr =  '出错 不满足命令执行条件（不允许的命令，INS有错）'
            when '6987'
                retstr =  '出错 MAC丢失'
            when '6988'
                retstr =  '出错 MAC不正确'
            when '698D'
                retstr =  '保留'
            when '6A80'
                retstr =  '出错 数据域参数不正确'
            when '6A81'
                retstr =  '出错 功能不支持；创建不允许；目录无效；应用锁定'
            when '6A82'
                retstr =  '出错 该文件未找到'
            when '6A83'
                retstr =  '出错 该记录未找到'
            when '6A84'
                retstr =  '出错 文件预留空间不足'
            when '6A86'
                retstr =  '出错 P1或P2不正确'
            when '6A88'
                retstr =  '出错 引用数据未找到'
            when '6B00'
                retstr =  '出错 参数错误'
            when '6E00'
                retstr =  '出错 不支持的类：CLA有错'
            when '6F00'
                retstr =  '出错 数据无效'
            when '6D00'
                retstr =  '出错 不支持的指令代码'
            when '9301'
                retstr =  '出错 资金不足'
            when '9302'
                retstr =  '出错 MAC无效'
            when '9303'
                retstr =  '出错 应用被永久锁定'
            when '9401'
                retstr =  '出错 交易金额不足'
            when '9402'
                retstr =  '出错 交易计数器达到最大值'
            when '9403'
                retstr =  '出错 密钥索引不支持'
            when '9406'
                retstr =  '出错 所需MAC不可用'
            when '6900'
                retstr =  '出错 不能处理'
            when '6901'
                retstr =  '出错 命令不接受（无效状态）'
            when '6600'
                retstr =  '出错 接收通讯超时'
            when '6601'
                retstr =  '出错 接收字符奇偶错'
            when '6602'
                retstr =  '出错 校验和不对'
            when '6603'
                retstr =  '警告 当前DF文件无FCI'
            when '6604'
                retstr =  '警告 当前DF下无SF或KF'
            else
                if code[0..2] == '63C'
                    x = code[3..3]
                    retstr =  "警告 校验失败（#{x}－允许重试次数）"
                elsif code[0..1] == '61'
                    retstr =  '正常 需发GET RESPONSE命令'
                elsif code[0..1] == '6C'
                    xx = code[2..3]
                    retstr =  '出错 Le长度错误，实际长度是#{xx}'
                else
                    retstr =  '未知错误代码'
                end
        end
        return hexcode + ': ' + retstr
    end
end


def coss
    @Coss ||= Coss.new
end
