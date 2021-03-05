# -*- coding: UTF-8 -*-
# ucore.rb
# 作者：王政
# 描述：utest 系统 核心单元
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利

require "fiddle"
require "fiddle/import"

def utest_version
    "1.4.3.0"
end

#################################### 可以使用的API #######################################################################

def get_bcc(bytes)
    bcc = 0
    bytes.each { |b| bcc = bcc ^ b }
    return bcc
end

#用于标准车道CRC校验
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



#用于交通部MAC和车辆信息加密MAC CRC校验
def cal_crc16_mac (bytes)
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
    crc = (crc) & 0xFFFF
    return crc
end

#16进制字符串转化为2进制数据，返回一个数组
#比如 hex2bin("21")，返回[0x21]
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

#2进制数据转化为16进制字符串，返回字符串
#比如 b = [0x25]
#   bin2hex(b)，返回"25"
def bin2hex(binary)
    res = ""
    binary.each{|b| res = res + sprintf("%.02X", b)}
    return res
end

#二进制数组转换为字符串，
#比如：b=[0x31, 0x32, 0x33]
#     bin2str(b) 返回 "123"
def bin2str(binary, stopwith0 = false)
    s = ''
    binary.each{ |a| break if stopwith0 && (a == 0); s = s + a.chr;}
    return s
end

#这个函数跟上一个一样，但是碰到0不结束
def bytes2str(binary)
    s = ''
    binary.each{ |a| s = s + a.chr;}
    return s
end


#二进制转换为字符串，
#比如：s="313233"
#     hex2str(s) 返回 "123"
def hex2str(hexstr)
    bin2str(hex2bin(hexstr))
end

alias h hex2str

#判断一个字符串是否是16进制字符串，每一个字符串都在0--F就可以了，不判断长度(单数还是偶数)
#  ishexstr("ABCDEF") ==> true
#  ishexstr("ABCDEFG") ==> false
def ishexstr(hexstr)
    return false if hexstr.length == 0
    len = hexstr.length
    for i in 0..len-1 do
    	b = hexstr[i]
    	return false if !('0123456789abcdefABCDEF'.include?(b))
    end
    return true
end

def isbitstr(binstr)
    return false if binstr.length == 0
    len = binstr.length
    for i in 0..len-1 do
        b = binstr[i]
        return false if !('01'.include?(b))
    end
    return true
end

# 字符串中间可能有一个字符是 0，
# 主要是在动态库返回字符串时，由于输入缓冲区很大, 返回的字符串里面中间有个0，
# 就用这个函数来截取，返回0前面的字符串
def cstr(str)
    bin2str(str.bytes, true)
end

class String
    def cat(v)
        if self.encoding != v.encoding
            return bin2str(self.bytes + v.bytes, true)
        else
            return self + v
        end
    end

    alias add cat

    #cat hex(str)
    def cathex(hexstr)
        return bin2str(self.bytes + hex2bin(hexstr), true)
    end

    alias adh cathex

    #同cstr
    def to_cs
        bin2str(self.bytes, true)
    end
end



#用于制作拼接的APDU，用于发下到到OBU的IC、ESAM，一次执行多条命令。
#apduhexstr 参数的个数不确定，可以是多条，也可以是一条 16进制字符串指令，
#  比如：执行进入3F00，取随机数。
#  apdulist = add_apdu("00A40000023F00", "0084000004")
#     ==>  apdulist={:apdus=>"0700A40000023F00050084000004", :count=>2, :index=>0, :point=>0}
#       apdus的格式: 长度 + APDU + 长度 + APDU
#     :count=>2 表示 :apdus 包含了两个 apdu
#     用 gb_obu_transfer_channel(apdulist), dev_psam_channel  等函数时，会自动在 加个数，下发时就是：02 0700A40000023F00050084000004
#     如果要用 dev_pure_transfer 纯通道时，如果用到apdulist, 你要自己把 apdulist 转换成 hexcmd，下发
#     转换方法：
#         hexcmd = sprintf("%.02X", apdulist[:count]) + apdulist[:apdus]
#         hexcmd = "........" + hexcmd + ".........." #其他的处理
#         m600t.gb_obu_transfer_channel(0xF2, hexcmd)
def add_apdu(*apduhexstr)
    apdulist = {}
    apduhexstr.each do |apduhex|
        len = apduhex.length
        if(ishexstr(apduhex) && (len > 0) && (len % 2) == 0) then
            bin = [(len / 2)]
            apduhex = bin2hex(bin) + apduhex;
            if apdulist.empty? then
                apdulist[:apdus] = apduhex
                apdulist[:count] = 1
                apdulist[:index] = 0
                apdulist[:point] = 0
            else
                apdulist[:apdus] = apdulist[:apdus] + apduhex
                apdulist[:count] = apdulist[:count] + 1
                apdulist[:index] = 0
                apdulist[:point] = 0
            end
        end
    end
    return apdulist
