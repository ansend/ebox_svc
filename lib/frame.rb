# -*- coding: UTF-8 -*-
# frame.rb
# 作者：王政
# 描述：定义基本帧结构，国标的。其他的可以参考。
# 深圳市金溢科技股份有限公司版权所有, 保留一切权利


require "ostruct"
require File.dirname(__FILE__)+"/utils"
require File.dirname(__FILE__)+"/ucore"

class FreeStruct
    attr_accessor :struct

    def initialize
        @struct = Hash.new
    end

    def method_missing method_name, *args, &block
        mname = method_name.to_s
        if mname.end_with?("=")
            mname.delete!("=")
            @struct[mname.to_sym] = args[0]
        else
            return @struct[mname.to_sym]
        end
    end

    def each_pair(&b)
        @struct.each_pair(&b)
    end
end


class BaseFc
    def initialize
        @fields = FreeStruct.new
    end

    #没有定义的方法，全部转发给 @fields,
    def method_missing(method_name, *args, &block)
        @fields.send(method_name, *args, &block)
    end

    def input(value)
        #空的方法，子类里面实现
    end

    def clear
        #空的方法，子类里面实现
    end

    #别名，set 函数 = input 函数
    #输入字符串用input，输入数字用set，更形象一点，所以定义两个函数
    alias set input

    def <= (value)
        if value.is_a?(Array)
            if value.size == 0
                return
            elsif value.size == 1
                input(value[0])
            else
                send :input, value[0], value[1]
            end
        else
            input(value)
        end
    end

end


class BitField < BaseFc
protected
    def min_len() 1 end
    def max_len() 12 end
public
    def initialize(length, define, defval = 0, chkval = nil)         #chkval 是用户接收输入后，检查是否为固定值
        super()                    #加括号就按括号里的参数传，不加括号，就把三个参数一起往上传。因为上层构造函数没有参数，所以必须这么写
        raise "#{self.class.name} length must in #{min_len}--#{max_len}" unless (length >= min_len and length <= max_len)
        @fields.length = length
        @fields.define = define
        @fields.chkval = chkval
        input(defval)
    end

    def input(value)
        if value.is_a?(Fixnum) || value.is_a?(Bignum)
            @fields.value = value
        elsif value.is_a?(String)
            value = value.gsub(/X| |x/, {"X" => "0", "x" => "0", " " => ""})
            raise "#{self.class.name} set vaue must be bin String" unless isbitstr(value)
            @fields.value = value.to_i(2)
        else
            raise "#{self.class.name} set vaue must be Fixnum or String"
        end
        s = @fields.value.to_s(2)
        while s.length < @fields.length do s = "0" + s end
        @fields.bitstr = s[0..@fields.length-1]
        @fields.value = @fields.bitstr.to_i(2)
        @fields.hexstr = sprintf("%.02X", @fields.value)
    end

    def clear
        @fields.value = 0
    end

    def to_hs
        return @fields.hexstr if (@fields.optfield.nil? || @fields.optfield.value == 1)
        return ""
    end

    def to_bs
        return @fields.bitstr if (@fields.optfield.nil? || @fields.optfield.value == 1)
        return ""
    end

end

