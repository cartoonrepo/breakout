package engine

import      "core:fmt"
import glm  "core:math/linalg/glsl"
import gl   "vendor:OpenGL"
import stbi "vendor:stb/image"

Vertex :: struct {
    position  : glm.vec2,
    tex_coord : glm.vec2,
}

Shader :: struct {
    id       : u32,
    uniforms : map[string]gl.Uniform_Info,
}

Texture :: struct {
    id              : u32,
    width           : i32,
    height          : i32,
    internal_format : i32,
    image_format    : u32,
}

Renderer :: struct {
    vao, vbo, ebo  : u32,
    default_shader : Shader,
    current_shader : Shader,
}

Color :: struct {
    r, g, b, a: u8,
}

// /renderer
@(private)
renderer: Renderer

init_renderer :: proc() {
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    init_render_data()

    // TODO: check for default shader files.
    default_shader := load_shader("assets/shaders/default.vert", "assets/shaders/default.frag")

    renderer.default_shader = default_shader
    renderer.current_shader = default_shader
}

destroy_renderer :: proc() {
    r := renderer

    unload_shader(r.default_shader)

    gl.DeleteVertexArrays(1, &r.vao)
    gl.DeleteBuffers(1, &r.vbo)
    gl.DeleteBuffers(1, &r.ebo)
}

init_render_data :: proc() {
    r := &renderer

    vertices := []Vertex {
        {{0.0, 1.0}, {0.0, 1.0}}, // TOP    LEFT
        {{1.0, 1.0}, {1.0, 1.0}}, // TOP    RIGHT
        {{1.0, 0.0}, {1.0, 0.0}}, // BOTTOM RIGHT
        {{0.0, 0.0}, {0.0, 0.0}}, // BOTTOM LEFT
    }

    indices := []u32 {0, 1, 2, 2, 3, 0}

    gl.GenVertexArrays(1, &r.vao)
    gl.GenBuffers(1, &r.vbo)
    gl.GenBuffers(1, &r.ebo)

    gl.BindVertexArray(r.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER,         r.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, r.ebo)

    gl.BufferData(gl.ARRAY_BUFFER,         len(vertices) * size_of(vertices[0]), raw_data(vertices[:]), gl.STATIC_DRAW)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(indices)  * size_of(indices[0]),  raw_data(indices[:]),  gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(0, i32(len(vertices[0].position)),  gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(vertices[0].tex_coord)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, tex_coord))

    gl.BindVertexArray(0)
    gl.BindBuffer(gl.ARRAY_BUFFER, 0)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0)
}

// /shader
load_shader :: proc(vertex_shader, fragment_shader: string) -> (shader: Shader) {
    program_id, ok := gl.load_shaders_file(vertex_shader, fragment_shader)
    if !ok {
        fmt.println("shader compilation failed.")
        when gl.GL_DEBUG {
            fmt.eprintln(gl.get_last_error_message())
        }
    }

    shader.id       = program_id
    shader.uniforms = gl.get_uniforms_from_program(program_id)

    return
}

unload_shader :: proc(shader: Shader) {
    // NOTE: we are not checking if shader exits or not
    gl.destroy_uniforms(shader.uniforms)
}

set_current_shader :: #force_inline proc(shader: Shader) {
    renderer.current_shader.id = shader.id
}

clear_shader :: #force_inline proc() {
    renderer.current_shader.id = renderer.default_shader.id
}

// /texture
load_texture :: proc(file: cstring, alpha: bool = true) -> (texture: Texture) {
    width, height, channels: i32
    data := stbi.load(file, &width, &height, &channels, 0)
    defer stbi.image_free(data)

    if data == nil {
        // NOTE: we return 0 texture id, (black texture)
        fmt.printfln("ERROR: Failed to load texture: %v", file)
        return
    }

    texture.width  = width
    texture.height = height

    if alpha {
        texture.internal_format = gl.RGBA
        texture.image_format    = gl.RGBA
    } else {
        texture.internal_format = gl.RGB
        texture.image_format    = gl.RGB
    }

    gl.GenTextures(1, &texture.id)
    gl.BindTexture(gl.TEXTURE_2D, texture.id)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    gl.TexImage2D(gl.TEXTURE_2D, 0, texture.internal_format, width, height, 0, texture.image_format, gl.UNSIGNED_BYTE, data)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    return
}

unload_texture :: proc(texture: ^Texture) {
    gl.DeleteTextures(1, &texture.id)
}

// /sprite
@(private)
set_projection :: #force_inline proc(shader: u32, width, height: f32) {
    // NOTE: i like top-left(0,0) coordinate system.
    projection := glm.mat4Ortho3d(0, width, height, 0, -1.0, 1.0)
    gl.UniformMatrix4fv(gl.GetUniformLocation(shader, "projection"),  1, false, &projection[0, 0])
}

draw_sprite :: proc(texture: Texture, position, size: glm.vec2, rotate: f32, color: Color = {255, 255, 255, 255}) {
    r := &renderer

    gl.UseProgram(r.current_shader.id)

    p := position + size * 0.5
    model := glm.mat4Translate({p.x, p.y, 0})
    model *= glm.mat4Rotate({0, 0, -1}, glm.radians(rotate))
    model *= glm.mat4Translate({size.x * -0.5, size.y * -0.5, 0.0})
    model *= glm.mat4Scale({size.x, size.y, 0})

    gl.UniformMatrix4fv(gl.GetUniformLocation(r.current_shader.id, "model"),  1, false, &model[0, 0])

    c := normalize_color(color)
    gl.Uniform4fv(gl.GetUniformLocation(r.current_shader.id, "color"), 1, raw_data(c[:]))

    w, h := get_window_size_f32()
    set_projection(renderer.current_shader.id, w, h)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture.id)

    gl.BindVertexArray(r.vao)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)
}

draw_quad :: proc(position, size: glm.vec2, rotate: f32, color: Color = {255, 255, 255, 255}) {
    r := &renderer

    gl.UseProgram(r.current_shader.id)

    p := position + size * 0.5
    model := glm.mat4Translate({p.x, p.y, 0})
    model *= glm.mat4Rotate({0, 0, -1}, glm.radians(rotate))
    model *= glm.mat4Translate({size.x * -0.5, size.y * -0.5, 0.0})
    model *= glm.mat4Scale({size.x, size.y, 0})

    gl.UniformMatrix4fv(gl.GetUniformLocation(r.current_shader.id, "model"),  1, false, &model[0, 0])

    c := normalize_color(color)
    gl.Uniform4fv(gl.GetUniformLocation(r.current_shader.id, "color"), 1, raw_data(c[:]))

    w, h := get_window_size_f32()
    set_projection(renderer.current_shader.id, w, h)

    gl.BindVertexArray(r.vao)
    gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)
}

// /utils
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

gl_viewport_resize :: proc(width, height: i32) {
    gl.Viewport(0, 0, width, height)
}
