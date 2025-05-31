// Made by TorchTheDragon, use it if you want, I don't need credit

#pragma header

uniform float blurAmount;
uniform float edgeFade;
uniform vec2 framePos;
uniform vec2 frameSize;
uniform vec4 tintColor;

void main() {
    vec2 pixelSize = vec2(1.0) / openfl_TextureSize;

    vec2 localUV = (openfl_TextureCoordv - framePos) / frameSize;
    localUV = clamp(localUV, 0.0, 1.0);

    vec2 baseUV = framePos + localUV * frameSize;

    vec4 color = vec4(0.0);
    float total = 0.0;

    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            vec2 offset = vec2(x, y) * pixelSize * blurAmount;
            vec2 sampleUV = clamp(baseUV + offset, framePos - (pixelSize * 0.5), framePos + frameSize + (pixelSize * 0.5));
            color += flixel_texture2D(bitmap, sampleUV);
            total += 1.0;
        }
    }

    color /= total;

    float fade = smoothstep(0.0, edgeFade, localUV.x)
               * smoothstep(0.0, edgeFade, localUV.y)
               * smoothstep(0.0, edgeFade, 1.0 - localUV.x)
               * smoothstep(0.0, edgeFade, 1.0 - localUV.y);

    color *= tintColor;
    color.a *= fade;

    gl_FragColor = color;
}
