#encoding: gb2312

#蓝牙盒子自动化测试接口函数, 指针和结构体例子在后面有说明

require "utest"

require "fiddle"
require "fiddle/import"
require "fiddle/struct"
require "fiddle/cparser"
require "cstruct"

# //原始定义
# struct st_frame
# {
#     unsigned char frmdata[MAX_HDLCDATA_LEN]; //256
#     int length;
#     DWORD recv_time;
#     DWORD interval;
#     TColor clfrm;
#     bool uplink;
#     bool crcflg;
#     FRAME_TYPE frmtype;
#     TDateTime recvtm;
# };

ST_Frame = Fiddle::Importer.struct([
    'unsigned char frmdata[256]',
    'int length',
    'int uplink',
    'int frmtype',
    'double recvtime',
])

# module DlaApi
#     extend Fiddle::Importer
#     dlload 'dla.dll'
#
#     extern 'int dla_open(char *, int, int, int, int, int)'
#
#     extern 'int dla_start()'
#     extern 'int dla_stop()'
#     extern 'int dla_clear()'
#
#     extern 'int dla_recv_frame(ST_Frame*, int)'
#     extern 'int dla_save_bsd(char *)'
# end

#由于JSON 和C++Builder的vcl有冲突，所以要改一下写法，并且，以后用到selenium的地方，就不能用dla.dll里面的功能
#如动态库没有用VCL，则用上面这种写法就很方便

STD_GB = 0
STD_WH = 1
STD_GD = 2

CRC_6363 = 0  #0x6363  ITU-V.41
CRC_0000 = 1  #0x0000  BJ, Park
CRC_FFFF = 2  #0xFFFF  GB
CRC_BJ = CRC_0000
CRC_GB = CRC_FFFF

FREQ_5790 = 0
FREQ_5800 = 1
FREQ_5797 = 2
FREQ_5830 = 3
FREQ_5840 = 4
FREQ_5812 = 5

FRAME_UNKNOWN = 0
FRAME_BST = 1
FRAME_VST = 2
FRAME_GSRQ = 3
FRAME_GSRS = 4
FRAME_SSRQ = 5
FRAME_SSRS = 6
FRAME_TCRQ = 7
FRAME_TCRS = 8
FRAME_SETMMIRQ = 9
FRAME_SETMMIRS = 10
FRAME_ERPT = 11
FRAME_FASTRS = 12
FRAME_LINKRQ = 13
FRAME_LINKRS = 14

class DlaFrame
    attr_accessor :frmtype
    attr_accessor :recvtime  #double类型的时间戳
    attr_accessor :uplink
    attr_accessor :hexdata
    attr_accessor :datalen

    def frmtypestr
        case @frmtype
            when FRAME_BST
                return "BST";
            when FRAME_VST
                return "VST";
            when FRAME_GSRQ
                return "GetSecureRequest";
            when FRAME_GSRS
                return "GetSecureResponse";
            when FRAME_SSRQ
                return "FRAME_SSRQ";
            when FRAME_SSRS
                return "FRAME_SSRS";
            when FRAME_TCRQ
                return "TransferChannelRequest";
            when FRAME_TCRS
                return "TransferChannelResponse";
            when FRAME_SETMMIRQ
                return "SetMMIRequest";
            when FRAME_SETMMIRS
                return "SetMMiResponse";
            when FRAME_ERPT
                return "EventReport";
            when FRAME_FASTRS
                return "FastResponse";
            when FRAME_LINKRQ
                return "LinkRequest";
            when FRAME_LINKRS
                return "LinkResponse";
            else
                return "Unknown";
        end
    end

    def recvtimestr
        ret = utils.formattimestr(@recvtime)
        return ret.to_s
    end

    def direction
         @uplink == 1 ? "↑" : "↓"
    end

    def to_ps
        ret = "#{self.class.name}:\n"
        ret = ret + sprintf("  %-28s %s\n", 'recvtime', recvtimestr)
        ret = ret + sprintf("  %-28s %s\n", 'direction', direction)
        ret = ret + sprintf("  %-28s %s\n", 'frmtype', frmtypestr)
        ret = ret + sprintf("  %-28s %s\n", 'datalen', datalen)
        ret = ret + sprintf("  %-28s %s\n", 'hexdata', hexdata)
        return ret
    end

