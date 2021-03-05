#encoding: gb2312

require 'win32/autogui'
require 'windows/window'
require 'json'
include Autogui::Input
include Windows::Window
require "fiddle"
require "fiddle/import"


def code_to_vk(code)
    case code
    	when VK_LBUTTON
    		return "VK_LBUTTON"
    	when VK_RBUTTON
    		return "VK_RBUTTON"
    	when VK_CANCEL
    		return "VK_CANCEL"
    	when VK_BACK
    		return "VK_BACK"
    	when VK_TAB
    		return "VK_TAB"
    	when VK_CLEAR
    		return "VK_CLEAR"
    	when VK_RETURN
    		return "VK_RETURN"
    	when VK_SHIFT
    		return "VK_SHIFT"
    	when VK_CONTROL
    		return "VK_CONTROL"
    	when VK_MENU
    		return "VK_MENU"
    	when VK_PAUSE
    		return "VK_PAUSE"
    	when VK_ESCAPE
    		return "VK_ESCAPE"
    	when VK_SPACE
    		return "VK_SPACE"
    	when VK_PRIOR
    		return "VK_PRIOR"
    	when VK_NEXT
    		return "VK_NEXT"
    	when VK_END
    		return "VK_END"
    	when VK_HOME
    		return "VK_HOME"
    	when VK_LEFT
    		return "VK_LEFT"
    	when VK_UP
    		return "VK_UP"
    	when VK_RIGHT
    		return "VK_RIGHT"
    	when VK_DOWN
    		return "VK_DOWN"
    	when VK_SELECT
    		return "VK_SELECT"
    	when VK_EXECUTE
    		return "VK_EXECUTE"
    	when VK_SNAPSHOT
    		return "VK_SNAPSHOT"
    	when VK_INSERT
    		return "VK_INSERT"
    	when VK_DELETE
    		return "VK_DELETE"
    	when VK_HELP
    		return "VK_HELP"
    	when VK_0
    		return "VK_0"
    	when VK_1
    		return "VK_1"
    	when VK_2
    		return "VK_2"
    	when VK_3
    		return "VK_3"
    	when VK_4
    		return "VK_4"
    	when VK_5
    		return "VK_5"
    	when VK_6
    		return "VK_6"
    	when VK_7
    		return "VK_7"
    	when VK_8
    		return "VK_8"
    	when VK_9
    		return "VK_9"
    	when VK_A
    		return "VK_A"
    	when VK_B
    		return "VK_B"
    	when VK_C
    		return "VK_C"
    	when VK_D
    		return "VK_D"
    	when VK_E
    		return "VK_E"
    	when VK_F
    		return "VK_F"
    	when VK_G
    		return "VK_G"
    	when VK_H
    		return "VK_H"
    	when VK_I
    		return "VK_I"
    	when VK_J
    		return "VK_J"
    	when VK_K
    		return "VK_K"
    	when VK_L
    		return "VK_L"
    	when VK_M
    		return "VK_M"
    	when VK_N
    		return "VK_N"
    	when VK_O
    		return "VK_O"
    	when VK_P
    		return "VK_P"
    	when VK_Q
    		return "VK_Q"
    	when VK_R
    		return "VK_R"
    	when VK_S
    		return "VK_S"
    	when VK_T
    		return "VK_T"
    	when VK_U
    		return "VK_U"
    	when VK_V
    		return "VK_V"
    	when VK_W
    		return "VK_W"
    	when VK_X
    		return "VK_X"
    	when VK_Y
    		return "VK_Y"
    	when VK_Z
    		return "VK_Z"
    	when VK_LWIN
    		return "VK_LWIN"
    	when VK_RWIN
    		return "VK_RWIN"
    	when VK_APPS
    		return "VK_APPS"
    	when VK_NUMPAD0
    		return "VK_NUMPAD0"
    	when VK_NUMPAD1
    		return "VK_NUMPAD1"
    	when VK_NUMPAD2
    		return "VK_NUMPAD2"
    	when VK_NUMPAD3
    		return "VK_NUMPAD3"
    	when VK_NUMPAD4
    		return "VK_NUMPAD4"
    	when VK_NUMPAD5
    		return "VK_NUMPAD5"
    	when VK_NUMPAD6
    		return "VK_NUMPAD6"
    	when VK_NUMPAD7
    		return "VK_NUMPAD7"
    	when VK_NUMPAD8
    		return "VK_NUMPAD8"
    	when VK_NUMPAD9
    		return "VK_NUMPAD9"
    	when VK_MULTIPLY
    		return "VK_MULTIPLY"
    	when VK_ADD
    		return "VK_ADD"
    	when VK_SEPARATOR
    		return "VK_SEPARATOR"
    	when VK_SUBTRACT
    		return "VK_SUBTRACT"
    	when VK_DECIMAL
    		return "VK_DECIMAL"
    	when VK_DIVIDE
    		return "VK_DIVIDE	when "
    	when VK_F1
    		return "VK_F1"
    	when VK_F2
    		return "VK_F2"
    	when VK_F3
    		return "VK_F3"
    	when VK_F4
    		return "VK_F4"
    	when VK_F5
    		return "VK_F5"
    	when VK_F6
    		return "VK_F6"
    	when VK_F7
    		return "VK_F7"
    	when VK_F8
    		return "VK_F8"
    	when VK_F9
    		return "VK_F9"
    	when VK_F10
    		return "VK_F10"
    	when VK_F11
    		return "VK_F11"
    	when VK_F12
    		return "VK_F12"
    	when VK_NUMLOCK
    		return "VK_NUMLOCK"
    	when VK_SCROLL
    		return "VK_SCROLL"
    	when VK_OEM_EQU
    		return "VK_OEM_EQU"
    	when VK_LSHIFT
    		return "VK_LSHIFT"
    	when VK_RSHIFT
    		return "VK_RSHIFT"
    	when VK_LCONTROL
    		return "VK_LCONTROL"
    	when VK_RCONTROL
    		return "VK_RCONTROL"
    	when VK_LMENU
    		return "VK_LMENU"
    	when VK_RMENU
    		return "VK_RMENU"
    	when VK_OEM_1
    		return "VK_OEM_1"
    	when VK_OEM_PLUS
    		return "VK_OEM_PLUS"
    	when VK_OEM_COMMA
    		return "VK_OEM_COMMA"
    	when VK_OEM_MINUS
    		return "VK_OEM_MINUS"
    	when VK_OEM_PERIOD
    		return "VK_OEM_PERIOD"
    	when VK_OEM_2
    		return "VK_OEM_2"
    	when VK_OEM_3 
    		return "VK_OEM_3 "
    	when VK_OEM_4
    		return "VK_OEM_4"
    	when VK_OEM_5
    		return "VK_OEM_5"
    	when VK_OEM_6
    		return "VK_OEM_6"
    	when VK_OEM_7
    		return "VK_OEM_7"
    	when VK_OEM_8
    		return "VK_OEM_8"
    	else
    		return sprintf("0x%.2x", code)
    end
