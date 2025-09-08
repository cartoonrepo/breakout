package main

import "core:fmt"
import "core:mem"

import sdl "vendor:sdl3"
import en  "engine"

TITLE         :: "Breakout"
SCREEN_WIDTH  :: 1280
SCREEN_HEIGHT :: 720

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

    // en.set_window_flags({.RESIZABLE, .MAXIMIZED})
    en.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT); defer en.close_window()

    main_loop: for {
        en.process_event()
        if en.window_should_close() do break main_loop

        en.clear_background({0, 25, 38, 255})
        en.swap_window()
    }
}
