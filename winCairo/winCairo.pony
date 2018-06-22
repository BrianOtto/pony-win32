use "lib:winCairo/cairo" if windows

// Structs

struct CairoSurfaceT
    new create() => None

struct CairoT
    new create() => None

// Functions

primitive CairoCreate
    fun @apply(target: CairoSurfaceT): CairoT =>
        @cairo_create[CairoT](target)

primitive CairoDestroy
    fun @apply(cr: CairoT): None =>
        @cairo_destroy[None](cr)

primitive CairoFill
    fun @apply(cr: CairoT): None =>
        @cairo_fill[None](cr)

primitive CairoRectangle
    fun @apply(cr: CairoT, x: F64, y: F64, width: F64, height: F64): None =>
        @cairo_rectangle[None](cr, x, y, width, height)

primitive CairoSetLineWidth
    fun @apply(cr: CairoT, width: F64): None =>
        @cairo_set_line_width[None](cr, width)

primitive CairoSetSourceRgb
    fun @apply(cr: CairoT, red: F64, green: F64, blue: F64): None =>
        @cairo_set_source_rgb[None](cr, red, green, blue)

primitive CairoStrokePreserve
    fun @apply(cr: CairoT): None =>
        @cairo_stroke_preserve[None](cr)

primitive CairoSurfaceDestroy
    fun @apply(surface: CairoSurfaceT): None =>
        @cairo_surface_destroy[None](surface)

primitive CairoWin32SurfaceCreate
    fun @apply(hdc: Pointer[U8] tag): CairoSurfaceT =>
        @cairo_win32_surface_create[CairoSurfaceT](hdc)
