package main

import en  "engine"
import glm "core:math/linalg/glsl"

Entity :: struct {
    pos, size, vel: glm.vec2,
    rotation      : f32,
    color         : en.Color,
    is_solid      : bool,
    destroyed     : bool,
    sprite        : en.Texture,
}
