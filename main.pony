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
                Event.buttonClick()
            end
        | WMCREATE() =>
            Message.onCreate(hWnd, wParam, lParam)
        | WMPAINT() =>
            Message.onPaint(hWnd, wParam, lParam)
        | WMDESTROY() =>
            PostQuitMessage(0)
        else
            return DefWindowProcA(hWnd, msg, wParam, lParam)
        end
        
        0

class Message
    fun onCreate(hWnd: HWND, wParam: WPARAM, lParam: LPARAM): None =>
        Window(WindowSettings.control(10, 5, hWnd, "button", 100, "Click Me")).init()
        
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

class Event
    fun buttonClick(): None =>
        Debug.out("The button was clicked")