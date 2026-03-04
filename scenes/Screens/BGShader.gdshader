shader_type canvas_item;

uniform float speed : hint_range(0.0, 2.0) = 0.01;

void fragment() {
    vec2 uv = UV;
	uv.x += TIME * speed * 0.5;
    uv.y -= TIME * speed;
    vec4 noise = texture(TEXTURE, fract(uv));
    noise.rgb = pow(noise.rgb, vec3(1.1)); // higher = sharper
    COLOR = texture(TEXTURE, fract(uv));
}