end

#从apdulist里面一个一个取出APDU，用于在IC卡执行多条命令时，返回多个结果，从结果中解释出一个个结果
#比如 apduret = {:apdus=>"071122334455900006AABBCCD9000", :count=>2, :index=>0, :point=>0}
#    调用一次 get_apdu(apduret)  => "11223344559000"
#  再调用一次 get_apdu(apduret)  => "AABBCCDD9000"
#  再调用一次 get_apdu(apduret)  => ""
def get_apdu(apdulist)
    apduhex = ""
    if(!apdulist.empty? && (apdulist[:count] > 0) && (apdulist[:index] < apdulist[:count])) then
        str = apdulist[:apdus]
        pnt = apdulist[:point]
        len = str[pnt..(pnt + 1)].to_i(16)
        apduhex = str[(pnt + 2)..(pnt + 2 + len * 2 - 1)]
        apdulist[:index] = apdulist[:index] + 1
        apdulist[:point] = pnt + 2 + len * 2
        return apduhex
    end
    return ""
end

#把卡片返回的字符串，分割成response和sw12
#比如：取8字节随机数返回 11223344556677889000
#  split_sw12("11223344556677889000") ==> 返回 {:resp=>"1122334455667788", :sw12=>"9000"}
def split_sw12(hexapdu)
    len = hexapdu.length
    if ishexstr(hexapdu)
        if (len > 4) && (len % 2) == 0
            return {:resp=>hexapdu[0..len - 1 - 4], :sw12=>hexapdu[len - 4..len - 1]}
        elsif (len == 4)
            return {:resp=>"", :sw12=>hexapdu}
        end
    end
    return {}
end

#return [response, sw12]
def split_resw(hexapdu)
    ret = split_sw12(hexapdu)
    return [ret[:resp], ret[:sw12]] unless ret.empty?
    return ["", ""]
end


#从一串16进制字符串里面按顺序取出数据，取数据时，输入是16进制字符串，实际取时按2进制取
#会保存上一次取的位置，下次取时从上一次位置开始取
#比如：
#   ret = "11223344556677889900AABBCCDDEEFF"
#   next={}       #状态变量
#   hex_get_next(ret, 1, next)  #取1个字节，返回"11"
#   hex_get_next(ret, 2, next)  #再取2个字节，返回"2233"
#   hex_get_next(ret, 5, next)  #再取5个字节，返回"4455667788"
#   hex_get_next(ret, 3, next)  #再取5个字节，返回"9900AA"
#   ......
def hex_get_next(hexstr, count, gnext)
    gnext[:end] = 0 if gnext[:end].nil?
    gnext[:start] = 0 if gnext[:start].nil?
    gnext[:end] = gnext[:start] + count * 2 - 1
    return "" if count == 0
    s = hexstr[gnext[:start]..gnext[:end]]
    gnext[:start] = gnext[:end] + 1
    return s
end

def str_get_next(hexstr, count, gnext)
    gnext[:end] = 0 if gnext[:end].nil?
    gnext[:start] = 0 if gnext[:start].nil?
    gnext[:end] = gnext[:start] + count - 1
    return "" if count == 0
    s = hexstr[gnext[:start]..gnext[:end]]
    gnext[:start] = gnext[:end] + 1
    return s
