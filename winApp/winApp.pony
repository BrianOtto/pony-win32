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
        var windowClassName: LPCWSTR = LPCWSTR
        var windowClassInstance: HINSTANCE = HINSTANCE
        
        if _settings.style.systemClass == "" then
            var windowClass: WNDCLASSW ref = WNDCLASSW
            windowClass.lpfnWndProc = _messageHandler
            windowClass.hCursor = LoadCursorW(HINSTANCE, _settings.style.cursor)
            windowClass.hbrBackground = GetSysColorBrush(_settings.style.backgroundColor)
            windowClass.lpszClassName = Util.stringToWideChar("winApp").cpointer() // TODO: use a random name
            
            let windowClassAtom = RegisterClassW(MaybePointer[WNDCLASSW](windowClass))
            
            if windowClassAtom == 0 then
                return _setError("RegisterClassW")
            end
            
            windowClassName = windowClass.lpszClassName
            windowClassInstance = windowClass.hInstance
        else
            windowClassName = Util.stringToWideChar(_settings.style.systemClass).cpointer()
        end
        
        setCoordinates()
        
        var windowTitle = Util.stringToWideChar(_settings.title).cpointer()
        var windowMenu = (_settings.menuId, _settings.menuHandle)
        
        let windowHandle = 
            CreateWindowExW(WSEXAPPWINDOW(), windowClassName, windowTitle, _settings.style.systemStyle, 
                            _settings.x, _settings.y, _settings.width, _settings.height, 
                            _settings.parent, windowMenu, windowClassInstance, LPVOID)
        
        if windowHandle.is_null() then
            return _setError("CreateWindowExA")
        end
        
        _settings.handle = windowHandle
        
        ShowWindow(windowHandle, I32(1))
        
        if _settings.style.systemClass == "" then
            var msg: MSG ref = MSG
            var ret: I32 = 0
            
            repeat
                ret = GetMessageW(MaybePointer[MSG](msg), windowHandle, UINT(0), UINT(0))
                
                if ret == -1 then
                    if msg.wParam != 0 then
                        return _setError("GetMessageW")
                    end
                else
                    TranslateMessage(MaybePointer[MSG](msg))
                    DispatchMessageW(MaybePointer[MSG](msg))
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

primitive Util
    fun stringToWideChar(s: String): Array[U16] =>
        // get the size of the buffer required for the wide char
        var wcLength = MultiByteToWideChar(CPUTF8(), 0, s.cpointer(), s.size().i32(), Pointer[U16], 0)
        
        // create a U16 buffer for the wide char by allocating space in a pointer
        var wcString = wideCharBuffer(wcLength.usize())
        
        MultiByteToWideChar(CPUTF8(), 0, s.cpointer(), s.size().i32(), wcString.cpointer(), wcLength)
        
        wcString
    
    fun wideCharToString(wcString: Array[U16]): String =>
        // get the size of the buffer required for the string
        var csLength = WideCharToMultiByte(CPUTF8(), 0, wcString.cpointer(), wcString.size().i32(), Pointer[U8], 0, 
                                           Pointer[U8], Pointer[U8])
        
        // create a U8 buffer for the string by allocating space in a pointer
        // This must be done inside a recover so that we can retrieve a val 
        // for the from_array() conversion that gets returned
        var csString = recover val
            var csStringAsRef = Array[U8].from_cpointer(Pointer[U8], csLength.usize(), csLength.usize())
            try csStringAsRef.>push(0).>pop()? end // see the note in wideCharBuffer()
            csStringAsRef
        end
        
        WideCharToMultiByte(CPUTF8(), 0, wcString.cpointer(), wcString.size().i32(), csString.cpointer(), csLength, 
                            Pointer[U8], Pointer[U8])
        
        String.from_array(csString)
    
    fun wideCharBuffer(size: USize): Array[U16] =>
        // create a U16 buffer for the wide char by allocating space in a pointer
        var wcString = Array[U16].from_cpointer(Pointer[U16], size, size)
        
        // push a NULL terminator onto the buffer and then reduce the size by one to keep the original length
        // I don't know why this is necessary and using other array functions causes the Window to crash
        try wcString.>push(0).>pop()? end
        
        wcString