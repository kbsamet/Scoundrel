shader_type canvas_item;

uniform vec2 _CirclePosition = vec2(0.5);
uniform float _Progress : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float _Smoothness : hint_range(0.0, 0.1, 0.01) = 0.03;
uniform vec4 _Background : source_color;
/** Ellipse stretch — x squishes width, y squishes height. 1.0 = circle */
uniform vec2 _EllipseScale = vec2(1.0, 0.75);

float ellipse_dist(vec2 a, vec2 b, vec2 scale) {
    return length((a - b) * scale);
}

void fragment() {
    float r = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
    vec2 position = _CirclePosition * vec2(r, 1.0);
    vec2 new_uv   = SCREEN_UV        * vec2(r, 1.0);

    // Scale used for ellipse — combine aspect correction with ellipse shape
    vec2 ell = _EllipseScale * vec2(1.0, 1.0);

    // Most far away corner using ellipse distance
    float far_x = float(_CirclePosition.x < 0.5) * r;
    float far_y = float(_CirclePosition.y < 0.5);
    float r_max = ellipse_dist(position, vec2(far_x, far_y), ell);

    float new_progress = r_max * (1.0 - _Progress);
    float f    = mix(new_progress, new_progress + _Smoothness, new_progress);
    float mask = smoothstep(new_progress, f, ellipse_dist(new_uv, position, ell));

    COLOR = vec4(_Background.rgb, _Background.a * mask);
}