end


#从一串16进制字符串里面取出一段数据，取数据时，输入是16进制字符串，实际取时按2进制取
#比如：
#   ret = "11223344556677889900AABBCCDDEEFF"
#   hex_get_range(ret, 0, 5)  #从0开始取5个字节，返回"1122334455"
#   hex_get_range(ret, 3, 6)  #从0开始取5个字节，返回"445566778899"
def hex_get_range(hexstr, index, count)
    return "" if count == 0
    hexstr[index*2..(index*2+count*2-1)]
end


def uloop(condf = nil)
    def ustart
        @u_while_semaphore_1 ||= KernalAPI.OpenSemaphore(SEMAPHORE_ALL_ACCESS, 0, "u_while_semaphore_1")
        @u_while_semaphore_2 ||= KernalAPI.OpenSemaphore(SEMAPHORE_ALL_ACCESS, 0, "u_while_semaphore_2")
        @u_while_semaphore_3 ||= KernalAPI.OpenSemaphore(SEMAPHORE_ALL_ACCESS, 0, "u_while_semaphore_3")
        KernalAPI.ReleaseSemaphore(@u_while_semaphore_1, 1, 0)
    end
    def uruning?
        r = KernalAPI.WaitForSingleObject(@u_while_semaphore_2, 0)
        return (r != 0)
    end

    ustart
    if block_given?
        begin
            while uruning?
                if condf.is_a?(Proc)
                    @_r_ = condf.call
                elsif !condf.nil?
                    @_r_ = condf
                else
                    @_r_ = true
                end
                break if !@_r_
                yield
            end
        ensure
            KernalAPI.ReleaseSemaphore(@u_while_semaphore_3, 1, 0)
        end
    end
end


class DebugLog

    def self.log(msg)
        if @defug_log_flag
            @logfile = File.open('utest.log', 'a')
            @logfile.puts msg
        end
    end

    def self.set_debug(flag)
        @defug_log_flag = flag
    end

    def self.get_flag
        @defug_log_flag
    end
end

def params_for(meth, obj=nil)
    result = []
    obj.nil? ? params = method(meth).parameters : params = obj.method(meth).parameters
    params.each{ |p| result << [p[0], p[1],  nil] }
    return result if result.empty?

    obj.nil? ? loc = method(meth).source_location : loc = obj.method(meth).source_location
    return [] if loc.nil?
    file = loc[0]
    line = loc[1]

    @src = {} if @src.nil?
    if @src[file].nil?
        @src[file] = []
        f = File.open(file, 'r').each_line{ |l| @src[file] << l}
        f.close
    end

    src = @src[file]

    sline = ''
    for i in line-1..src.length-1
        s = src[i]
        sline = sline + s.gsub("\n", '&rn&').gsub("\\'", '&dy&').gsub('\\"', '&sy&')
        break if s.include?(')') or s.include?(';') or s.include?('end')
    end

    loop{
        ida = sline.index('"')
        idb = sline.index("'")
        break if ida.nil? && idb.nil?
        if (!ida.nil? and idb.nil?) or (!ida.nil? and !idb.nil? and ida < idb)
            nxt = sline.index('"', ida+1)
            break if nxt.nil?
            s1 = sline[0..ida-1]
            s2 = sline[ida..nxt]
            s3 = sline[nxt + 1..sline.length-1]
            s2 = s2.gsub('"', '&sk&').gsub(/ |,/, {' '=>'&sp&', ','=>'&dh&'})
            sline=s1 + s2 + s3
        end
        if (!idb.nil? and ida.nil?) or (!ida.nil? and !idb.nil? and idb < ida)
            nxt = sline.index("'", idb+1)
            break if nxt.nil?
            s1 = sline[0..idb-1]
            s2 = sline[idb..nxt]
            s3 = sline[nxt + 1..sline.length-1]
            s2 = s2.gsub("'", '&dk&').gsub(/ |,/, {' '=>'&sp&', ','=>'&dh&'})
            sline= s1 + s2 + s3
        end
    }

    #squeeze：去掉多余空格
    sps = sline.gsub(/[,;:=(){}]/, ' ').squeeze(' ').split(' ')
    result.each{|p|
        if p[0] == :opt or p[0] == :key
            idx = sps.index(p[1].to_s)
            t = sps[idx+1]
            if t[0..3] == '&dk&'
                nxt = t.index('&dk&', 4)
                break if nxt.nil?
                s = t[4..nxt-1]
                p[2] = s.gsub(/&sk&|&sp&|&dh&|&rn&|&dy&|&sy&/, '&sk&'=>'"', '&sp&'=>' ', '&dh&'=>',', '&rn&'=>"\n", '&dy&'=>"\\'", '&sy&'=>'\\"')
            elsif t[0..3] == '&sk&'
                nxt = t.index('&sk&', 4)
                break if nxt.nil?
                s = t[4..nxt-1]
                p[2] = s.gsub(/&dk&|&sp&|&dh&|&rn&|&dy&|&sy&/, '&dk&'=>"'", '&sp&'=>' ', '&dh&'=>',', '&rn&'=>"\n", '&dy&'=>"\\'", '&sy&'=>'\\"')
            elsif t.include?('.')
                p[2] = t.to_f
            else
                p[2] = t.to_i
            end
        end
    }
    return result
