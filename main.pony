use "debug"
use "win32"
use "winApp"

actor Main
    new create(env: Env) =>
        let win = Window(WindowSettings.simple(80, 60, "Hello World"))
        
        win.setMessageHandler(this~handle())
        
        try
            win.init() ?
        else
            env.out.print(win.getError())
        end
    
    fun @handle(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =>
        match msg
        | WMDESTROY() =>
            PostQuitMessage(0)
            0
        else
            DefWindowProcW(hWnd, msg, wParam, lParam)
        end
    