end

#计算两个时间点相差的毫秒数
#比如两个DlaFrame.recvtime 的时间差
#一般时间2 比 时间1 晚
#time1, time2 都是 double型的
def difftime_ms(time1, time2)
    ((time2 - time1) * 24 * 60 * 60 * 1000).to_i
end


class Dla
    def initialize
        libutils = Fiddle.dlopen('dla.dll')
        @dla_open        = Fiddle::Function.new(libutils['dla_open'],      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT],  Fiddle::TYPE_INT)
        @dla_start       = Fiddle::Function.new(libutils['dla_start'],     [], Fiddle::TYPE_INT)
        @dla_stop        = Fiddle::Function.new(libutils['dla_stop'],      [], Fiddle::TYPE_INT)
        @dla_close       = Fiddle::Function.new(libutils['dla_close'],     [], Fiddle::TYPE_INT)
        @dla_clear       = Fiddle::Function.new(libutils['dla_clear'],     [], Fiddle::TYPE_INT)
        @dla_recv_frame  = Fiddle::Function.new(libutils['dla_recv_frame'],[Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT],  Fiddle::TYPE_INT)
        @dla_save_bsd    = Fiddle::Function.new(libutils['dla_save_bsd'],  [Fiddle::TYPE_VOIDP],                    Fiddle::TYPE_INT)
    end

    #打开DLA设备，参数是关键字参数（不同于默认参数），参数的定义在上面都有定义。
    #调用时，全部参数不写，就全部默认，想要哪个就写那个，没写的都用默认值，而且没有顺序
    #比如：open(crc: CRC_GD, freqb: FREQ_5800)
    def open(std: STD_GB, crc: CRC_GB, freqa: FREQ_5830, freqb: FREQ_5790, smpl_time: 5)
        return 0 if @dla_opened
        dn = 'a' * 200
        ret = @dla_open.call(dn, std, crc, freqa, freqb, smpl_time)
        if ret == 1
            dname = cstr(dn)
            @dla_opened = 1
            puts "DLA设备打开成功，名称：".cathex(bin2hex(dname.bytes))
            return 1
        else
            puts "DLA设备打开失败！"
        end
        return 0
    end

    def isopen?
        @dla_opened == 1
    end

    def clear
        return 0 if @dla_opened.nil?
        @dla_clear.call
    end

    def start
        return 0 if @dla_opened.nil?
        @dla_start.call
    end

    def stop
        return 0 if @dla_opened.nil?
        @dla_stop.call
    end

    def close
        return 0 if @dla_opened.nil?
        @dla_close.call
        @dla_opened = false
    end

    #接收一个帧
    def recv_frame(timeout = 10)
        return nil if @dla_opened.nil?
        frm = ST_Frame.malloc
        r = @dla_recv_frame.call(frm, timeout)
        if r == 1
            ret = DlaFrame.new
            ret.frmtype = frm.frmtype
            ret.recvtime = frm.recvtime
            ret.uplink = frm.uplink
            ret.datalen = frm.length
            ret.hexdata = ""
            if frm.length > 0 && frm.length < 256
                bytes = frm.frmdata[0..frm.length-1]
                ret.hexdata = bin2hex(bytes)
                return ret
            end
        end
        return nil
    end

    #接收全部帧
    def recv_frames(timeout = 10)
        dlaframes = []
        while dlaframe = dla.recv_frame(timeout)
            dlaframes << dlaframe
        end
        return dlaframes
    end


    def save_bsd(str_filename)
        return 0 if @dla_opened.nil?
        @dla_save_bsd.call(str_filename)
    end


    def self.inst
        @dla ||= Dla.new
    end
end

def dla
    Dla.inst
end