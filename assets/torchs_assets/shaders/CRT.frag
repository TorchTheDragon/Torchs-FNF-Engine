#pragma header

uniform float uTime;
uniform float uSwipeAmount;
uniform float uIsCreepy;
uniform float uIsTest;
uniform float movingPoint;

#define BLUR 0.021

void main()
{
    vec2 q = openfl_TextureCoordv.xy;
    vec2 uv = 0.5 + (q-0.5)*(0.9 + 0.1*sin(1.0/**uTime*/));

    vec4 oricol = flixel_texture2D( bitmap, vec2(q.x,q.y) );
    vec4 col;

    // curving
    vec2 crtUV = uv * 2.0 - 1.0;
    vec2 offset = crtUV.yx / 4.2;
    crtUV += crtUV * offset * offset;
    crtUV = crtUV * .5 + .5;
    vec2 edge = smoothstep(0.0, BLUR, crtUV) * (1.0 - smoothstep(1.0 - BLUR, 1.0, crtUV));

    if (uIsCreepy >= 0.5) {
        col.r = flixel_texture2D(bitmap,vec2(uv.x+0.003,uv.y)).x;
        col.g = flixel_texture2D(bitmap,vec2(uv.x+0.000,uv.y)).y;
        col.b = flixel_texture2D(bitmap,vec2(uv.x-0.003,uv.y)).z;
        col.a = flixel_texture2D(bitmap,vec2(uv.x,uv.y)).a;
    } else {
        col.r = flixel_texture2D(bitmap,vec2(crtUV.x+0.003,crtUV.y)).x;
        col.g = flixel_texture2D(bitmap,vec2(crtUV.x+0.000,crtUV.y)).y;
        col.b = flixel_texture2D(bitmap,vec2(crtUV.x-0.003,crtUV.y)).z;
        col.a = flixel_texture2D(bitmap,vec2(crtUV.x,crtUV.y)).a;
    }

    col = clamp(col*0.5+0.5*col*col*1.2,0.0,1.0);

    col *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);

    col *= vec4(0.95,1.05,0.95,1.0);

    col *= 0.9+0.1*sin(10.0*uTime+uv.y*1000.0);
    
    col *= 0.99+0.01*sin(110.0*uTime);
    
    col *= 1.25; 
    col = mix( col, oricol, clamp(-2.0 + 2.0 * q.x + 3.0 * uSwipeAmount, 0.0, 1.0) );
    
    if (uIsCreepy >= 0.5 && uIsTest >= 0.5) {
        if (q.x <= 0.5) {
            col.rgb *= (flixel_texture2D(bitmap, crtUV).r, flixel_texture2D(bitmap, crtUV).g, flixel_texture2D(bitmap, crtUV).b) * edge.x * edge.y;
        } else {
            col.rgb *= edge.x * edge.y;
        }
    } else if (uIsCreepy >= 0.5) {
        col.rgb *= (flixel_texture2D(bitmap, crtUV).r, flixel_texture2D(bitmap, crtUV).g, flixel_texture2D(bitmap, crtUV).b) * edge.x * edge.y;
    } else {
        col.rgb *= edge.x * edge.y;
    }

    if (uIsTest >= 0.5 && uIsCreepy < 0.5) {
        if (q.x <= movingPoint) {
            gl_FragColor = col;
        } else {
            gl_FragColor = oricol;
        }
    } else {
        gl_FragColor = col;
    }
}