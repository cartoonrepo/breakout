#version 330 core

out vec4 frag_color;
in vec2 v_tex_coord;

uniform sampler2D image;
uniform vec4 color;

void main() {
    frag_color = color * texture(image, v_tex_coord);
}
