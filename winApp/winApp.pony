use "debug"
use "../win32"

class WindowSettings
    // pixels
    var x: I32 = 0
    var y: I32 = 0
    
    // percentage
    var width: I32 = 100
    
    // pixels
    var widthMin: I32 = 0
    var widthMax: I32 = 0
    var widthPixels: I32 = 0
    
    // percentage
    var height: I32 = 100
    
    // pixels
    var heightMin: I32 = 0
    var heightMax: I32 = 0
    var heightPixels: I32 = 0
    
    var title: String = ""
    
    var parent: HWND = HWND
    var menuID: HMENU = HMENU
    var handle: HWND = HWND
    
    var style: WindowStyle = WindowStyle
    
    new create() => None
    
    new window(sWidth: I32, sHeight: I32, sTitle: String) =>
        width  = sWidth
        height = sHeight
        title  = sTitle
    
    new control(sWidth: I32, sHeight: I32, sParent: HWND, sSystemClass: String, sTitle: String = "") =>
        width  = sWidth
        height = sHeight
        parent = sParent
        style.systemStyle = WSCHILD()
        style.systemClass = sSystemClass
        title  = sTitle
    
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
        
        let windowHandle = 
            CreateWindowExA(WSEXAPPWINDOW(), windowClassName, _settings.title.cstring(), _settings.style.systemStyle, 
                            _settings.x, _settings.y, _settings.widthPixels, _settings.heightPixels, 
                            _settings.parent, _settings.menuID, windowClassInstance, LPVOID)
        
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
    
    fun ref setMessageHandler(callback: @{(HWND, UINT, WPARAM, LPARAM): LRESULT}) =>
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
        
        if _settings.width > 0 then
            _settings.widthPixels = (parentWidth.f32() * (_settings.width.f32() / 100.0)).i32()
            
            if (_settings.widthMin > 0) and (_settings.widthPixels < _settings.widthMin) then
                _settings.widthPixels = _settings.widthMin
            end
            
            if (_settings.widthMax > 0) and (_settings.widthPixels < _settings.widthMax) then
                _settings.widthPixels = _settings.widthMax
            end
        end
        
        if _settings.height > 0 then
            _settings.heightPixels = (parentHeight.f32() * (_settings.height.f32() / 100.0)).i32()

            if (_settings.heightMin > 0) and (_settings.heightPixels < _settings.heightMin) then
                _settings.heightPixels = _settings.heightMin
            end

            if (_settings.heightMax > 0) and (_settings.heightPixels < _settings.heightMax) then
                _settings.heightPixels = _settings.heightMax
            end
        end
        
        _settings.x = (parentWidth - _settings.widthPixels) / 2
        _settings.y = (parentHeight - _settings.heightPixels) / 2