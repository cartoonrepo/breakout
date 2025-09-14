package main

import en  "engine"
import glm "core:math/linalg/glsl"

// all entity in one
Entity :: struct {
    pos       : glm.vec2,
    size      : glm.vec2,
    vel       : glm.vec2,
    speed     : f32,
    rotation  : f32,
    radius    : f32,
    color     : en.Color,
    is_solid  : bool,
    destroyed : bool,
    stuck     : bool,
    sprite    : en.Texture,
}

// /player
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

// /ball
setup_ball :: proc(texture: ^en.Texture, radius, speed: f32, player: ^Entity) -> Entity {
    x := player.pos.x + (player.size.x - radius) / 2
    y := player.pos.y - radius // 10 is offset, i eye balled it.

    return Entity {
        pos    = {x, y},
        size   = {radius, radius},
        radius = radius,
        speed  = speed,
        stuck  = true,
        sprite = texture^,
    }
}

reset_ball :: proc(ball, player: ^Entity) {
    ball.pos.x = player.pos.x + (player.size.x - ball.radius) / 2
    ball.pos.y = player.pos.y - ball.radius
    ball.vel   = {0, 0}
    ball.stuck = true

}
