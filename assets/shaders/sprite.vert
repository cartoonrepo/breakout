#version 330 core

layout (location = 0) in vec2 position;
layout (location = 1) in vec2 tex_coord;

out vec2 v_tex_coord;

uniform mat4 model;
uniform mat4 projection;

void main() {
    v_tex_coord = tex_coord;
    gl_Position = projection * model * vec4(position, 0.0, 1.0f);
}
