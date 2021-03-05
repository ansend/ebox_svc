# -*- coding: UTF-8 -*-
#require "utest"
require_relative "p20_frame"
require_relative "trans_protocol"
require_relative "../lib/utest"

require 'pathname'
require 'socket'               # 获取socket标准库

def start_svc()

    server = TCPServer.open(2000)  # Socket 监听端口为 2000
    loop {                         # 永久运行服务
      client = server.accept       # 等待客户端连接
     
      line = 1
      loop # firstly read out all the request from client.
          #line = client.gets    # here simulate read the client request.
          line = client.recv 2500  # here simulate read the client request.
          p line
          puts line
          puts "#{line.length}" + "size"
          puts "#{i}" + "times"
      }
      

      client.puts(Time.now.ctime)  # 发送时间到客户端
      client.puts "Closing the connection. Bye!"

      client.close                 # 关闭客户端连接
    }

end 


class P20TradeMachine < EtcTradeMachineBase

  # 奇怪的是，不能有构造函数！！！
  # def initialize
  #     @obuid = 0
  #     @start_time = 0
  # end

  #有什么全局变量，用attr_accessor
  attr_accessor :obuid
  attr_accessor :start_time
  attr_accessor :trade_counter
  attr_accessor :trade_tac
  attr_accessor :time_c6_c7
  attr_accessor :obu_ic_id
  attr_accessor :set_dla_ac
  attr_accessor :statistics
  attr_accessor :b9_cardps
  attr_accessor :pay_money
  

  attr_accessor :trade_mode # 0: success , 1: failure


  state_machine :initial => :start do
    #ev_trade，ev_control，名字是固定的，必须叫这个名字
    #状态表必须在这两个事件内，不要自行改动
    event :ev_trade do
      transition :start => :b0,
                 :b0 => :b4,
                 :b4 => :b5,
                 :b5 => :b4
    end
    event :ev_break do             #break事件，所有状态都转到b4
      transition all => :b4
    end
    event :ev_reset do             #reset事件，所有状态都转到start
      transition all => :start
    end
    event :ev_stop do              #stop事件，所有状态都转到finish，结束
      transition all => :finished
    end
  end


  def on_trade_start
    set_ff_potocol_type(FrameParkingFFFF)

    @trade_counter = 0
    @trade_tac=0   #标记失败，返回的B5帧中，状态码非零。
    @time_c6_c7=''
    @money_b4=""
    @money_b5=""
    @statistics={}
    @set_dla_ac =0
    @b9_cardps = 0
    @pay_money = 0
    @trade_mode = 0

    frmc0 = P20FrameC0.new(channel: 0, txpower: 1, mode:0)
    send_frame(frmc0)

  end

  def on_trade_b0
    puts "start b0 hex data\n"
    puts receivehexdat
    frmb0 = P20FrameB0.new
    frmb0 <= receivehexdat
    puts frmb0.to_ps
    puts "软件版本：#{frmb0.sw_version.hexstr}"
    send_frame(BZFrameEmpty.new)
    send_frame(BZFrame4C.new(1))
  end

  def on_trade_b4
    puts "start b2 hex data\n"
    puts receivehexdat
    #if receivehexdat[10..11] == "80"
    if false
      keep_state
    #elsif ( receivehexdat[10..11] == "00" && receivehexdat[12..13] == "00")
    elsif (true)

      # 脚本执行过程中，更换交易标签场景， 重置交易失败标记为0， 即初始状态下没有交易失败发生。
      if receivehexdat[2..9].to_i(16) != @obuid
      end

      @start_time = utils.get_utick
      @frmb4 ||= P20FrameB4.new
      @frmb4 <= receivehexdat
      puts @frmb4.to_ps
      @obuid =@frmb4.obuid.value
      file_0019 = @frmb4.last_station.to_hs
      if @obuid != 0
        @frmc6 ||= P20FrameC6.new  #(@obuid, @obu_ic_id)
        @frmc6.set_field_values(:obuid => @obuid, :money => @pay_money, :file0019 => file_0019)
        puts @frmc6.to_hs
        puts @frmc6.to_ps
        send_frame(@frmc6)
		
      else
        @frmc2 ||= P20FrameC2.new  #(@obuid,1)
        @frmc2.set_field_values(:obuid => @obuid)
        puts @frmc2.to_hs
        #send_frame(@frmc2)
        puts "B4 zero obu id, break current trade"

        break_trade
      end
    else
      puts "B4  OBU or ICC read ERROR, break current trade"
      break_trade
    end
  end
  
   def on_trade_b5
    puts "start b5 hex data\n"
    puts receivehexdat
    #if receivehexdat[10..11] == "80"
    if false
      keep_state
    #elsif ( receivehexdat[10..11] == "00" && receivehexdat[12..13] == "00")
    elsif ( true)
      # 脚本执行过程中，更换交易标签场景， 重置交易失败标记为0， 即初始状态下没有交易失败发生。
      if receivehexdat[2..9].to_i(16) != @obuid
      end

      @start_time = utils.get_utick
      @frmb5 ||= P20FrameB5.new
      @frmb5 <= receivehexdat
      puts @frmb5.to_ps
      @obuid =@frmb5.obuid.value
      if @obuid != 0
        @frmc1||= P20FrameC1.new  #(@obuid, @obu_ic_id)
        @frmc1.obuid <= @obuid
       
        puts @frmc1.to_hs
        send_frame(@frmc1)
		@trade_counter += 1
		puts "#{sprintf("%08x", @obuid)}交易次数是 #{@trade_counter} "


      else
        @frmc2 ||= P20FrameC2.new  #(@obuid,1)
        @frmc2.set_field_values(:obuid => @obuid)
        puts @frmc2.to_hs
        #send_frame(@frmc2)
        puts "B4 zero obu id, break current trade"

        break_trade
      end
    else
      puts "B4  OBU or ICC read ERROR, break current trade"
      break_trade
    end
  end

  def on_trade_b10000
    puts receivehexdat
    if receivehexdat[10..11] == "00"
      @frmb3 ||= P20FrameB3.new
      @frmb3 <= receivehexdat

      @frmc1 ||= P20FrameC1.new
      @frmc1.set_field_values(:obuid => @obuid)
      puts @frmc1.to_hs
      send_frame(@frmc1)
    else
      @frmc2 ||= P20FrameC2.new
      @frmc2.set_field_values(:obuid => @obuid)
      puts @frmc2.to_hs
      send_frame(@frmc2)
      break_trade
    end
  end


  def on_trade_finished
    send_frame(BZFrame4C.new(0))
    stop_machine
  end

  def on_trade_flowexception  #对于交易过程中的B2或定位帧或其他特殊帧的处理

    if receivehexdat[0..1]=="B2" 
       puts receivehexdat
       keep_state
    end

    if receivehexdat[0..1]=="B4" && receivehexdat[12..13] != "00"
      keep_state
    end
  end
end

class TestEtcR10 < TestSuit

  def suit_desc
    '测试 P20 与车道机交易接口'
  end

  def suit_options
    #设置选项
  end
  
  def test_start_server(desc="启动服务器")
  
      start_svc()
  
  end 
end


TestEtcR10.run
