package engine

import gl  "vendor:OpenGL"

Color :: struct {
    r, g, b, a: u8,
}

normalize_color :: proc(color: Color) -> [4]f32 {
    return {
        f32(color.r) / 255,
        f32(color.g) / 255,
        f32(color.b) / 255,
        f32(color.a) / 255,
    }
}

clear_background :: proc(color: Color) {
    c := normalize_color(color)

    gl.ClearColor(c.x, c.y, c.z, c.w)
    gl.Clear(gl.COLOR_BUFFER_BIT)
}
