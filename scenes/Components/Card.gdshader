shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;
uniform float glow_width : hint_range(0.0, 0.1) = 0.03;

uniform vec2 atlas_size = vec2(1024.0, 1024.0);
uniform vec2 region_pos = vec2(0.0, 0.0);
uniform vec2 region_size = vec2(64.0, 64.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Convert atlas UV to region-local UV (0..1 within just this card)
    vec2 local_uv = (UV * atlas_size - region_pos) / region_size;

    // Distance from each edge in local space
    float edge = min(min(local_uv.x, 1.0 - local_uv.x), 
                     min(local_uv.y, 1.0 - local_uv.y));

    float glow = smoothstep(glow_width, 0.0, edge);
    COLOR = mix(tex, glow_color, glow * glow_strength);
}