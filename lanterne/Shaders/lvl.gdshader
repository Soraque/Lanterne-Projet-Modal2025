shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float desaturation_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color = textureLod(screen_texture, SCREEN_UV, 0.0);

    // Noir et blanc
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
    color.rgb = mix(color.rgb, vec3(gray), desaturation_amount);

    // Nécessaire au fonctionnement du CanvasGroup
    if (color.a > 0.0001) {
        color.rgb /= color.a;
    }

    COLOR *= color;
}