class NumField  < BitField
public
    #chkval 是用户接收输入后，检查是否为固定值
    #optfield 是该字段依赖于之前的某个选项值，如果该选项为1，则本字段不输入也不输出
    def initialize(length, define, defval = 0, chkval = nil, optfield = nil)
        raise "#{optfield.class.name} is not BitField!" if !optfield.nil? and !optfield.is_a?(BitField)
        super(length, define, defval, chkval)
        @fields.optfield = optfield
    end

    def input(value)
        return if value.nil?
        if value.is_a?(Fixnum) || value.is_a?(Bignum)
            @fields.value = value
            @fields.bitstr = ""
            if self.is_a?(DatField)
                @fields.hexstr = sprintf("%X", @fields.value)
            else
                @fields.hexstr = sprintf("%.0#{@fields.length*2}X", @fields.value)
                @fields.bitstr = sprintf("%.0#{@fields.length*8}b", @fields.value) if self.is_a?(BitField)
            end
        elsif value.is_a?(String)
            return if value.length == 0

            value = value.gsub(/X| |x/, {"X" => "0", "x" => "0", " " => ""})

            @fields.bitstr = ""
            if self.is_a?(DatField)
                @fields.value = 0
                @fields.hexstr = value
                @fields.length = value.length / 2  #不要设置了，会影响下一次 input
                return
            else
                if ishexstr(value)
                    @fields.value = value.to_i(16)
                    s = @fields.value.to_s(16)
                    len = @fields.length * 2
                    while s.length < len do s = "0" + s end
                    @fields.hexstr = s[0..len-1].upcase
                    @fields.value = @fields.hexstr.to_i(16)
                else
                    raise "#{self.class.name} set value must be bin or hex string"
                end
                @fields.bitstr = sprintf("%.0#{@fields.length*8}b", @fields.value) if self.is_a?(BitField)
            end
        else
            raise "#{self.class.name} set vaue must be Fixnum or String"
        end
    end

    def bitstr
        raise "can not call bitstr in #{self.class.name} "
    end

    def to_bs
        return bitstr if (@fields.optfield.nil? || @fields.optfield.value == 1)
        return ""
    end
end

class VarNumField  < BitField
    def min_len() 0 end
    def max_len() 1024 end
    public
    #chkval 是用户接收输入后，检查是否为固定值
    #optfield 是该字段依赖于之前的某个选项值，如果该选项为1，则本字段不输入也不输出
    #lenfield 是决定本字段长度的, 其他字段的对象, 肯定是在本字段之前的字段
    #opstr    lenfield和本字段长度的对应关系, 如果nil, lenfield的长度就是本字段的长度, 如本字段长度是lenfield字段长度的3倍,
    #         则 opstr="* 3", 如果本字段长度是lenfield字段长度的6倍, 则操作字符(opstr)为 "*6"
    def initialize(length, define, lenfield, opstr=nil, defval = 0, chkval = nil, optfield=nil)
        raise "#{optfield.class.name} is not BitField!" if !optfield.nil? and !optfield.is_a?(BitField)
        raise "lenfield can not be nil, should be a NumField or a BitField!" if lenfield.nil?
        raise "#{lenfield.class.name} is not BitField!" if !lenfield.is_a?(BitField)

        super(length, define, defval, chkval)
        @fields.lenfield = lenfield
        @fields.optfield = optfield
        @fields.opstr    = opstr
    end

    def input(value)

        return if value.nil?
        if value.is_a?(Fixnum) || value.is_a?(Bignum)
            @fields.value = value
            @fields.bitstr = ""
            if self.is_a?(DatField)
                @fields.hexstr = sprintf("%X", @fields.value)
            else
                @fields.hexstr = sprintf("%.0#{@fields.length*2}X", @fields.value)
                @fields.bitstr = sprintf("%.0#{@fields.length*8}b", @fields.value) if self.is_a?(BitField)
            end
        elsif value.is_a?(String)
            return if value.length == 0

            value = value.gsub(/X| |x/, {"X" => "0", "x" => "0", " " => ""})

            @fields.bitstr = ""
            if self.is_a?(DatField)
                @fields.value = 0
                @fields.hexstr = value
                @fields.length = value.length / 2  #不要设置了，会影响下一次 input
                return
            else
                if ishexstr(value)
                    @fields.value = value.to_i(16)
                    s = @fields.value.to_s(16)
                    len = @fields.length * 2
                    while s.length < len do s = "0" + s end
                    @fields.hexstr = s[0..len-1].upcase
                    @fields.value = @fields.hexstr.to_i(16)
                else
                    raise "#{self.class.name} set value must be bin or hex string"
                end
                @fields.bitstr = sprintf("%.0#{@fields.length*8}b", @fields.value) if self.is_a?(BitField)
            end
        else
            raise "#{self.class.name} set value must be Fixnum or String"
        end
    end

    def bitstr
        raise "can not call bitstr in #{self.class.name} "
    end

    def to_bs
        return bitstr if (@fields.optfield.nil? || @fields.optfield.value == 1)
        return ""
    end