end

def test_abort
    puts '----test_abort called，exit current test mission!!!!!'
    puts '<fin>---test_aborted---</fin>'
    exit
end

def send_rescue(fname, obj=nil)
    begin
        obj.nil? ? send(fname) : obj.send(fname)
    rescue
        expmsg = $!.to_s
        unless expmsg.include?("ASSERT_")
		    str = '<ept>' + $!.to_s + "\n"
		    $@.each{ |line| str = str + 'from ' + line.encode("gb2312") + "\n" }
		    str = str + '</ept>'
		    puts str
        end
        if expmsg == "ASSERT_STOP"
            puts '----assert_stop called，exit current test case!!!!!'
        elsif expmsg == "ASSERT_EXIT"
            puts '----assert_exit called，exit current test suit!!!!!'
            @ast_exit_flag = 1
        elsif expmsg == "ASSERT_ABORT"
            puts '----assert_abort called，exit current test mission!!!!!'
            puts '<fin>---test_aborted---</fin>'
            @ast_exit_flag = 1
        end
    end
end

########################### Test Suits ####################################
#断言期望值和实际值是否相等
#经常出现字符编码不一致的情况，所以要转换一下
def assert(value1, value2 = nil, desc = "assert failed!", atype='==', at=nil, &b)
    r = 0
    if value2.nil? && (value1.is_a?(FalseClass) || value1.is_a?(TrueClass))
        r = 1 if value1
    elsif value1.is_a?(String) && value2.is_a?(String) && value1.encoding.to_s != value2.encoding.to_s
        value1 = value1.encode("gb2312")
        value2 = value2.encode("gb2312")
    end
    eval "r = 1 if value1 #{atype} value2"
    puts "<ast><e>#{value1}</e><v>#{value2}</v><d>#{desc}</d><r>#{r}</r><t>#{atype}</t></ast>"
    has_yield = false
    if r == 0
        at = caller(1)[0] if at.nil?
        p = at.rindex("/")
        at = at[p+1..at.length-1] unless p.nil?
        puts "--assert failed：#{value1} [#{atype}] #{value2}，desc: #{desc}，代码 @" + at.to_s.encode("gb2312")
    end
    if b
        if b.parameters.size == 0
            b.call
        elsif b.parameters.size == 1
            b.call(r == 1)
        end
    end
    return r == 1
end

#断言失败时，结束当前测试用例
def assert_stop(value1, value2 = nil, desc = "assert failed!", atype='==')
    if !assert(value1, value2, desc, atype, caller(1)[0])
        raise 'ASSERT_STOP'
    end
