# -*- coding: UTF-8 -*-
# utils.rb
# 作者：王政
# 描述：本单元定义了一些实用工具函数，有些是直接调用了utils.dll，的有些用ruby实现更方便的，就直接用ruby实现。
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

require "fiddle"

def adddllpath
    return unless @addbinfile.nil?
    @addbinfile = 1
    binpath = File.dirname(__FILE__)
    pos = binpath.rindex("/")
    binpath=binpath[0..pos-1]+"/bin"
    binpath.gsub!("/", "\\")
    syspath = ENV["Path"]
    ENV["Path"] = syspath + ";"+binpath unless syspath.include?(binpath)
end

#adddllpath

# module SM4Api
#     extend Fiddle::Importer
#     dlload 'utest.dll'
#
#     # 用于CPC卡测试，用8字节CARID，分散出16字节密钥，再用16字节密钥加密16字节随机数
#     # extern void __stdcall sm4_init_by_card_id(unsigned char card_id[8],unsigned char output[16]);
#     # extern void __stdcall encrypt_data_sm4(unsigned char *out_key_dat, unsigned char *rand_dat, unsigned char *out_dat);
#
#     extern 'void sm4_init_by_card_id(unsigned char*,unsigned char*)'
#     extern 'void encrypt_data_sm4(unsigned char*, unsigned char*, unsigned char*)'
# end