end

TPoint = Fiddle::Importer.struct([
    'int x',
    'int y'
])
class UiRecord
    def initialize
        libutest       = Fiddle.dlopen('utest.dll')
        @ui_record_by_name     = Fiddle::Function.new(libutest['ui_record_by_name'],     [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        @ui_record_by_pid      = Fiddle::Function.new(libutest['ui_record_by_pid'],      [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)

        libuser32              = Fiddle.dlopen('user32.dll')
        @ClientToScreen        = Fiddle::Function.new(libuser32['ClientToScreen'],       [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
        @BringWindowToTop      = Fiddle::Function.new(libuser32['BringWindowToTop'],     [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
        @SetCursorPos          = Fiddle::Function.new(libuser32['SetCursorPos'],         [Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        @PostMessage           = Fiddle::Function.new(libuser32['PostMessage'],          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        @SendMessage           = Fiddle::Function.new(libuser32['SendMessage'],          [Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
        @WindowFromPoint       = Fiddle::Function.new(libuser32['WindowFromPoint'],      [Fiddle::TYPE_LONG_LONG], Fiddle::TYPE_INT)
        @SetFocus              = Fiddle::Function.new(libuser32['SetFocus'],             [Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
    end

    def record_by_name(exename)
        puts "start to record by exe name: #{exename}, CRTL+SHIFT+F12 to stop record."
        recfilename = 'a' * 256
        ret = @ui_record_by_name.call(exename, recfilename, 0)
        puts "record stoped"
        if ret == 1
            return cstr(recfilename)
        else
            return ""
        end
    end

    def record_by_pid(pid)
        puts "start to record by pid: #{pid}, CRTL+SHIFT+F12 to stop record"
        recfilename = 'a' * 256
        ret = @ui_record_by_pid.call(pid, recfilename, 0)
        puts "record stoped"
        if ret == 1
            return cstr(recfilename)
        else
            return ""
        end
    end

    def ClientToScreen(hwnd, x, y)
        @p ||= TPoint.malloc
        @p.x = x
        @p.y = y
        @ClientToScreen.call hwnd, @p
        return @p.x, @p.y
    end

    def BringWindowToTop(hwnd)
        @BringWindowToTop.call hwnd
    end

    def SetCursorPos(x, y)
        @SetCursorPos.call x, y
    end

    def PostMessage(hwnd, msg, wparam, lparam)
        @PostMessage.call hwnd, msg, wparam, lparam
    end

    def SendMessage(hwnd, msg, wparam, lparam)
        @SendMessage.call hwnd, msg, wparam, lparam
    end

    def WindowFromPoint(x, y)
        lp = x + y * 0x100000000
        ret=@WindowFromPoint.call lp
    end

    def SetFocus(hwnd)
        @SetFocus.call hwnd
    end

    def record_get_src(app_name_id, savefilename = nil)
        retsrc = []
        hashsrc = []
        recfilename = app_name_id.is_a?(String) ? record_by_name(app_name_id) : record_by_pid(app_name_id)
        casename = "test_case"
        if !savefilename.nil?
            str = File.basename savefilename
            ext = File.extname str
            casename = str[0..str.length-ext.length-1]
        end
        retsrc << "def #{casename}(desc: 'description')"
        #--------------------------1json to hash------------------
        if recfilename.length
            File.open(recfilename, "r") do |file|
                file.each { |line|
                    hashsrc << JSON.parse(line)
                }
                file.close
            end
        end
        #--------------------------2合并keypress, 合并button click------------------
        keystate = ""
        hashsrc.each_with_index {|hsrc, i|
            if hsrc["op"] == "key_up" || hsrc["op"] == "key_down"
                hsrc["key"] = code_to_vk(hsrc['key'].to_i)
            end
            if hsrc["op"] == "key_down"
                keystate = "hasbeenset"
            end
            if hsrc["op"] == "key_up" && keystate == ""
                hsrc["op"] = "key_press"
                keystate = "hasbeenset"
                next
            end
            if i > 0
                if hsrc["op"] == "key_up" && hashsrc[i-1]["op"] == "key_down" && hsrc["key"] == hashsrc[i-1]["key"]
                    hashsrc[i-1]["skiped"] = true
                    hsrc["op"] = "key_press"
                elsif hsrc["op"] == "lbtn_up" && hashsrc[i-1]["op"] == "lbtn_down" && hsrc["x"] == hashsrc[i-1]["x"] && hsrc["y"] == hashsrc[i-1]["y"]
                    hashsrc[i-1]["skiped"] = true
                    hsrc["op"] = "lbtn_click"
                elsif hsrc["op"] == "rbtn_up" && hashsrc[i-1]["op"] == "rbtn_down" && hsrc["x"] == hashsrc[i-1]["x"] && hsrc["y"] == hashsrc[i-1]["y"]
                    hashsrc[i-1]["skiped"] = true
                    hsrc["op"] = "rbtn_click"
                end
            end
        }
        hashsrc.delete_if{|a| a["skiped"] == true}

        #--------------------------3-连续的键盘输入合并为一行-----------------
        hashsrc.each_with_index {|hsrc, i|
            if i > 0
                if (hsrc["op"] == "key_press") && (hashsrc[i-1]["op"] == "key_press") && (hsrc["obj"] == hashsrc[i-1]["obj"])
                    if hsrc["utick"] - hashsrc[i-1]["utick"] < 100 * 1000
                        hashsrc[i-1]["skiped"] = true
                        hsrc["key"] = hashsrc[i-1]["key"] +", " + hsrc["key"]
                    end
                end
            end
        }
        hashsrc.delete_if{|a| a["skiped"] == true}

        #-----------------------4-删除 CTRL_SHIFT_F12,否则回放结束，系统键盘鼠标出问题-----------------
        stopkeystate = {"VK_CONTROL" => -1, "VK_SHIFT" => -1, "VK_F12" => -1}
        minindex = -1
        hashsrc.each_with_index{|hsrc, i|
            if hsrc["op"] == "key_down"
                if hsrc["key"] == "VK_CONTROL"
                    stopkeystate["VK_CONTROL"] = i
                elsif hsrc["key"] == "VK_SHIFT"
                    stopkeystate["VK_SHIFT"] = i
                elsif hsrc["key"] == "VK_F12"
                    stopkeystate["VK_F12"] = i
                end
            elsif hsrc["op"] == "key_up"
                if hsrc["key"] == "VK_CONTROL"
                    stopkeystate["VK_CONTROL"] = -1
                elsif hsrc["key"] == "VK_SHIFT"
                    stopkeystate["VK_SHIFT"] = -1
                elsif hsrc["key"] == "VK_F12"
                    stopkeystate["VK_F12"] = -1
                end
            end
            if (stopkeystate["VK_CONTROL"] != -1) && (stopkeystate["VK_SHIFT"] != -1) && (stopkeystate["VK_F12"] != -1)
                tmp = []
                tmp << stopkeystate["VK_CONTROL"]
                tmp << stopkeystate["VK_SHIFT"]
                tmp << stopkeystate["VK_F12"]
                minindex = tmp.min
            end
        }
        if minindex != -1
            hashsrc.each_with_index{|hsrc, i|
                if i >= minindex
                    hsrc["skiped"] = true
                end
            }
        end
        hashsrc.delete_if{|a| a["skiped"] == true}

        #------------------------5输出源码--------------------
        last_tick = 0
        last_obj = ""
        hashsrc.each_with_index{|hsrc, i|
            tick = hsrc["utick"]
            sltime = sprintf("%.03f", (tick-last_tick)/(1000.0*1000.0))

            obj = hsrc["obj"]
            if obj.nil?
                obj = ""
            end
            pntobj = ", '#{obj}'"
            if i > 0
                if last_obj != obj
                    retsrc << "    "
                else
                    pntobj = ""  #obj不要写太多，只写一个就可以了，免得代码看起来太臃肿
                end
            end
            case hsrc["op"]
                when "key_press"
                    retsrc << "    @app.key_press(    #{sltime}, [#{hsrc['key']}]#{pntobj})"
                when "key_up"
                    retsrc << "    @app.key_up(       #{sltime}, #{hsrc['key']}#{pntobj})"
                when "key_down"
                    retsrc << "    @app.key_down(     #{sltime}, #{hsrc['key']}#{pntobj})"
                when "rbtn_down"
                    retsrc << "    @app.rbtn_down(    #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "rbtn_up"
                    retsrc << "    @app.rbtn_up(      #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "rbtn_click"
                    retsrc << "    @app.rbtn_click(   #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "rbtn_dclk"
                    retsrc << "    @app.rbtn_dbclick( #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "lbtn_down"
                    retsrc << "    @app.lbtn_down(    #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "lbtn_up"
                    retsrc << "    @app.lbtn_up(      #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "lbtn_click"
                    retsrc << "    @app.lbtn_click(   #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "lbtn_dclk"
                    retsrc << "    @app.lbtn_dbclick( #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
                when "move_to"
                    retsrc << "    @app.move_to(      #{sltime}, #{hsrc['x']}, #{hsrc['y']}#{pntobj})"
            end
            last_tick = tick
            last_obj = obj
        }
        #------------------------6收工--------------------
        retsrc << "end"
        ret = retsrc.join("\n")
        if !savefilename.nil?
            File.open("#{savefilename}", "w") do |file|
                file.puts "#encoding: gb2312\n"
                retsrc.each do |line|
                    file.puts line.encode("gb2312")
                end
                file.close
            end
        end
        return ret
    end

end

def uirec
    @uirec ||= UiRecord.new
end

module MoustEvent
    MOUSEEVENTF_MOVE        = 0x0001
    MOUSEEVENTF_LEFTDOWN    = 0x0002
    MOUSEEVENTF_LEFTUP      = 0x0004
    MOUSEEVENTF_RIGHTDOWN   = 0x0008
    MOUSEEVENTF_RIGHTUP     = 0x0010
    MOUSEEVENTF_MIDDLEDOWN  = 0x0020
    MOUSEEVENTF_MIDDLEUP    = 0x0040
    MOUSEEVENTF_XDOWN       = 0x0080
    MOUSEEVENTF_XUP         = 0x0100
    MOUSEEVENTF_WHEEL       = 0x0800
    MOUSEEVENTF_VIRTUALDESK = 0x4000
    MOUSEEVENTF_ABSOLUTE    = 0x8000

    WM_LBUTTONDOWN          = 0x0201
    WM_LBUTTONUP            = 0x0202
    WM_LBUTTONDBLCLK        = 0x0203
    WM_RBUTTONDOWN          = 0x0204
    WM_RBUTTONUP            = 0x0205
    WM_RBUTTONDBLCLK        = 0x0206

    MK_LBUTTON              = 0x0001
    MK_RBUTTON              = 0x0002
end


class Autogui::ApplicationEx < Autogui::Application
    include MoustEvent
    def main_window
        return @main_window if @main_window

        # pre sanity checks
        raise_error "calling main_window without a pid, application not initialized properly" unless @pid

        Autogui::EnumerateDesktopWindows.new.each{ |w|
            if w.pid == pid && w.parent.nil?
                @main_window = w
                break
            end
        }
        @main_window
    end

    def find_window(classname)
        raise_error "calling find_window without a pid, application not initialized properly" unless @pid

        Autogui::EnumerateDesktopWindows.new.each{ |w|
            if w.pid == pid && w.window_class.match(classname)
                return w
            end
        }
        return nil
    end
    
    def button_press(title)
        obj = obj_by_text(title)
        if obj
            obj.set_focus
            keystroke(VK_RETURN)
        end
    end

    def obj_by_text(title, index = -1, parent = nil)
        t = title.bytes
        c = 1
        parent = main_window if parent.nil?
        if parent
            parent.children.each {|w|
                if w.title.bytes == t
                    if index == -1
                        return w
                    else
                        c = c + 1
                        if c == index
                            return w
                        end
                    end
                end
            }
        end
        return nil
    end

    def obj_by_class(classname, index = -1, parent = nil)
        t = classname.bytes
        c = -1
        parent = main_window if parent.nil?
        if parent
            parent.children.each {|w|
                if w.window_class.bytes == t
                    if index == -1
                        return w
                    else
                        c = c + 1
                        if c == index
                            return w
                        end
                    end
                end
            }
        end
        return nil
    end

    def obj_by_index(classname, index, parent = nil)
        t = classname.bytes
        c = 0
        parent = main_window if parent.nil?
        if parent then
            parent.children.each {|w|
                if w.window_class.bytes == t
                    return w if c == index
                    c = c + 1
                end
            }
        end
        return nil
    end

    def obj_by_path(path = nil)
        if path.nil? || path.length == 0
            return @_obj_by_path
        end
        if !path.include?("/")
            @_obj_by_path = main_window
            return main_window
        end
        pathlist = path.split("/")
        parent = nil
        ret = nil
        pathlist.each { |p|
            if p.include?(".")
                tmp = p.split(".")
                classname = tmp[0]
                index = Integer(tmp[1]) rescue nil
                if index.nil?
                    ret = obj_by_text(tmp[1], parent)
                else
                    ret = obj_by_index(classname, index, parent)
                end
                parent = ret
            else
                classname = p
                index = 0
                ret = obj_by_index(classname, index, parent)
                parent = ret
            end
        }
        @_obj_by_path = ret
        return ret
    end

    def key_delay
        0.05
    end
    
    def key_down(sleeptime, vk_key, obj = nil)
        obj_by_path(obj)
        sleep(sleeptime);
        keybd_event(vk_key, 0, KEYBD_EVENT_KEYDOWN, 0);
    end

    def key_up(sleeptime, vk_key, obj = nil)
        obj_by_path(obj)
        sleep(sleeptime);
        keybd_event(vk_key, 0, KEYBD_EVENT_KEYUP, 0);
    end

    def key_press(sleeptime, vk_key, obj = nil)
        obj_by_path(obj)
        sleeptime = sleeptime - vk_key.size * key_delay
        sleep(sleeptime) if sleeptime > 0
        vk_key.each{|key|
            keybd_event(key, 0, KEYBD_EVENT_KEYDOWN, 0);
            sleep key_delay
            keybd_event(key, 0, KEYBD_EVENT_KEYUP, 0);
        }
    end

    def rbtn_down(sleeptime, x, y, obj = nil)
        sleep(sleeptime);
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        mouse_event MOUSEEVENTF_RIGHTDOWN, mx, my, 0, 0
    end

    def rbtn_up(sleeptime, x, y, obj = nil)
        sleep(sleeptime);
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        mouse_event MOUSEEVENTF_RIGHTUP, mx, my, 0, 0
    end

    def rbtn_click(sleeptime, x, y, obj = nil)
        sleeptime = sleeptime - key_delay
        sleep(sleeptime) if sleeptime > 0
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        mouse_event MOUSEEVENTF_RIGHTDOWN, mx, my, 0, 0
        sleep key_delay
        mouse_event MOUSEEVENTF_RIGHTUP, mx, my, 0, 0
    end

    def rbtn_dbclick(sleeptime, x, y, obj = nil)
        sleep(sleeptime) if sleeptime > 0
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        lparam = mx + my * 65536
        uirec.PostMessage objwnd.handle, WM_RBUTTONDOWN, MK_RBUTTON, lparam
        uirec.PostMessage objwnd.handle, WM_RBUTTONDBLCLK, MK_RBUTTON, lparam
        uirec.PostMessage objwnd.handle, WM_RBUTTONUP, MK_RBUTTON, lparam
    end

    def lbtn_down(sleeptime, x, y, obj = nil)
        sleep(sleeptime);
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        mouse_event MOUSEEVENTF_LEFTDOWN, mx, my, 0, 0
    end

    def lbtn_up(sleeptime, x, y, obj = nil)
        sleep(sleeptime);
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        mouse_event MOUSEEVENTF_LEFTUP, mx, my, 0, 0
    end

    def lbtn_click(sleeptime, x, y, obj = nil)
        sleeptime = sleeptime - 1 * key_delay
        sleep(sleeptime) if sleeptime > 0
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        mouse_event MOUSEEVENTF_LEFTDOWN, mx, my, 0, 0
        sleep key_delay
        mouse_event MOUSEEVENTF_LEFTUP, mx, my, 0, 0
    end

    def lbtn_dbclick(sleeptime, x, y, obj = nil)
        sleeptime = sleeptime
        sleep(sleeptime) if sleeptime > 0
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        lparam = mx + my * 65536
        uirec.PostMessage objwnd.handle, WM_LBUTTONDOWN, MK_LBUTTON, lparam
        uirec.PostMessage objwnd.handle, WM_LBUTTONDBLCLK, MK_LBUTTON, lparam
        uirec.PostMessage objwnd.handle, WM_LBUTTONUP, MK_LBUTTON, lparam
    end

    def move_to(sleeptime, x, y, obj = nil)
        sleep(sleeptime);
        objwnd = obj_by_path(obj)
        mx, my = uirec.ClientToScreen objwnd.handle, x, y
        uirec.SetCursorPos(mx, my)
    end
end
