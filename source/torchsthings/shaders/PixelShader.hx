package torchsthings.shaders;

import flixel.system.FlxAssets.FlxShader;

// This is the exact same thing in the NoteSplash section, but only for the blocky bits
class PixelShader extends FlxShader {
	@:glFragmentHeader('
		#pragma header

		uniform vec2 uBlocksize;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) {
			vec2 blocks = openfl_TextureSize / uBlocksize;

			vec2 q = openfl_TextureCoordv.xy;

			vec4 color = flixel_texture2D(bitmap, floor(coord * blocks) / blocks);
			if (!hasTransform) {
				return color;
			}

			if(color.a == 0.0) {
				return color * openfl_Alphav;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * vec3(0.0) + color.g * vec3(0.0) + color.b * vec3(0.0), vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, 0.0);
			
			if(color.a > 0.0) {
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}')

	@:glFragmentSource('
		#pragma header

		void main() {
			gl_FragColor = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);
		}')

	public function new()
	{
		super();
	}
}

class PixelShaderRef {
	public var shader:PixelShader = new PixelShader();

	public function new(?pixelBlockSize:Float = 6)
	{
		if (pixelBlockSize == null) pixelBlockSize = PlayState.daPixelZoom;
		var pixel:Float = pixelBlockSize;
		shader.uBlocksize.value = [pixel, pixel];
		//trace('Created shader ' + Conductor.songPosition);
	}

	public function updateBlockSize(pixelBlockSize:Float) {
		shader.uBlocksize.value = [pixelBlockSize, pixelBlockSize];
	}
}