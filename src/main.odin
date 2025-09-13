package main

import    "core:fmt"
import    "core:mem"
import    "core:time"
import sdl "vendor:sdl3"
import en "engine"

TITLE         :: "Breakout"
SCREEN_WIDTH  :: 960
SCREEN_HEIGHT :: 960

SPRITE_VERTEX_SHADER   :: "assets/shaders/sprite.vert"
SPRITE_FRAGMENT_SHADER :: "assets/shaders/sprite.frag"

Game_State :: enum {
    Active,
    Menu,
    Win,
}

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

    // /arena
    en.arena_allocate(); defer en.destroy_arena()

    // en.set_window_flags({.RESIZABLE, .MAXIMIZED})
    en.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT); defer en.close_window()

    screen_width, screen_height := en.get_window_size_f32()

    en.init_renderer(); defer en.destroy_renderer()

    sprite := en.load_shader(SPRITE_VERTEX_SHADER, SPRITE_FRAGMENT_SHADER)
    defer en.unload_shader(sprite)

    face        := en.load_texture("assets/textures/face.png")
    paddle      := en.load_texture("assets/textures/paddle.png")
    block       := en.load_texture("assets/textures/block.png",       false)
    block_solid := en.load_texture("assets/textures/block_solid.png", false)
    background  := en.load_texture("assets/textures/background.jpg",  false)

    defer en.unload_texture(&face)
    defer en.unload_texture(&paddle)
    defer en.unload_texture(&block)
    defer en.unload_texture(&block_solid)
    defer en.unload_texture(&background)

    levels := load_levels(&block_solid, &block)
    select_level = .One


    player := setup_player(&paddle, 150, 30, 800, screen_width, screen_height)
    ball   := setup_ball(&face, 50, 800, &player)

    game_state := Game_State.Active

    last_time: f32
    start_tick := time.tick_now()
    main_loop: for {
        current_time := f32(time.duration_seconds(time.tick_since(start_tick)))
        delta_time   := current_time - last_time
        last_time     = current_time

        en.process_event()
        key_state := sdl.GetKeyboardState(nil)

        if en.window_should_close() do break main_loop

        if en.window_resized() {
            screen_width, screen_height = en.get_window_size_f32()
            player = setup_player(&paddle, 150, 30, 800, screen_width, screen_height)

            update_level(&levels[int(select_level)], screen_width, screen_height)
        }

        switch game_state {
        case .Active :
            vel: f32
            if key_state[i32(sdl.Scancode.A)] do vel = -1
            if key_state[i32(sdl.Scancode.D)] do vel =  1

            player.pos.x += vel * player.speed * delta_time

            if player.pos.x < 0 do player.pos.x = 0
            if player.pos.x > screen_width - player.size.x do player.pos.x = screen_width - player.size.x

            ball.pos.x = player.pos.x + (player.size.x - ball.size.x) / 2

        case .Menu:
        case .Win:
        }

        // /draw
        en.clear_background({0, 25, 38, 255})
        defer en.swap_window()

        switch game_state {
        case .Active :
            en.set_current_shader(sprite)
            en.draw_sprite(background, {0, 0}, {screen_width, screen_height}, 0, {100, 100, 155, 255})

            en.draw_sprite(player.sprite, player.pos, player.size, 0)
            en.draw_sprite(ball.sprite, ball.pos, ball.size, 0)

            draw_level(&levels[int(select_level)])
        case .Menu:
        case .Win:
        }
   }
}

setup_player :: proc(texture: ^en.Texture, width, height, speed, screen_width, screen_height: f32) -> Entity {
    x := (screen_width - width) / 2
    y := screen_height - height * 1.5

    return Entity {
        pos    = {x, y},
        size   = {width, height},
        speed  = speed,
        sprite = texture^,
    }
}

setup_ball :: proc(texture: ^en.Texture, size, speed: f32, player: ^Entity) -> Entity {
    x := player.pos.x + (player.size.x - size) / 2
    y := player.pos.y - size

    return Entity {
        pos    = {x, y},
        size   = {size, size},
        speed  = speed,
        sprite = texture^,
    }
}
