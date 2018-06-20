use "lib:user32" if windows
use "debug"

// Data Types

type ATOM      is WORD

// conflicts with Pony's internal type
// and so we specify I32 directly in the code
// type BOOL      is I32

type DWORD     is U32
type HANDLE    is PVOID
type HBRUSH    is HANDLE
type HICON     is HANDLE
type HCURSOR   is HICON
type HINSTANCE is HANDLE
type HMENU     is HANDLE
type HWND      is HANDLE
type INTPTR    is I64
type LONG      is I32
type LONGPTR   is I64
type LPARAM    is LONGPTR
type LPCSTR    is Pointer[U8] tag

// use LPCWSTR when Pony supports WCHAR
// and move to CreateWindowExW too
type LPCTSTR   is LPCSTR

type LPCWSTR   is WCHAR
type LRESULT   is LONGPTR
type LPVOID    is Pointer[U8] tag
type PVOID     is Pointer[U8] tag
type UINT      is U32
type UINTPTR   is U64
type VOID      is None
type WCHAR     is Pointer[U16] tag
type WORD      is U16
type WPARAM    is UINTPTR

// Constants - Colors

primitive COLOR3DFACE
    fun apply(): I32 => 15

// Constants - Cursors

primitive IDCARROW
    fun apply(): I32 => 32512

// Constants - System Metrics

primitive SMCXSCREEN
    fun apply(): I32 => 0

primitive SMCYSCREEN
    fun apply(): I32 => 1

// Constants - Window Messages

primitive WMCLOSE
    fun apply(): UINT => 0x0010

primitive WMDESTROY
    fun apply(): UINT => 0x0002

primitive WMNULL
    fun apply(): UINT => 0x0000

primitive WMPAINT
    fun apply(): UINT => 0x000f

// Constants - Window Styles

primitive WSCAPTION
    fun apply(): DWORD => 0x00C00000

primitive WSMAXIMIZEBOX
    fun apply(): DWORD => 0x00010000

primitive WSMINIMIZEBOX
    fun apply(): DWORD => 0x00020000

primitive WSOVERLAPPED
    fun apply(): DWORD => 0x00000000

primitive WSOVERLAPPEDWINDOW
    fun apply(): DWORD => WSOVERLAPPED() or WSCAPTION() or WSSYSMENU() or 
                          WSTHICKFRAME() or WSMINIMIZEBOX() or WSMAXIMIZEBOX()

primitive WSSYSMENU
    fun apply(): DWORD => 0x00080000

primitive WSTHICKFRAME
    fun apply(): DWORD => 0x00040000

// Constants - Window Styles Extended

primitive WSEXAPPWINDOW
    fun apply(): DWORD => 0x00040000

// Structs

struct MSG
    var hwnd: HWND = HWND
    var message: UINT = 0
    var wParam: WPARAM = 0
    var lParam: LPARAM = 0
    var time: DWORD = 0
    var pt: POINT = POINT
    
    new create() => None

struct POINT
    var x: LONG = 0
    var y: LONG = 0
    
    new create() => None

// we use WNDCLASS instead of WNDCLASSEX because
// there is no way to set cbSize in Pony
struct WNDCLASS
    var style: UINT = 0
    
    var lpfnWndProc: @{(HWND, UINT, WPARAM, LPARAM): LRESULT} = 
        @{(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT => 0}
    
    var cbClsExtra: I32 = 0
    var cbWndExtra: I32 = 0
    var hInstance: HINSTANCE = HINSTANCE
    var hIcon: HICON = HICON
    var hCursor: HCURSOR = HCURSOR
    var hbrBackground: HBRUSH = HBRUSH
    var lpszMenuName: LPCTSTR = LPCTSTR
    var lpszClassName: LPCTSTR = LPCTSTR
    
    new create() => None

// Functions

primitive CreateWindowExA
    fun @apply(dwExStyle: DWORD, lpClassName: ATOM /* LPCTSTR */, lpWindowName: LPCTSTR, dwStyle: DWORD, x: I32, y: I32, 
               nWidth: I32, nHeight: I32, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPVOID): HWND =>
        @CreateWindowExA[HWND](dwExStyle, lpClassName, lpWindowName, dwStyle, x, y, 
                               nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam)

primitive DefWindowProcW
    fun @apply(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM): LRESULT =>
        @DefWindowProcW[LRESULT](hWnd, msg, wParam, lParam)

primitive DispatchMessageW
    fun @apply(lpMsg: MaybePointer[MSG]): LRESULT =>
        @DispatchMessageW[LRESULT](lpMsg)

primitive GetLastError
    fun @apply(): DWORD =>
        @GetLastError[DWORD]()

primitive GetMessageW
    fun @apply(lpMsg: MaybePointer[MSG], hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT): I32 /* BOOL */ =>
        @GetMessageW[I32](lpMsg, hWnd, wMsgFilterMin, wMsgFilterMax)

primitive GetSysColorBrush
    fun @apply(color: I32): HBRUSH =>
        @GetSysColorBrush[HBRUSH](color)

primitive GetSystemMetrics
    fun @apply(nIndex: I32): I32 =>
        @GetSystemMetrics[I32](nIndex)

primitive LoadCursorW
    fun @apply(hInstance: HINSTANCE, lpCursorName: I32 /* LPCTSTR */): HCURSOR =>
        @LoadCursorW[HCURSOR](hInstance, lpCursorName)

primitive PostQuitMessage
    fun @apply(nExitCode: I32): VOID =>
        @PostQuitMessage[VOID](nExitCode)

primitive RegisterClassW
    fun @apply(lpWndClass: MaybePointer[WNDCLASS]): ATOM =>
        @RegisterClassW[ATOM](lpWndClass)

primitive ShowWindow
    fun @apply(hWnd: HWND, nCmdShow: I32): I32 /* BOOL */ =>
        @ShowWindow[I32](hWnd, nCmdShow)

primitive TranslateMessage
    fun @apply(lpMsg: MaybePointer[MSG]): I32 /* BOOL */ =>
        @TranslateMessage[I32](lpMsg)
