package engine

import     "core:fmt"
import     "core:os"
import sdl "vendor:sdl3"
import gl  "vendor:OpenGL"

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

@(private)
Context :: struct {
    width, height : i32,
    window        : ^sdl.Window,
    window_flags  : sdl.WindowFlags,
    gl_context    : sdl.GLContext,
    should_close  : bool,
    resized       : bool,
}

@(private)
ctx : Context

set_window_flags :: proc(flags: sdl.WindowFlags) {
    ctx.window_flags = flags
}

init_window :: proc(title: cstring, width, height: i32) {
    if !sdl.Init({.VIDEO}) {
        fmt.eprintfln("Failed to initialzed SDL: %v", sdl.GetError())
    }

    // set opengl attributes
    sdl.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(sdl.GL_CONTEXT_PROFILE_CORE))
    sdl.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, GL_VERSION_MAJOR)
    sdl.GL_SetAttribute(.CONTEXT_MINOR_VERSION, GL_VERSION_MINOR)

    ctx.window_flags |= {.OPENGL}

    ctx.window = sdl.CreateWindow(title, width, height, ctx.window_flags)
    if ctx.window == nil {
        fmt.eprintfln("Failed to create window: %v", sdl.GetError())
        os.exit(1)
    }

    ctx.gl_context = sdl.GL_CreateContext(ctx.window)
    if ctx.gl_context == nil {
        fmt.eprintfln("Failed to create OpenGL context: %v", sdl.GetError())
        os.exit(1)
    }

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, sdl.gl_set_proc_address)

    gl_viewport_resize(ctx.width, ctx.height)

    when ODIN_DEBUG {
        log_opengl_info()
    }
}

log_opengl_info :: proc() {
    fmt.println("OpenGL loaded")
    fmt.printfln("VENDOR   : %v", gl.GetString(gl.VENDOR))
    fmt.printfln("RENDERER : %v", gl.GetString(gl.RENDERER))
    fmt.printfln("VERSION  : %v", gl.GetString(gl.VERSION))
    fmt.printfln("GLSL     : %v", gl.GetString(gl.SHADING_LANGUAGE_VERSION))
}

close_window :: proc() {
    sdl.GL_DestroyContext(ctx.gl_context)
    sdl.DestroyWindow(ctx.window)
    sdl.Quit()
}

process_event :: proc() {
    ctx.resized = false
    event: sdl.Event
    for sdl.PollEvent(&event) {
        #partial switch event.type {
        case .QUIT:
            ctx.should_close = true
        case .KEY_DOWN:
            #partial switch event.key.scancode {
            case .ESCAPE:
                ctx.should_close = true
            }
        case .WINDOW_PIXEL_SIZE_CHANGED:
            ctx.resized = true
            sdl.GetWindowSizeInPixels(ctx.window, &ctx.width, &ctx.height)
            gl_viewport_resize(ctx.width, ctx.height)
        }
    }
}

window_should_close :: #force_inline proc() -> bool {
    return ctx.should_close
}

swap_window :: #force_inline proc() {
    sdl.GL_SwapWindow(ctx.window)
}

get_window_size_f32 :: #force_inline proc() -> (f32, f32){
    return f32(ctx.width), f32(ctx.height)
}

window_resized :: #force_inline proc() -> bool {
    return ctx.resized
}