end

MAX_DATLEN = 1024


#不确定长度的字段
class DatField < NumField
private
    @saved_maxlen = 0
protected
    def max_len() MAX_DATLEN end
    def min_len() 0 end
public
    def initialize(maxlen, define, optfield = nil)
        raise "#{optfield.class.name} is not BitField!" if !optfield.nil? and !optfield.is_a?(BitField)
        maxlen = max_len() if maxlen > max_len()
        super(maxlen, define)
        @saved_maxlen = maxlen
        @fields.optfield = optfield
        @fields.hexstr = ""
        @fields.bitstr = ""
    end

    def clear
        @fields.value = 0
        @fields.hexstr = ""
        @fields.bitstr = ""
        @fields.length = @saved_maxlen
    end
end

class ApduField < DatField
    def initialize(define, optfield = nil)
        raise "#{optfield.class.name} is not BitField!" if !optfield.nil? and !optfield.is_a?(BitField)
        super(0, define, optfield)
    end

    def input(value, gnext = nil)
        clear
        if gnext.nil?
            super value
        else
            s = hex_get_next(value, 1, gnext)
            len = s.to_i(16)
            cmd = hex_get_next(value, len, gnext)
            raise "输入数据不够了一个帧的所需要的数据长度，可能是设备没有返回: #{self.class.name}::#{self.define}" if cmd.length != len * 2
            super(cmd)
        end
    end

    def hexstr
        sprintf("%.02X%s", @fields.hexstr.length / 2 ,@fields.hexstr)

    end

    alias to_hs hexstr
end

class ApduList < BaseFc
    def initialize(define, optfield = nil)
        raise "#{optfield.class.name} is not BitField!" if !optfield.nil? and !optfield.is_a?(BitField)
        super()
        @fields.optfield = optfield
        @fields.length = 0
        @fields.apdulist = []
        @fields.define = define
    end

    def clear
        @fields.apdulist.clear
        @fields.length = 0
    end

    def input(value, gnext = nil)
        clear
        gnext = {} if gnext.nil?

        s = hex_get_next(value, 1, gnext)
        count = s.to_i(16)
        count.times do |i|
            s = hex_get_next(value, 1, gnext)
            raise "输入数据不够了一个帧的所需要的数据长度，可能是设备没有返回: #{self.class.name}::#{self.define}" if s.length != 2
            len = s.to_i(16)
            cmd = hex_get_next(value, len, gnext)
            raise "输入数据不够了一个帧的所需要的数据长度，可能是设备没有返回: #{self.class.name}::#{self.define}" if cmd.length != len * 2
            add_apdu(cmd)
        end
    end

    def add_apdu(hexcmd)
        if hexcmd.is_a?(String)
            apdu = ApduField.new("apdu")
            apdu <= hexcmd
            @fields.apdulist << apdu
            @fields.length = @fields.length + 1
        elsif hexcmd.is_a?(Array)
            hexcmd.each { |cmd|
                apdu = ApduField.new("apdu")
                apdu <= cmd
                @fields.apdulist << apdu
                @fields.length = @fields.length + 1
            }
        end
    end

    def <<(apduhex)
        add_apdu(apduhex)
    end

    def get_count
        @fields.apdulist.size
    end

    def get_apdu(idx)
        return @fields.apdulist[idx] if @fields.apdulist.size > idx && idx >= 0
        return nil
    end

    def get_apdu_hexstr(idx)
        return  @fields.apdulist[idx].to_hs if @fields.apdulist.size > idx && idx >= 0
        return ""
    end

    def get_apdu_cmdstr(idx)
        ret = get_apdu_hexstr(idx)
        ret = ret[2..ret.length-1] if ret.length > 0
        return ret
    end

    #return [response, sw12]
    def get_apdu_resw(idx)
        return split_resw(get_apdu_cmdstr(idx))
    end

    #return {:resp=>"", :sw12=>""}
    def get_apdu_sw12(idx)
        return split_sw12(get_apdu_cmdstr(idx))
    end

    def hexstr
        ret = sprintf("%.02X", @fields.length)
        @fields.apdulist.each do |field|
            ret = ret + field.hexstr
        end
        return ret
    end
    alias to_hs hexstr
    alias count get_count