end

#断言失败时，结束当前测试套件
def assert_exit(value1, value2 = nil, desc = "assert failed!", atype='==')
    if !assert(value1, value2, desc, atype, caller(1)[0])
        raise 'ASSERT_EXIT'
    end
end

#断言失败时，结束当前测试，剩下的所有套件所有用例全部停止
def assert_abort(value1, value2 = nil, desc = "assert failed!", atype='==')
    if !assert(value1, value2, desc, atype, caller(1)[0])
        raise 'ASSERT_ABORT'
    end
end

class TestSuit
private
    LOAD_FLAG = '___load___'
    DEBUG_FLAG = '--debug_log'

    def ___slp___  #key method in testsuit
    end

protected
    def initialize
        @isruning = !ARGV.include?(LOAD_FLAG)
        @options = {}
    end

    def set_option(option)
        @options[option.to_s] = true
        return @options
    end

    #return true or false
    def get_option(option)
        ret = false
        if isruning
            #--------1---------------
            #ret = @options[option.to_s]
            #ret = false if ret.nil?
            #--------2---------------
            obytes = option.to_s.bytes
            @options.each{|k,v|
                if obytes == k.bytes
                    ret = true
                    break
                end
            }
            #上面两种方法，第一种不支持中文，所以用第二种
        end
        return ret
    end


    attr_reader :options
    attr_reader :isruning
public
    def self.run
        #防止运行多次
        return unless @run_suit_ctrl.nil?
        @run_suit_ctrl ||= 1
        funcs = {:test => []}
        params = {}
        inst = self.new
        clsname = inst.class.name
        inst.methods.each{ |m|
            break if m == :___slp___
            s = m.to_s
            params[s] = params_for(m, inst) if ARGV.include?(LOAD_FLAG)
            if s[0..4] == 'test_'
                funcs[:test] << s
            elsif m == :suit_desc
                funcs[:desc] = s
            elsif m == :suit_options
                funcs[:opts] = s
            end
        }
        DebugLog.set_debug(ARGV.include?(DEBUG_FLAG))

        if  ARGV.include?(LOAD_FLAG)
            if !funcs[:desc].nil?
                dsc = (inst.send funcs[:desc])
                if dsc.nil?
                    raise "\n#{inst.class.name}.suit_desc 应该返回测试套件的说明文字!'"
                else
                    puts "<dsc>#{clsname}|#{dsc}</dsc>"
                end
            end
            if !funcs[:opts].nil?
                opts = (inst.send funcs[:opts])
                if opts && !opts.empty?
                    str = 'options='
                    opts.each{|k,v| str = str + k.to_s + ';'}
                    str = str[0..str.length-2]
                    puts "<dsc>#{clsname}|#{str}</dsc>"
                end
            end
            funcs[:test].each_with_index{ |fun|
                fname = fun.to_s
                dsc = nil
                idx = -1
                params[fname].each_with_index { |a, i|
                    if (a[1] == :desc) && (a[2].is_a?(String))
                        dsc = a[2]
                        idx = i
                        break
                    end
                }
                if idx != -1
                    puts "<fnm>#{clsname}.#{fname}|#{dsc}</fnm>"
                else
                    raise "\n#{inst.class.name}.#{fname} 函数格式错误，格式应该是: #{fname}(desc='descript for test case')"
                end
            }
            sleep(0.05)
        else
            #get options
            ARGV.each{| arg |
                if arg[0..4] == "-opt=" then
                    t = arg[5..arg.length-1]
                    p = t.index(".")
                    unless p.nil?
                        cls = t[0..p-1]
                        opt = t[p+1..t.length-1]
                        inst.send :set_option, opt if cls == clsname
                    end
                end
            }
            inst.send(:setup) if inst.respond_to?(:setup)
            funcs[:test].each{ |m|
                foo = inst.method(m).name.to_s
                fname = "#{clsname}.#{foo}"
                if ARGV.include?(fname)
                    begin
                        puts "<run>"+fname+"</run>"
                        send_rescue(foo, inst)
                        sleep(0.05)
                    ensure
                        puts "<fin>"+fname+"</fin>"
                    end
                end
                break unless @ast_exit_flag.nil?
            }
            inst.send(:teardown) if inst.respond_to?(:teardown)
        end
    end