#由于JSON 和C++Builder的vcl有冲突，所以要改一下写法，并且，以后用到selenium的地方，就不能用utest.dll里面的功能
class SM4
    class SM4Api
        attr_accessor :sm4_init_by_card_id
        attr_accessor :encrypt_data_sm4
        attr_accessor :sm4_init_by_card_id_with_rootkey
        attr_accessor :sm4_mac
        attr_accessor :sm4_ecb_enc_dec



        # 用于CPC卡测试，用8字节CARID，分散出16字节密钥，再用16字节密钥加密16字节随机数
        # extern void __stdcall sm4_init_by_card_id(unsigned char card_id[8],unsigned char output[16]);
        # extern void __stdcall encrypt_data_sm4(unsigned char *out_key_dat, unsigned char *rand_dat, unsigned char *out_dat);
        def initialize
            #libutils = Fiddle.dlopen('utest.dll')
            libutils = Fiddle.dlopen('./libutest.so')
            @sm4_init_by_card_id = Fiddle::Function.new(libutils['sm4_init_by_card_id'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP],                     Fiddle::TYPE_VOID)
            @encrypt_data_sm4    = Fiddle::Function.new(libutils['encrypt_data_sm4'],   [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
            @sm4_init_by_card_id_with_rootkey = Fiddle::Function.new(libutils['sm4_init_by_card_id_with_rootkey'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
            @sm4_mac = Fiddle::Function.new(libutils['SM4_MAC'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
            @sm4_ecb_enc_dec = Fiddle::Function.new(libutils['SM4_ECB_EncDec'],[Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)


        end

        def self.inst
            @sm4api ||= SM4Api.new
        end
    end
    def self.sm4_init_by_card_id(hexcardid)
        id = hex2bin(hexcardid)
        key = 'a' * 16
        SM4Api.inst.sm4_init_by_card_id.call(bytes2str(id), id.size, key)
        return bin2hex(key.bytes)
    end

    def self.encrypt_data_sm4(hexkey, hexrand)
        key = hex2bin(hexkey)
        rand = hex2bin(hexrand)
        out = 'a' * 16
        SM4Api.inst.encrypt_data_sm4.call(bytes2str(key), bytes2str(rand), out)
        return bin2hex(out.bytes)
    end

    def self.sm4_init_by_card_id_with_rootkey(hexcardid, root_key)
        id = hex2bin(hexcardid)
        rootkey = hex2bin(root_key)
        key = 'a' * 16
        SM4Api.inst.sm4_init_by_card_id_with_rootkey.call(bytes2str(id), id.size(), bytes2str(rootkey), rootkey.size(), key)
        return bin2hex(key.bytes)
    end

    def self.sm4_mac(hex_key, hex_in_data, hex_init_vec = '0' * 32)
        key = hex2bin(hex_key)
        in_data = hex2bin(hex_in_data)
        init_vec = hex2bin(hex_init_vec)
        out_data = 'a' * 4
        SM4Api.inst.sm4_mac.call(bytes2str(key), bytes2str(in_data), in_data.size(), bytes2str(init_vec), out_data)
        return bin2hex(out_data.bytes)
    end


    def self.sm4_ecb_enc_dec(mode, hex_key, hex_in_data)
        key = hex2bin(hex_key)
        in_data = hex2bin(hex_in_data)
        out_data = 'a' * in_data.size()
        SM4Api.inst.sm4_ecb_enc_dec.call(mode, bytes2str(in_data), out_data , in_data.size(),  bytes2str(key))
        return bin2hex(out_data.bytes)
    end


end

class Utils
    def initialize
        #libutils       = Fiddle.dlopen('utest.dll')
        libutils       = Fiddle.dlopen('./libutest.so')
        #@get_utick     = Fiddle::Function.new(libutils['get_utick'],     [], Fiddle::TYPE_LONG_LONG)
        @des_encrypt   = Fiddle::Function.new(libutils['des_encrypt'],   [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
        @des_decrypt   = Fiddle::Function.new(libutils['des_decrypt'],   [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
        @mac_calculate = Fiddle::Function.new(libutils['mac_calculate'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
        @des_diversify = Fiddle::Function.new(libutils['des_diversify'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)

        @single_des_diversify = Fiddle::Function.new(libutils['single_des_diversify'], [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
 #@messagebox    = Fiddle::Function.new(libutils['messagebox'],    [Fiddle::TYPE_INT,   Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        #@question      = Fiddle::Function.new(libutils['question'],      [Fiddle::TYPE_INT,   Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
        #@information   = Fiddle::Function.new(libutils['information'],   [Fiddle::TYPE_INT,   Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID)
        #@inputbox      = Fiddle::Function.new(libutils['inputbox'],      [Fiddle::TYPE_INT,   Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP)
        #@gettimestr    = Fiddle::Function.new(libutils['gettimestr'],    [Fiddle::TYPE_INT],  Fiddle::TYPE_VOIDP)
        #@formattimestr = Fiddle::Function.new(libutils['formattimestr'], [Fiddle::TYPE_DOUBLE,Fiddle::TYPE_INT], Fiddle::TYPE_VOIDP)
        #@datetime_now  = Fiddle::Function.new(libutils['datetime_now'],  [], Fiddle::TYPE_DOUBLE)
        #@formatdatetime = Fiddle::Function.new(libutils['formatdatetime'],[Fiddle::TYPE_DOUBLE,Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOIDP)
    end

    def apphandle
        @apphandle ||= 0
        return @apphandle if @apphandle > 0
        ARGV.each{|p|
            if p.index("hwnd=") == 0
                s = p.split("=")[1]
                @apphandle = s.to_i
            end
        }
        return @apphandle
    end

    #取计算时间，单位us
    def get_utick
        @get_utick.call
    end

    #延时m个毫秒，这是阻塞的，会消耗CPU，跟sleep不一样，sleep不会消耗CPU
    #但是比较准确
    def delay_ms(m)
        t1 = get_utick
        while get_utick - t1 < m * 1000 do
            ;
        end
    end

    #des加密, 参数都是16进制字符串，参数名已经给出意义，这里不解释了。
    def des_encrypt(hexdata, hexkey)
        hexout = ' '* hexdata.length #避免缓冲不够长
        while hexout.length % 16 > 0 do hexout = hexout + "0" end
        @des_encrypt.call(hexdata, hexkey, hexout)
        return hexout
    end

    #des解密，参数都是16进制字符串，参数名已经给出意义，这里不解释了。
    def des_decrypt(hexdata, hexkey)
        hexout = ' '* hexdata.length #避免缓冲不够长
        while hexout.length % 16 > 0 do hexout = hexout + "0" end
        @des_decrypt.call(hexdata, hexkey, hexout)
        return hexout
    end

    #计算MAC码, 参数都是16进制字符串，参数名已经给出意义，这里不解释了。
    def mac_calculate(hexinit, hexdata, hexkey)
        hexout = '00000000'  #避免缓冲不够长
        @mac_calculate.call(hexinit, hexdata, hexkey, hexout)
        return hexout
    end

    #密钥分散,用分散因子did对key进行分散, 参数都是16进制字符串，参数名已经给出意义，这里不解释了。
    def des_diversify(hexdid, hexkey)
        hexout =' '* hexkey.length #避免缓冲不够长
        while hexout.length % 16 > 0 do hexout = hexout + "0" end
        @des_diversify.call(hexdid, hexkey, hexout)
        return hexout
    end

    #单次密钥分散,用于交易的会话密钥计算， 会话密钥是单密钥长度8字节.
    #用分散因子did对key进行分散, 参数都是16进制字符串，参数名已经给出意义，这里不解释了。
    def single_des_diversify(hexdid, hexkey)
        hexout =' '* hexkey.length #避免缓冲不够长
        while hexout.length % 16 > 0 do hexout = hexout + "0" end
        @single_des_diversify.call(hexdid, hexkey, hexout)
        return hexout
    end

    def messagebox(title, text, flag)
        @messagebox.call(apphandle, text, title, flag)
    end

    #在平台界面上弹出对话框询问是和否，当按YES按钮时，返回true，否则返回false
    #其中，title是对话框的标题，text，是要显示的内容。
    def question(title, text)
        r = @question.call(apphandle, text, title)
        return r == 1
    end

    #在平台界面上弹出对话框按下按钮后返回
    #其中，title是对话框的标题，text，是要显示的内容。
    def information(title, text)
        @information.call(apphandle, text, title)
    end

    #在平台界面上弹出对话框,要求输入一段字符串
    #其中，title是对话框的标题，text，是输入框前面的提示。
    def inputbox(title, text)
        res = @inputbox.call(apphandle, text, title)
        return res
    end

    #取当前时间字符串
    def gettimestr(longstr = 1)
        res = @gettimestr.call(longstr)
        return res.to_s
    end

    #格式化时间字符串
    def formattimestr(datetime, longstr = 1)
        res = @formattimestr.call(datetime, longstr)
        return res.to_s
    end

    def datetime_now
        return @datetime_now.call
    end

    def formatdatetime(time, format)
        return @formatdatetime.call(time, format).to_s
    end

    #获取unix时间，返回一个4字节的数组
    #在发BST时设置RUS参数，可以直接用这4字节数组
    def get_unix_time
        hex2bin(sprintf("%.08X", Time.now.to_i))
    end

    #获取unix时间，返回一个4字节的数组
    #在发BST时设置RUS参数，可以直接用这4字节数组
    def get_unix_time_hex
        sprintf("%.08X", Time.now.to_i)
    end

    #对一个数组进行快速排序，数组里面的元素类型要一致
    def qsort(list)
        return [] if list.empty?
        x, *xs = list
        small, big = xs.partition{|i| i < x}
        qsort(small) + [x] + qsort(big)
    end

    #用于计算mac时，按计算要求调整输入数据，先在80，再加00，直到8的倍数
    #这只是帮你补齐数据，没有帮你加密哦，自己加密
    def make_macinput(hexdata)
        hexdata = hexdata + '80'
        while(hexdata.length % 16 > 0)  #因为是10进制值符传，所以这里去16的模
            hexdata = hexdata + "00";
        end
        return hexdata;
    end


    #用于计算DES数据加密时，按计算要求，先在前面加长度，再加80, 在加00，直到8的倍数
    #这只是帮你补齐数据，没有帮你加密哦，自己加密
    def make_datinput(hexdata)
        bin = [hexdata.length/2]      #按这个说法，数据长度不能大于254
        hexdata = bin2hex(bin) + hexdata
        hexdata = hexdata + '80' if hexdata.length % 16 > 0
        while(hexdata.length % 16 > 0)
            hexdata = hexdata + '00'
        end
        return hexdata;
    end

    def ip2bytes(ip)
        return [] if ip.nil? || !ip.is_a?(String) || ip.length == 0
        ns = ip.split('.')
        return [] if ns.size != 4 #ip地址的段数是4
        ns.each { |n| return false if n.to_i >255 || n.to_i < 0 }
        return [] if ns[0].to_i == 0
        ret = []
        ns.each { |n| ret << n.to_i}
        return ret
    end

    def bytes2ip(bytes)
        ret = []
        bytes.each {|b| ret << b.to_s}
        return ret.join('.')
    end
end

#for messagebox's flag
MB_OK                      = 0x00000000
MB_OKCANCEL                = 0x00000001
MB_ABORTRETRYIGNORE        = 0x00000002
MB_YESNOCANCEL             = 0x00000003
MB_YESNO                   = 0x00000004
MB_RETRYCANCEL             = 0x00000005

MB_ICONHAND                = 0x00000010
MB_ICONQUESTION            = 0x00000020
MB_ICONEXCLAMATION         = 0x00000030
MB_ICONASTERISK            = 0x00000040

MB_ICONWARNING             = MB_ICONEXCLAMATION
MB_ICONERROR               = MB_ICONHAND

MB_ICONINFORMATION         = MB_ICONASTERISK
MB_ICONSTOP                = MB_ICONHAND

MB_DEFBUTTON1              = 0x00000000
MB_DEFBUTTON2              = 0x00000100
MB_DEFBUTTON3              = 0x00000200


def utils
    @utils ||= Utils.new
end


#因为Rigol以来于第三方库，所以要这么写，如果用Module没有装NI的库就会出错。
class Rigol
    def initialize
        lib           = Fiddle.dlopen('ViDll.dll')
        @VisaOpen     = Fiddle::Function.new(lib['VisaOpen'],      [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
        @VisaClose    = Fiddle::Function.new(lib['VisaClose'],     [], Fiddle::TYPE_INT)
        @VisaWrite    = Fiddle::Function.new(lib['VisaWrite'],     [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
        @VisaWrite    = Fiddle::Function.new(lib['VisaWrite'],     [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
    end
    def rigol_cmd(cmd)
        @VisaWrite.call(cmd+"\n")
    end

    def rigol_read(res)
        @VisaRead.call(res)
    end

    def connect_dev(hostaddr)
        @VisaOpen.call(hostaddr)
        return  0
    end

    def close_dev
        @VisaClose.call()
    end

    def self.inst
        @rigol ||= Rigol.new
    end
end

def rigol
    Rigol.inst
end


module GladeGUIExt
    def method_missing(method_name, *args, &block)
        mname = method_name.to_s
        if mname.end_with?("=")
            mname.delete!("=")
        end
        return @builder[mname]
    end
end
