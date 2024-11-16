#pragma header

uniform float uTime;
uniform float uSwipeAmount;

void main()
{
    vec2 q = openfl_TextureCoordv.xy;
    vec2 uv = 0.5 + (q-0.5)*(0.9 + 0.1*sin(1.0/**uTime*/));

    vec4 oricol = flixel_texture2D( bitmap, vec2(q.x,q.y) );
    vec4 col;

    col.r = flixel_texture2D(bitmap,vec2(uv.x+0.003,uv.y)).x;
    col.g = flixel_texture2D(bitmap,vec2(uv.x+0.000,uv.y)).y;
    col.b = flixel_texture2D(bitmap,vec2(uv.x-0.003,uv.y)).z;
	col.a = flixel_texture2D(bitmap,vec2(uv.x,uv.y)).a;

    col = clamp(col*0.5+0.5*col*col*1.2,0.0,1.0);

    col *= 0.5 + 0.5*16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y);

    col *= vec4(0.95,1.05,0.95,1.0);

    col *= 0.9+0.1*sin(10.0*uTime+uv.y*1000.0);
    
    col *= 0.99+0.01*sin(110.0*uTime);
    
    col *= 1.25; 
    col = mix( col, oricol, clamp(-2.0 + 2.0 * q.x + 3.0 * uSwipeAmount, 0.0, 1.0) );

    gl_FragColor = col;
}