use "debug"
use "../win32"

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

class Window
    var _error: String = ""
    var _settings: WindowSettings
    var _messageHandler: @{(HWND, UINT, WPARAM, LPARAM): LRESULT} = 
        @{(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =>
            SetLastError(ERRORINVALIDHANDLE())
            -1
        }
    
    new create(ws: WindowSettings) =>
        _settings = ws
    
    fun ref init(): None ? =>
        var windowClass: WNDCLASS ref = WNDCLASS
        windowClass.lpfnWndProc = _messageHandler
        windowClass.hCursor = LoadCursorW(HINSTANCE, IDCARROW())
        windowClass.hbrBackground = GetSysColorBrush(COLOR3DFACE())
        windowClass.lpszClassName = "winApp".cstring()
        
        let windowClassAtom = RegisterClassW(MaybePointer[WNDCLASS](windowClass))
        
        if windowClassAtom == 0 then
            _setError("RegisterClassW") ?
        end
        
        let screenW: I32 = GetSystemMetrics(SMCXSCREEN())
        let screenH: I32 = GetSystemMetrics(SMCYSCREEN())
        
        var windowW = (screenW.f32() * (_settings.width.f32() / 100.0)).i32()
        
        if (_settings.widthMin > 0) and (windowW < _settings.widthMin) then
            windowW = _settings.widthMin
        end

        if (_settings.widthMax > 0) and (windowW < _settings.widthMax) then
            windowW = _settings.widthMax
        end
        
        var windowH = (screenH.f32() * (_settings.height.f32() / 100.0)).i32()

        if (_settings.heightMin > 0) and (windowH < _settings.heightMin) then
            windowH = _settings.heightMin
        end

        if (_settings.heightMax > 0) and (windowH < _settings.heightMax) then
            windowH = _settings.heightMax
        end
        
        let windowX: I32 = (screenW - windowW) / 2
        let windowY: I32 = (screenH - windowH) / 2
        
        let windowHandle = CreateWindowExA(WSEXAPPWINDOW(), windowClassAtom, _settings.title.cstring(), WSOVERLAPPEDWINDOW(), 
                                           windowX, windowY, windowW, windowH, HWND, HMENU, windowClass.hInstance, LPVOID)
        
        if windowHandle.is_null() then
            _setError("CreateWindowExA") ?
        end
        
        ShowWindow(windowHandle, I32(1))
        
        var msg: MSG ref = MSG
        var ret: I32 = 0
        
        repeat
            ret = GetMessageW(MaybePointer[MSG](msg), windowHandle, UINT(0), UINT(0))
            
            if ret == -1 then
                if msg.wParam != 0 then
                    _setError("GetMessageW") ?
                end
            else
                TranslateMessage(MaybePointer[MSG](msg))
                DispatchMessageW(MaybePointer[MSG](msg))
            end
        until ret <= 0 end
    
    fun ref _setError(desc: String = "", exception: Bool = true): None ? =>
        _error = "Error Code #".add(GetLastError().string())
        
        if desc != "" then
            _error = _error.add(" for ").add(desc)
        end
        
        Debug.out(_error)
        
        if exception then error end
    
    fun getError(): String => _error
    
    fun ref setMessageHandler(callback: @{(HWND, UINT, WPARAM, LPARAM): LRESULT}) =>
        _messageHandler = callback