/*
 * Copyright 2018 Brian Otto @ https://www.patreon.com/botto
 * Please see the ISC License in LICENSE
 *
 * Remember to copy winCairo/cario.dll to the location of your executable!
 *
 */

use "debug"
use "win32"
use "winApp"
use "winCairo"

actor Main
    new create(env: Env) =>
        let win = Window(WindowSettings.window(80, 60, "Hello World"))
        
        win.setMessageHandler(this~handle())
        
        if win.init() > 0 then
            env.out.print(win.getError())
        end
    
    fun @handle(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =>
        match msg
        | WMCOMMAND() =>
            if LOWORD(wParam.u32()) == 100 then
                Event.buttonClick(hWnd, wParam, lParam)
            end
        | WMCREATE() =>
            Message.onCreate(hWnd, wParam, lParam)
        | WMPAINT() =>
            Message.onPaint(hWnd, wParam, lParam)
        | WMDESTROY() =>
            PostQuitMessage(0)
        else
            return DefWindowProcW(hWnd, msg, wParam, lParam)
        end
        
        0

primitive Message
    fun onCreate(hWnd: HWND, wParam: WPARAM, lParam: LPARAM): None =>
        let button = Window(WindowSettings.control(200, 30, hWnd, "button", 100, "Click Me")).>init()
        let buttonSettings = button.getSettings()
        
        let txtFld = Window(WindowSettings.control(200, 30, hWnd, "edit", 101, "Enter text ...")).>init()
        let txtFldSettings = txtFld.getSettings()
        
        txtFldSettings.y = txtFldSettings.y - 50
        txtFld.setSettings(txtFldSettings)
        
        // We can't store a lookup of all window handles because @handle doesn't 
        // have access to this and Pony doesn't allow us to use global variables.
        // To get around this we store the handle of the txtFld window inside the
        // button window so that it can be accessed when the button is clicked.
        // Other alternatives would be to use FindWindowEx or EnumChildWindows or 
        // possibly the global variables available in Thread local Storage
        SetWindowLongPtrW(buttonSettings.handle, GWLPUSERDATA(), txtFldSettings.handle)
        
    fun onPaint(hWnd: HWND, wParam: WPARAM, lParam: LPARAM): None =>
        var ps: PAINTSTRUCT ref = PAINTSTRUCT
        
        var hdc = BeginPaint(hWnd, MaybePointer[PAINTSTRUCT](ps))
        
        var surface = CairoWin32SurfaceCreate(hdc)
        var cr = CairoCreate(surface)
        
        CairoSetSourceRgb(cr, 0.235, 0.569, 0.902)
        CairoSetLineWidth(cr, 1)

        CairoRectangle(cr, 20, 20, 200, 100)
        CairoStrokePreserve(cr)
        CairoFill(cr)
        
        CairoDestroy(cr)
        CairoSurfaceDestroy(surface)
        
        EndPaint(hWnd, MaybePointer[PAINTSTRUCT](ps))

primitive Event
    fun buttonClick(hWnd: HWND, wParam: WPARAM, lParam: LPARAM): None =>
        Debug.out("The button was clicked")
        
        let txtFldHandle = GetWindowLongPtrW(lParam, GWLPUSERDATA())
        
        let txtFldMax: USize = 20
        
        // allocate a buffer for the text
        var txtFldVal = Util.wideCharBuffer(txtFldMax)
        
        // populate the buffer with the window's text
        GetWindowTextW(txtFldHandle, txtFldVal.cpointer(), txtFldMax.i32())
        
        Debug.out(Util.wideCharToString(txtFldVal))
        
        