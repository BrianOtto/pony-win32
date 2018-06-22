/*
 * Copyright 2018 Brian Otto @ https://www.patreon.com/botto
 * Please see the ISC License in LICENSE
 *
 * Warning ! This must be compiled with: ponyc -d
 *
 * Otherwise the optimizations will cause an ERROR_NOACCESS (998).
 * I believe this is a bug with the LLVM optimizations that ponyc does,
 * but I haven't been able to track down the exact cause yet.
 * The issue will sometimes go away when the code structure changes.
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
        let win = Window(WindowSettings.simple(80, 60, "Hello World"))
        
        win.setMessageHandler(this~handle())
        
        try
            win.init() ?
        else
            env.out.print(win.getError())
        end
    
    fun @handle(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =>
        match msg
        | WMPAINT() =>
            Message.onPaint(hWnd, wParam, lParam)
        | WMDESTROY() =>
            PostQuitMessage(0)
        else
            return DefWindowProcW(hWnd, msg, wParam, lParam)
        end
        
        0

class Message
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
    