shader_type canvas_item;

uniform bool has_card_above = true;
uniform float shadow_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float corner_radius = 8.0;
uniform vec2 shadow_offset = vec2(15.0, 15.0);
uniform vec2 rect_size; 
uniform vec4 uv_rect; // x, y are pos; z, w are size (in UV units)

float sd_rounded_rect(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
    vec4 card_tex = texture(TEXTURE, UV);
    
    if (has_card_above) {
        // Transform Global Atlas UV to Local Card UV (0.0 to 1.0)
        vec2 local_uv = (UV - uv_rect.xy) / uv_rect.zw;
        
        // Map to actual pixel size of the TextureRect node
        vec2 p_pixel = local_uv * rect_size;
        
        // Shadow math
        vec2 center = (rect_size / 2.0) + shadow_offset;
        vec2 half_extents = rect_size / 2.0;
        
        float dist = sd_rounded_rect(p_pixel - center, half_extents, corner_radius);
        float shadow_mask = smoothstep(-1.0, 1.0, dist);
        
        float darkness = mix(1.0 - shadow_intensity, 1.0, shadow_mask);
        COLOR = vec4(card_tex.rgb * darkness, card_tex.a);
    } else {
        COLOR = card_tex;
    }
}