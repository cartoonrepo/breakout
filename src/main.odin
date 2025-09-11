package main

import    "core:fmt"
import    "core:os"
import    "core:mem"
import en "engine"

import vmem "core:mem/virtual"
import "base:runtime"

TITLE         :: "Breakout"
SCREEN_WIDTH  :: 960
SCREEN_HEIGHT :: 960

SPRITE_VERTEX_SHADER   :: "assets/shaders/sprite.vert"
SPRITE_FRAGMENT_SHADER :: "assets/shaders/sprite.frag"

BRICK_COLOR_1 :: en.Color {220, 220, 200, 255}
BRICK_COLOR_2 :: en.Color {50, 100, 220, 255}
BRICK_COLOR_3 :: en.Color {0, 220, 100, 255}
BRICK_COLOR_4 :: en.Color {220, 220, 100, 255}
BRICK_COLOR_5 :: en.Color {220, 140, 0, 255}

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

    arena := arena_allocate()
    arena_alloc := vmem.arena_allocator(&arena)
    defer	vmem.arena_destroy(&arena)

    // en.set_window_flags({.RESIZABLE, .MAXIMIZED})
    en.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT); defer en.close_window()

    en.init_renderer(); defer en.destroy_renderer()

    sprite := en.load_shader(SPRITE_VERTEX_SHADER, SPRITE_FRAGMENT_SHADER)
    defer en.unload_shader(sprite)

    face        := en.load_texture("assets/textures/face.png")
    block       := en.load_texture("assets/textures/block.png", false)
    block_solid := en.load_texture("assets/textures/block_solid.png", false)
    paddle      := en.load_texture("assets/textures/paddle.png")
    background  := en.load_texture("assets/textures/background.jpg", false)

    defer en.unload_texture(&face)
    defer en.unload_texture(&block)
    defer en.unload_texture(&paddle)
    defer en.unload_texture(&background)

    levels := load_levels(block_solid, block, &arena_alloc)
    select_level = .Three

    main_loop: for {
        en.process_event()
        if en.window_should_close() do break main_loop

        en.clear_background({0, 25, 38, 255})
        defer en.swap_window()

        en.set_current_shader(sprite)

        w, h := en.get_window_size_f32()
        en.draw_sprite(background, {0, 0}, {w, h}, 0, {200, 200, 255, 255})

        draw_levels(select_level, &levels)
    }
}

arena_allocate :: proc() -> (vmem.Arena) {
    arena: vmem.Arena
    arena_err := vmem.arena_init_growing(&arena)
    ensure(arena_err == nil)

	return arena
}
