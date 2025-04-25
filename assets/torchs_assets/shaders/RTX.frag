#pragma header

uniform vec4 overlay;
uniform vec4 satin;
uniform vec4 shadow;
uniform float daAngle;
uniform float daDistance;
uniform float falloffOn;

float DIST = 5.0;

float blendDodge(float base, float blend) {
    return (blend == 1.0) ? blend : min(base / (1.0 - blend), 1.0);
}
vec3 colorDodge(vec3 base, vec3 blend) {
    return vec3(blendDodge(base.r, blend.r), blendDodge(base.g, blend.g), blendDodge(base.b, blend.b));
}
vec3 lighten(vec3 base, vec3 blend) {
    return vec3(max(blend.r, base.r), max(blend.g, base.g), max(blend.b, base.b));
}

vec3 blend(vec3 base, vec3 blended, vec3 opacity) {
    return (blended * opacity + base * (1.0 - opacity));
}
float invert(float value)
{
    return (0.0 - value) + 1.0;
}

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 sprColor = flixel_texture2D(bitmap, uv);
    vec2 resolution = 1.0 / openfl_TextureSize.xy;

    sprColor.rgb = blend(sprColor.rgb, sprColor.rgb * satin.rgb, satin.a);

    float offsetX = cos(daAngle);
    float offsetY = sin(daAngle);
    vec2 multDist = (daDistance * resolution) / DIST;
    for (int i = 0; i < DIST; i++) {
        vec4 col = texture2D(bitmap, uv + vec2(offsetX * (multDist.x * i), offsetY * (multDist.y * i)));
        float falloff = 1.0 - (float(i) / DIST);
        if (falloffOn > 0.5) {
            sprColor.rgb = blend(sprColor.rgb, colorDodge(sprColor.rgb, shadow.rgb), shadow.a * invert(col.a) * falloff);
        } else {
            sprColor.rgb = blend(sprColor.rgb, colorDodge(sprColor.rgb, shadow.rgb), shadow.a * invert(col.a));
        }
    }

    sprColor.rgb = blend(sprColor.rgb, lighten(sprColor.rgb, overlay.rgb), overlay.a);
    gl_FragColor = sprColor * sprColor.a;
}