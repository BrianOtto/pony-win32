use "debug"
use "../win32"

class WindowSettings
    // pixels
    var x: I32 = 0
    var y: I32 = 0
    
    // pixels
    var width: I32 = 100
    var widthMin: I32 = 0
    var widthMax: I32 = 0
    
    // percent
    var widthPct: I32 = 0
    
    // pixels
    var height: I32 = 100
    var heightMin: I32 = 0
    var heightMax: I32 = 0
    
    // percent
    var heightPct: I32 = 0
    
    var title: String = ""
    
    var parent: HWND = HWND
    var menuId: U32 = 0
    var menuHandle: HWND = HWND
    var handle: HWND = HWND
    
    var style: WindowStyle = WindowStyle
    
    new create() => None
    
    new window(wsWidth: I32, wsHeight: I32, wsTitle: String, wsIsPixels: Bool = false) =>
        if wsIsPixels then
            width = wsWidth
            height = wsHeight
        else
            widthPct = wsWidth
            heightPct = wsHeight
        end
        
        title = wsTitle
    
    new control(wsWidth: I32, wsHeight: I32, wsParent: HWND, wsSystemClass: String, 
                wsMenuId: U32, wsTitle: String = "", wsIsPixels: Bool = true) =>
        
        if wsIsPixels then
            width = wsWidth
            height = wsHeight
        else
            widthPct = wsWidth
            heightPct = wsHeight
        end
        
        parent = wsParent
        menuId = wsMenuId
        
        style.systemStyle = WSCHILD()
        style.systemClass = wsSystemClass
        
        title  = wsTitle
    
class WindowStyle
    var cursor: I32 = IDCARROW()
    var backgroundColor: I32 = COLOR3DFACE()
    var systemStyle: DWORD = WSOVERLAPPEDWINDOW()
    var systemClass: String = ""
    
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
    
    fun ref init(): DWORD =>
        var windowClassName: LPCTSTR = LPCTSTR
        var windowClassInstance: HINSTANCE = HINSTANCE
        
        if _settings.style.systemClass == "" then
            var windowClass: WNDCLASS ref = WNDCLASS
            windowClass.lpfnWndProc = _messageHandler
            windowClass.hCursor = LoadCursorA(HINSTANCE, _settings.style.cursor)
            windowClass.hbrBackground = GetSysColorBrush(_settings.style.backgroundColor)
            windowClass.lpszClassName = "winApp".cstring() // TODO: use a random name
            
            let windowClassAtom = RegisterClassA(MaybePointer[WNDCLASS](windowClass))
            
            if windowClassAtom == 0 then
                return _setError("RegisterClassW")
            end
            
            windowClassName = windowClass.lpszClassName
            windowClassInstance = windowClass.hInstance
        else
            windowClassName = _settings.style.systemClass.cstring()
        end
        
        setCoordinates()
        
        var menu = (_settings.menuId, _settings.menuHandle)
        
        let windowHandle = 
            CreateWindowExA(WSEXAPPWINDOW(), windowClassName, _settings.title.cstring(), _settings.style.systemStyle, 
                            _settings.x, _settings.y, _settings.width, _settings.height, 
                            _settings.parent, menu, windowClassInstance, LPVOID)
        
        if windowHandle.is_null() then
            return _setError("CreateWindowExA")
        end
        
        _settings.handle = windowHandle
        
        ShowWindow(windowHandle, I32(1))
        
        if _settings.style.systemClass == "" then
            var msg: MSG ref = MSG
            var ret: I32 = 0
            
            repeat
                ret = GetMessageA(MaybePointer[MSG](msg), windowHandle, UINT(0), UINT(0))
                
                if ret == -1 then
                    if msg.wParam != 0 then
                        return _setError("GetMessageW")
                    end
                else
                    TranslateMessage(MaybePointer[MSG](msg))
                    DispatchMessageA(MaybePointer[MSG](msg))
                end
            until ret <= 0 end
        end
        
        0
    
    fun ref _setError(desc: String = ""): DWORD =>
        let errorCode = GetLastError()
        _error = "Error Code #".add(errorCode.string())
        
        if desc != "" then
            _error = _error.add(" for ").add(desc)
        end
        
        Debug.out(_error)
        
        errorCode
    
    fun getError(): String => _error
    
    fun ref getSettings(): WindowSettings => _settings
    
    fun ref setSettings(ws: WindowSettings): None =>
        _settings = ws
        
        MoveWindow(_settings.handle, _settings.x, _settings.y, _settings.width, _settings.height, 1)
    
    fun ref setMessageHandler(callback: @{(HWND, UINT, WPARAM, LPARAM): LRESULT}): None =>
        _messageHandler = callback
    
    fun ref setCoordinates(): None =>
        var parentWidth: I32 = 0
        var parentHeight: I32 = 0
        
        if _settings.parent.is_null() then
            parentWidth = GetSystemMetrics(SMCXSCREEN())
            parentHeight = GetSystemMetrics(SMCYSCREEN())
        else
            var pr: RECT ref = RECT
            GetWindowRect(_settings.parent, MaybePointer[RECT](pr))
            
            parentWidth = pr.right - pr.left
            parentHeight = pr.bottom - pr.top
        end
        
        if _settings.widthPct > 0 then
            _settings.width = (parentWidth.f32() * (_settings.widthPct.f32() / 100.0)).i32()
            
            if (_settings.widthMin > 0) and (_settings.width < _settings.widthMin) then
                _settings.width = _settings.widthMin
            end
            
            if (_settings.widthMax > 0) and (_settings.width > _settings.widthMax) then
                _settings.width = _settings.widthMax
            end
        end
        
        if _settings.heightPct > 0 then
            _settings.height = (parentHeight.f32() * (_settings.heightPct.f32() / 100.0)).i32()

            if (_settings.heightMin > 0) and (_settings.height < _settings.heightMin) then
                _settings.height = _settings.heightMin
            end

            if (_settings.heightMax > 0) and (_settings.height > _settings.heightMax) then
                _settings.height = _settings.heightMax
            end
        end
        
        // center the window within the parent
        // TODO: develop an automatic layout system
        _settings.x = (parentWidth - _settings.width) / 2
        _settings.y = (parentHeight - _settings.height) / 2