end

def assert_equal(value1, value2)
    assert value1, value2, "assert equal", "==", caller(1)[0]
end

def get_class_name(line)
    s = line.strip
    return line.split(" ")[1]
end

def run_selenium(file_name, close_time: 2, navigator: :firefox, params: [])

    file = File.open(file_name, "r")
    source = []
    modify = false
    converted = false
    cls_name = nil
    i = 0
    file.each_line{|line|
        i = i + 1
        if i == 1
            if line.include?("#encoding: ")
                converted = true
            else
                source.unshift "\n"
                source.unshift "#encoding: gb2312\n"
                modify = true
            end
        end
        if (converted == false)
            if line.include?("${receiver}")
                line.gsub!("${receiver}", "@driver")
                modify = true
            elsif line.include?("${receiver}")
                line.gsub!("assert ", "assert_equal true, ")
                modify = true
            end
        end
        if converted
            source << line
        else
            source << line.encode("gb2312", "utf-8")
        end
    }
    file.close

    #如果有修改，则保存，编码保持一致，并且避免编辑器出现红色下波浪先
    if modify
        file = File.open(file_name, "w")
        source.each_with_index{|line, i|
            file.puts line
        }
        file.close
    end
    file.close

    runsrc = source.dup
    runsrc.each_with_index{|line, i|
        if line.include?("< Test::Unit::TestCase")
            line.gsub!("<", "#")
            cls_name = get_class_name(line)
        elsif line.include?("# Test::Unit::TestCase")
            cls_name = get_class_name(line)
        elsif line.include?("Selenium::WebDriver.for :firefox")
            line.gsub!("firefox", navigator.to_s)
        end
        runsrc[i] = line
    }

    eval runsrc.join(" ")

    test_func = nil
    obj = eval "#{cls_name}.new"
    obj.methods.each{|m|
        if m.to_s[0..4] == 'test_'
            test_func = m.to_s
        end
    }
    unless test_func.nil?
        obj.setup
        if params.empty? #没有参数就
            obj.send(test_func)
            sleep close_time
        else
            params.each{|p|
                p.each{|k, v|
                    obj.instance_variable_set(k.to_sym, v)
                }
                obj.send(test_func)
                sleep close_time
            }
        end
        obj.teardown
    end
end

def get_adb_device
    def get_adb_device
        begin
            str = `adb devices`
        rescue

        end
        if str.nil?
            puts "无法运行 adb devices, 获取安卓设备失败。"
            return ""
        end
        ret = ""
        str.split("\n").each_with_index{ |line, i|
            if i == 1
                ret = line.split(" ")[0]
                ret = ret.strip
                break
            end
        }
        return ret
    end
end

def run_appium_android_uirec(file_name, close_time: 2, params: [])
    file = File.open(file_name, "r")
    source = []
    cls_name = nil
    i = 0
    file.each_line{|line|
        source << line
    }
    file.close

    runsrc = source.dup
    runsrc.each_with_index{|line, i|
        if line.include?("class ")
            cls_name = get_class_name(line)
            break
        end
    }

    eval runsrc.join(" ")

    test_func = nil
    obj = eval "#{cls_name}.new"
    obj.methods.each{|m|
        if m.to_s[0..4] == 'test_'
            test_func = m.to_s
        end
    }

    @devicename = get_adb_device

    unless test_func.nil?
        obj.instance_variable_set(:@__device__, @devicename)
        obj.setup
        if params.empty? #没有参数就
            obj.send(test_func)
            sleep close_time
        else
            params.each{|p|
                p.each{|k, v|
                    obj.instance_variable_set(k.to_sym, v)
                }
                obj.send(test_func)
                sleep close_time
            }
        end
        obj.teardown
    end
end
