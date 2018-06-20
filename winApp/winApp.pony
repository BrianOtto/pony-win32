use "../win32"
use "debug"

class WindowSettings
    var x: I32 = 0
    var y: I32 = 0
    var width: I32 = 100
    var widthMin: I32 = 0
    var widthMax: I32 = 0
    var height: I32 = 100
    var heightMin: I32 = 0
    var heightMax: I32 = 0
    var title: String = ""
    var parent: HWND = HWND
    var handle: HWND = HWND
    var style: WindowStyle = WindowStyle
    
    new create() => None
    
    new simple(sWidth: I32, sHeight: I32, sTitle: String) =>
        width  = sWidth
        height = sHeight
        title  = sTitle

class WindowStyle
    var icon: String = ""
    var cursor: I32 = IDCARROW()
    var backgroundColor: I32 = COLOR3DFACE()
    var resizable: Bool = true
    var titlebar: Bool = true
    var menu: Bool = true
    var border: Bool = true
    var minimize: Bool = true
    var maximize: Bool = true
    var visible: Bool = true
    
    new create() => None

primitive WindowHandles
  fun apply(): Array[HWND] => Array[HWND]

primitive Window
    fun @apply(ws: WindowSettings): WPARAM =>
        var windowClass: WNDCLASS ref = WNDCLASS
        
        windowClass.lpfnWndProc = @{
            (hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =>
            
            match msg
            | WMDESTROY() =>
                PostQuitMessage(0)
                0
            else
                DefWindowProcW(hWnd, msg, wParam, lParam)
            end
        }
        
        windowClass.hCursor = LoadCursorW(HINSTANCE, IDCARROW())
        windowClass.hbrBackground = GetSysColorBrush(COLOR3DFACE())
        windowClass.lpszClassName = "winApp".cstring()
        
        let windowClassAtom = RegisterClassW(MaybePointer[WNDCLASS](windowClass))
        
        if windowClassAtom == 0 then
            Debug.out("RegisterClassW Error: ".add(GetLastError().string()))
            WPARAM(-1)
        end
        
        let screenW: I32 = GetSystemMetrics(SMCXSCREEN())
        let screenH: I32 = GetSystemMetrics(SMCYSCREEN())
        
        var windowW = (screenW.f32() * (ws.width.f32() / 100.0)).i32()
        
        if (ws.widthMin > 0) and (windowW < ws.widthMin) then
            windowW = ws.widthMin
        end

        if (ws.widthMax > 0) and (windowW < ws.widthMax) then
            windowW = ws.widthMax
        end
        
        var windowH = (screenH.f32() * (ws.height.f32() / 100.0)).i32()

        if (ws.heightMin > 0) and (windowH < ws.heightMin) then
            windowH = ws.heightMin
        end

        if (ws.heightMax > 0) and (windowH < ws.heightMax) then
            windowH = ws.heightMax
        end
        
        let windowX: I32 = (screenW - windowW) / 2
        let windowY: I32 = (screenH - windowH) / 2
        
        let windowHandle = CreateWindowExA(WSEXAPPWINDOW(), windowClassAtom, ws.title.cstring(), WSOVERLAPPEDWINDOW(), 
                                           windowX, windowY, windowW, windowH, HWND, HMENU, windowClass.hInstance, LPVOID)
        
        if windowHandle.is_null() then
            Debug.out("CreateWindowExA Error: ".add(GetLastError().string()))
            WPARAM(-1)
        else
            ShowWindow(windowHandle, I32(1))
            
            var msg: MSG ref = MSG
            var ret: I32 = 0
            
            repeat
                ret = GetMessageW(MaybePointer[MSG](msg), windowHandle, UINT(0), UINT(0))
                
                if (ret == -1) then
                    if MSG.message != WMNULL() then
                        Debug.out("GetMessageW Error: ".add(ret.string()))
                    end
                else
                    TranslateMessage(MaybePointer[MSG](msg))
                    DispatchMessageW(MaybePointer[MSG](msg))
                end
            until ret <= 0 end
            
            msg.wParam
        end