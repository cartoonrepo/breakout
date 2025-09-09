package main

import    "core:fmt"
import    "core:mem"
import en "engine"

TITLE         :: "Breakout"
SCREEN_WIDTH  :: 1280
SCREEN_HEIGHT :: 720

SPRITE_VERTEX_SHADER   :: "assets/shaders/sprite.vert"
SPRITE_FRAGMENT_SHADER :: "assets/shaders/sprite.frag"

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
                }
            }
            if len(track.bad_free_array) > 0 {
                fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
                for entry in track.bad_free_array {
                    fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    en.set_window_flags({.RESIZABLE, .MAXIMIZED})
    en.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT); defer en.close_window()

    en.init_renderer(); defer en.destroy_renderer()

    sprite := en.load_shader(SPRITE_VERTEX_SHADER, SPRITE_FRAGMENT_SHADER)
    defer en.unload_shader(sprite)

    face        := en.load_texture("assets/textures/face.png")
    block       := en.load_texture("assets/textures/block.png")
    paddle      := en.load_texture("assets/textures/paddle.png")
    background  := en.load_texture("assets/textures/background.jpg", false)

    defer en.unload_texture(&face)
    defer en.unload_texture(&block)
    defer en.unload_texture(&paddle)
    defer en.unload_texture(&background)

    rot: f32
    main_loop: for {
        en.process_event()
        if en.window_should_close() do break main_loop

        en.clear_background({0, 25, 38, 255})

        w, h := en.get_window_size_f32()

        rot += 1
        if rot > 360 do rot = 0

        en.set_current_shader(sprite)
        en.draw_sprite(background, {w * 0.5, h * 0.5}, {w, h}, 0, {200, 200, 255, 255})

        en.draw_sprite(face,  {200, 200}, {100, 100}, rot)
        en.draw_sprite(block, {600, 600}, {100, 100}, 0)

        en.draw_sprite(paddle, {500, 300}, {200, 50}, rot)

        en.clear_shader() // sets default shader
        en.draw_quad({400, 620}, {100, 100}, rot, {50, 150, 255, 255})
        en.draw_quad({600, 100}, {100, 100}, rot)

        en.swap_window()
    }
}
