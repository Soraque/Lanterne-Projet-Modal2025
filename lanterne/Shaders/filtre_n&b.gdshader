shader_type canvas_item;

uniform float desaturation_amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // COLOR contient déjà texture * modulate du sprite
    float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
    gray = clamp(gray, 0.0, 1.0);
    COLOR.rgb = mix(COLOR.rgb, vec3(gray), clamp(desaturation_amount, 0.0, 1.0));
}
