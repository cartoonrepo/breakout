package main

import    "core:fmt"
import    "core:mem"
import    "core:time"
import    "core:math/rand"
import sdl "vendor:sdl3"
import en "engine"

TITLE         :: "Breakout"
SCREEN_WIDTH  :: 960
SCREEN_HEIGHT :: 960

SPRITE_VERTEX_SHADER   :: "assets/shaders/sprite.vert"
SPRITE_FRAGMENT_SHADER :: "assets/shaders/sprite.frag"

BALL_RADIUS   :: 32
BALL_SPEED    :: 400
BALL_ROTATION :: 8

PLAYER_WIDTH  :: 150
PLAYER_HEIGHT :: 30
PLAYER_SPEED  :: 600

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
    en.set_vsync(1)

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

    game_state := Game_State.Active

    // /level
    levels := load_levels(&block_solid, &block)
    select_level = .One

    // /player
    player := setup_player(&paddle, PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_SPEED, screen_width, screen_height)
    ball   := setup_ball(&face, BALL_RADIUS, BALL_SPEED, &player)

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
            player = setup_player(&paddle, PLAYER_WIDTH, PLAYER_HEIGHT, PLAYER_SPEED, screen_width, screen_height)
            update_level(&levels[int(select_level)], screen_width, screen_height)
        }

        switch game_state {
        case .Active :
            // /player
            player.vel.x = 0
            if key_state[i32(sdl.Scancode.A)] do player.vel.x = -1
            if key_state[i32(sdl.Scancode.D)] do player.vel.x =  1

            player.pos.x += player.vel.x * player.speed * delta_time

            if player.pos.x < 0 {
                player.pos.x = 0
            }

            if player.pos.x > screen_width - player.size.x {
                player.pos.x = screen_width - player.size.x
            }

            // /ball
            if ball.stuck {
                ball.pos.x = player.pos.x + (player.size.x - ball.size.x) / 2 // move ball with player
                ball.rotation = 0

                if key_state[i32(sdl.Scancode.SPACE)] {
                    if player.vel.x != 0 {
                        ball.vel.x = player.vel.x
                    } else {
                        ball.vel.x = rand.float32_range(-1, 1)
                    }

                    ball.vel.y = -1 // always up direction
                    ball.stuck = false
                }
            }

            // right-left wall collision
            if ball.pos.x + ball.size.x >= screen_width || ball.pos.x <= 0 {
                ball.vel.x *= -1
            }

            // top wall collision
            if ball.pos.y <= 0 {
                ball.vel.y *= -1
            }

            // bottom  wall collision, reset ball
            if ball.pos.y + ball.size.y > screen_width {
                reset_ball(&ball, &player)
            }

            ball.rotation += BALL_ROTATION * -ball.vel.x
            ball.pos += ball.vel * ball.speed * delta_time

            if check_collision(&ball, &player) {
                ball.vel.y *= -1
            }

            for &brick in levels[int(select_level)].data {
                if brick.destroyed do continue

                if check_collision(&ball, &brick) {
                    if brick.is_solid {
                        ball.vel.y *= -1
                    } else {
                        brick.destroyed = true
                    }
                }
            }

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

            draw_level(&levels[int(select_level)])

            en.draw_sprite(player.sprite, player.pos, player.size, 0)
            en.draw_sprite(ball.sprite, ball.pos, ball.size, ball.rotation)

        case .Menu:
        case .Win:
        }
   }
}

check_collision :: proc(r1, r2: ^Entity) -> bool {
    if  r1.pos.x + r1.size.x > r2.pos.x &&
        r1.pos.x < r2.pos.x + r2.size.x &&
        r1.pos.y < r2.pos.y + r2.size.y &&
        r1.pos.y + r1.size.y > r2.pos.y {
            return true
        }

    return false
}
