shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 4.0) = 1.2;
uniform float brightness : hint_range(0.0, 2.0) = 1.3;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec2 center = UV - 0.5;
    float vignette = 1.0 - dot(center, center) * vignette_strength;
    vec4 col = texture(TEXTURE, UV);
    col.rgb = mix(col.rgb, tint.rgb, tint_amount);
    col.rgb *= vignette * brightness;
    COLOR = col;
}