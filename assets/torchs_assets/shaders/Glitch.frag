#pragma header

uniform float iTime;
uniform float glitchSeed;

uniform bool enableChromatic;
uniform bool enableJitter;
uniform bool enableWave;
uniform bool enableScanlines;
uniform bool enableChunkShift;
uniform bool enableInvert;

uniform float chunkScale;
uniform float chunkShiftScale;
uniform float chunkInvertScale;

vec2 getNoise(vec2 uv) {
    return vec2(
        fract(sin(dot(uv.xy, vec2(4.12, 7.123))) * 7.12),
        fract(sin(dot(uv.xy, vec2(6.1, 6.12))) * 9.12)
    );
}

void main() {
    vec2 uv = openfl_TextureCoordv;
    vec2 originalUV = uv;

    vec4 baseCol = flixel_texture2D(bitmap, openfl_TextureCoordv);

    if (enableInvert) {
        vec2 invertChunkUV = floor(originalUV * chunkInvertScale); 
        float invertHash = fract(sin(dot(invertChunkUV + glitchSeed * 0.33, vec2(5.123, 2.1223))) * 8.421);

        if (invertHash > 0.75) {
            baseCol.rgb = vec3(1.0) - baseCol.rgb;
        }
    }

    if (enableChunkShift) {
        vec2 shiftChunkUV = floor(originalUV * chunkShiftScale);
        float shiftHash = fract(sin(dot(shiftChunkUV + glitchSeed * 1.5, vec2(3.34, 2.65))) * 1.654);
        
        if (shiftHash > 0.8) {
            //float shiftAngle = shiftHash * 6.2831;
            //float shiftAmount = 0.005 + 0.02 * sin(iTime * 1.5 + shiftHash * 10.0);
            float shiftAmount = 0.005 + 0.02 * sin(iTime * 1.5);
            //vec2 offset = vec2(cos(shiftAngle), sin(shiftAngle)) * shiftAmount;
            vec2 offset = vec2(cos(shiftHash), sin(shiftHash)) * shiftAmount;
            uv += offset;
        }
    }

    if (enableWave) {
        float wave = sin((uv.y + glitchSeed) * 5.0 + iTime * 6.0) * 0.005;
        uv += vec2(wave, 0.0);
    }

    if (enableJitter) {
        vec2 noise = getNoise(uv + glitchSeed) * 0.01;
        uv += noise;
    }

    if (enableChromatic) {
        vec2 chunkUV = floor(originalUV * chunkScale);
        float chunkHash = fract(sin(dot(chunkUV + glitchSeed, vec2(1.4, 2.645))) * 12.31);

        if (chunkHash > 0.5) {
            //float angle = chunkHash * 6.2831;
            float magnitude = 0.005 + 0.005 * sin(iTime * 2.0 + glitchSeed);
            //vec2 dir = vec2(cos(angle), sin(angle)) * magnitude;
            vec2 dir = vec2(cos(chunkHash), sin(chunkHash)) * magnitude;

            float r = flixel_texture2D(bitmap, originalUV + dir).r;
            float g = flixel_texture2D(bitmap, originalUV).g;
            float b = flixel_texture2D(bitmap, originalUV - dir).b;

            baseCol.rgb = vec3(r, g, b);
        }
    }

    if (enableScanlines) {
        float scan = sin(uv.y * 240.0) * 0.1;
        float flicker = sin(iTime * 50.0 + glitchSeed) * 0.1;
        baseCol.rgb += scan + flicker;
    }

    gl_FragColor = baseCol;
}