end


class Frame < BaseFc
    attr_reader :orgi_input_value

    #提供一个修改字段定义的方法。
    def modify(&b)
        instance_eval(&b) if block_given?
    end

    def input(value, gnext = nil)
        clear
        def set_bitfield(value, bitcount, bitfields, gnext)
            if bitcount > 0
                raise "bitfield's length all together must be dived by 8" unless bitcount % 8 == 0
                scnt = bitcount / 8
                sval = hex_get_next(value, scnt, gnext)
                raise "输入数据不够了一个帧的所需要的数据长度，可能是设备没有返回: #{self.class.name}::#{bitfields[0].define}, 原始数据是: #{value}" if sval.length != scnt * 2
                gnext1 = {}
                bitstr = sprintf("%.0#{bitcount}b", sval.to_i(16))
                bitfields.each do |f|
                    len = f.length
                    s = str_get_next(bitstr, len, gnext1)
                    f <= s
                end
            end
            bitfields.clear
        end

        def field_hex_get_next(field, value, length, gnext)
            s = hex_get_next(value, length, gnext)
            if s.length == length * 2
                field <= s
            else
                raise "输入数据不够了一个帧的所需要的数据长度，可能是设备没有返回: #{self.class.name}::#{field.define}, 原始数据是: #{value}"
            end
        end

        #input start
        @orgi_input_value=value
        value = value.gsub(" ", "")
        if value.is_a?(String) && ishexstr(value)
            gnext = {:start=>0} #下面有个地方引用可能会出错，
            bitfields = []
            bitcount = 0
            allfields = []
            @fields.each_pair do |p|
                allfields << p[1]
            end
            allfields.each_with_index do |field, idx|
                if field.is_a?(ApduField) || field.is_a?(ApduList)
                    set_bitfield(value, bitcount, bitfields, gnext); bitcount = 0

                    if field.optfield.nil? || field.optfield.value == 1
                        field <= [value, gnext]
                    end
                elsif field.is_a?(DatField)
                    set_bitfield(value, bitcount, bitfields, gnext);bitcount = 0

                    if field.optfield.nil? || field.optfield.value == 1
                        if field.length == 0 || field.length == max_dat_len() #不限长度
                            ncount = 0
                            bcount = 0
                            allfields.each_with_index do |f, i|
                                if i > idx
                                    if f.is_a?(NumField)
                                        ncount += f.length
                                    elsif f.is_a?(BitField)
                                        bcount += f.length
                                    else
                                        raise "after DatField, there is a #{f.class.name}!!!, can't determain length."
                                    end
                                end
                            end
                            remaincount = ncount
                            remaincount = remaincount + bcount / 8 if bcount > 0
                            remaincount = remaincount + 1 if (bcount > 0) && (bitcount % 8 > 0)
                            dcount = value.length / 2 - gnext[:start] / 2 - remaincount
                            field_hex_get_next(field, value, dcount, gnext) if dcount > 0
                        else                            #有确定长度
                            field_hex_get_next(field, value, field.length, gnext)
                        end
                    end
                elsif field.is_a?(NumField)
                    set_bitfield(value, bitcount, bitfields, gnext); bitcount = 0

                    if field.optfield.nil? || field.optfield.value == 1
                        field_hex_get_next(field, value, field.length, gnext)
                    end
                elsif field.is_a?(VarNumField)
                    set_bitfield(value, bitcount, bitfields, gnext); bitcount = 0

                    if field.optfield.nil? || field.optfield.value == 1
                        varlen = field.lenfield.value # default len is equal to lenfield value.
                        if(field.opstr) #if opstr is given
                            eval "varlen = #{field.lenfield.value} #{field.opstr}"
                        end
                        field.length = varlen  # here to set the actual length to VarNumFiled.
                        field_hex_get_next(field, value, varlen, gnext)
                    end
                elsif field.is_a?(BitField)
                    bitcount += field.length
                    bitfields << field
                end

            end
        else
            raise "#{self.class.name} input value must be a hex string"
        end

    end

    #用于 接收帧 后，input，然后检查一些有固定值的字段，是否符合要求
    #发送的包，没有必要检查，当然，发送的包，一般也不设检查字段，检查也没用
    def asserts
        @fields.each_pair do |p|
            if (field.is_a?(NumField) || field.is_a?(BitField) )&& !field.chkval.nil?
                s0 = field.value
                if field.chkval.is_a?(Fixnum)
                    s1 = field.chkval
                    assert(s0, s1, "检查值 #{field.define}, 期望值：#{s1} 实际值：#{s0}")
                elsif field.chkval.is_a?(Array)
                    f = true
                    s1 = s0
                    field.chkval.each { |v|
                        if s0 != v
                            s1 = s0
                            f = false
                            break
                        end
                    }
                    assert(s0, s1, "检查值 #{field.define}, 期望值之一：#{s1} 实际值：#{s0}") unless f == true
                end
            end
        end
        send :myasserts if respond_to?(:myasserts)
    end

    #to format printable string
    def to_ps
        ret = "#{self.class.name}:\n"
        c = 0
        @fields.each_pair do |p|
            field = p[1]
            next if field.nil?
            if field.is_a?(NumField) || field.is_a?(ApduList)|| field.is_a?(VarNumField)
                if field.optfield.nil? || field.optfield.value == 1
                    ret = ret + sprintf("  %-28s %s\n", field.define, field.hexstr)
                else
                    ret = ret + sprintf("  %-28s %s\n", field.define, "--")
                end
                c = 0
            else  #only for bitfield
                ret = ret + sprintf("  %-28s %s\n", field.define, " " * c + field.bitstr)
                c += field.length
            end
        end
        return ret
    end

    #to hex string
    def to_hs
        ret = ""
        bstr = ""
        c = 0
        @fields.each_pair do |p|
            field = p[1]
            if field.is_a?(NumField) || field.is_a?(ApduList)|| field.is_a?(VarNumField)
                #如果原来有没有输出的2进制字符串，转换成16进制输出
                if bstr.length > 0
                    t = bstr.to_i(2)
                    c = c / 8
                    s = sprintf("%.0#{c*2}X", t)
                    ret = ret + s
                    bstr = ""
                    c = 0
                end
                ret = ret + field.hexstr if field.optfield.nil? || field.optfield.value == 1
            else #only for bitfield
                bstr = bstr + field.bitstr
                c += field.length
            end
        end
        return ret
    end

    def clear
        @fields.each_pair do |p|
            field = p[1]
            field.clear
        end
    end

    #values 是一个Hash，{:fieldname => vlaue}
    def set_field_values(values)
        @fields.each_pair do |p|
            name = p[0].to_sym
            field = p[1]
            field <= values[name] unless values[name].nil?
        end
    end

    def get_field_values(values = nil)
        ret = {}
        @fields.each_pair do |p|
            name = p[0]
            field = p[1]
            values[name] = field.to_hs unless values.nil?
            ret[name] = field.to_hs
        end
        return ret
    end

    def find_field_by_define(define)
        @fields.each_pair{|p|
            return p[1] if p[1].define == define
        }
        return nil
    end

end

