package torchsthings.objects;

import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;

class ImageBar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;
	public var leftBarOverlay:FlxSprite;
	public var rightBarOverlay:FlxSprite;
	public var valueFunction:Void->Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = new FlxPoint(-5, -5);
	public var barData:BarSettings = null;

	/*
		When choosing your bar, the array goes like this:
		1. Texture
		2. Library
		3. Is it animated
		4. Animation name

		All of these have to be a string, so number 3 would end up being either 'true' or 'false', not true or false... does that make sense?
	*/

	public function new(x:Float, y:Float, barSettings:BarSettings, enemyColor:FlxColor = 0xFFFF0000, playerColor:FlxColor = 0xFF00FF0D, valueFunction:Void->Float = null, minVal:Float = 0, maxVal:Float = 2) {
		super(x, y);
		if (barSettings == null) {
			barSettings = {
				emptyBar: "Default",
				emptyBarLibrary: "shared",
				emptyBarAnimated: false,
				fullBar: "Default",
				fullBarLibrary: "shared",
				fullBarAnimated: false
			}
		}
		barData = barSettings;

		if (valueFunction == null) {
			valueFunction = function() return 1;
		}
		this.valueFunction = valueFunction;
		setBounds(minVal, maxVal);

		bg = new FlxSprite().loadGraphic(Paths.image('healthbars/' + barData.emptyBar, barData.emptyBarLibrary, false), barData.emptyBarAnimated);
		bg.antialiasing = ClientPrefs.data.antialiasing;
		leftBar = new FlxSprite().loadGraphic(Paths.image('healthbars/' + barData.emptyBar, barData.emptyBarLibrary, false), barData.emptyBarAnimated);
		leftBar.antialiasing = ClientPrefs.data.antialiasing;
		if (barData.emptyBarAnimated) {
			bg.frames = Paths.getSparrowAtlas('healthbars/' + barData.emptyBar, barData.emptyBarLibrary);
			leftBar.frames = Paths.getSparrowAtlas('healthbars/' + barData.emptyBar, barData.emptyBarLibrary);
			animationAdd(true);
		}
		if (barData.emptyBarOverlay != null && barData.emptyBarOverlay != '') {
			leftBarOverlay = new FlxSprite().loadGraphic(Paths.image('healthbars/' + barData.emptyBarOverlay, barData.emptyBarLibrary, false), barData.emptyBarOverlayAnimated);
			leftBarOverlay.antialiasing = ClientPrefs.data.antialiasing;
			if (barData.emptyBarOverlayAnimated) {
				leftBarOverlay.frames = Paths.getSparrowAtlas('healthbars/' + barData.emptyBarOverlay, barData.emptyBarLibrary);
				animationAdd(true, true);
			}
		}

		rightBar = new FlxSprite().loadGraphic(Paths.image('healthbars/' + barData.fullBar, barData.fullBarLibrary, false), barData.fullBarAnimated);
		rightBar.antialiasing = ClientPrefs.data.antialiasing;
		if (barData.fullBarAnimated) {
			rightBar.frames = Paths.getSparrowAtlas('healthbars/' + barData.fullBar, barData.fullBarLibrary);
			animationAdd(false);
		}
		if (barData.fullBarOverlay != null && barData.fullBarOverlay != '') {
			rightBarOverlay = new FlxSprite().loadGraphic(Paths.image('healthbars/' + barData.fullBarOverlay, barData.fullBarLibrary, false), barData.fullBarOverlayAnimated);
			rightBarOverlay.antialiasing = ClientPrefs.data.antialiasing;
			if (barData.fullBarOverlayAnimated) {
				rightBarOverlay.frames = Paths.getSparrowAtlas('healthbars/' + barData.fullBarOverlay, barData.fullBarLibrary);
				animationAdd(false, true);
			}
		}

		setColors(enemyColor, playerColor);

		barWidth = Std.int(bg.width + 10);
		barHeight = Std.int(bg.height + 10);

		add(bg);
		bg.visible = false;
		add(leftBar);
		add(rightBar);
		if (leftBarOverlay != null) add(leftBarOverlay);
		if (rightBarOverlay != null) add(rightBarOverlay);
		regenerateClips();
	}

	public function animationAdd(left:Bool, ?overlay:Bool = false) {
		if (overlay) {
			if (left) {
				leftBarOverlay.animation.addByPrefix("idle", barData.emptyBarOverlayAnimationName, 24, true);
				leftBarOverlay.animation.play('idle');
			} else {
				rightBarOverlay.animation.addByPrefix("idle", barData.fullBarOverlayAnimationName, 24, true);
				rightBarOverlay.animation.play('idle');
			}
		} else {
			if (left) {
				leftBar.animation.addByPrefix("idle", barData.emptyBarAnimationName, 24, true);
				leftBar.animation.play("idle");
			} else {
				rightBar.animation.addByPrefix("idle", barData.fullBarAnimationName, 24, true);
				rightBar.animation.play("idle");
			}
		}
	}

	public var healthLerp:Bool = false;
	var lerpingHealth:Float = 1;
	public var enabled:Bool = true;
	override function update(elapsed:Float) {
		if(!enabled)
		{
			super.update(elapsed);
			return;
		}

		if(valueFunction != null)
		{
			var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(valueFunction(), bounds.min, bounds.max), bounds.min, bounds.max, 0, 100);
			if (healthLerp) {
				lerpingHealth = FlxMath.lerp(lerpingHealth, value, 0.15);
				percent = (value != null ? lerpingHealth : 0);
			} else {
				percent = (value != null ? value : 0);
			}
		}
		else percent = 0;
		super.update(elapsed);
	}

	
	public function setBounds(min:Float, max:Float)
	{
		bounds.min = min;
		bounds.max = max;
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null)
	{
		if (left != null)
			leftBar.color = left;
		if (right != null)
			rightBar.color = right;
	}

	public function changeDirection() {
		leftToRight = !leftToRight;
		var tempCol = rightBar.color;
		rightBar.color = leftBar.color;
		leftBar.color = tempCol;
		updateBar();
	}

	public function setSpriteShaders(shader:FlxShader) {
		bg.shader = shader;
		leftBar.shader = shader;
		rightBar.shader = shader;
		if (leftBarOverlay != null) leftBarOverlay.shader = shader;
		if (rightBarOverlay != null) rightBarOverlay.shader = shader;
	}
	
	public function grabShaders():Array<FlxShader> {
		var temp:Array<FlxShader> = [bg.shader, leftBar.shader, rightBar.shader];
		if (leftBarOverlay != null) temp.push(leftBarOverlay.shader);
		if (rightBarOverlay != null) temp.push(rightBarOverlay.shader);
		return temp;
	}

	public function updateBar()
	{
		if(leftBar == null || rightBar == null) return;

		leftBar.setPosition(bg.x, bg.y);
		rightBar.setPosition(leftBar.x, leftBar.y);

		var leftSize:Float = 0;
		if(leftToRight) leftSize = FlxMath.lerp(0, barWidth, percent / 100);
		else leftSize = FlxMath.lerp(0, barWidth, 1 - percent / 100);

		leftBar.clipRect.width = leftSize;
		leftBar.clipRect.height = barHeight + 10;
		leftBar.clipRect.x = barOffset.x;
		leftBar.clipRect.y = barOffset.y;

		rightBar.clipRect.width = barWidth - leftSize;
		rightBar.clipRect.height = barHeight + 10;
		rightBar.clipRect.x = barOffset.x + leftSize;
		rightBar.clipRect.y = barOffset.y;

		barCenter = leftBar.x + leftSize + barOffset.x;

		// flixel is retarded
		leftBar.clipRect = leftBar.clipRect;
		rightBar.clipRect = rightBar.clipRect;
		updateOverlays(leftSize);
	}

	public function updateOverlays(size:Float) {
		if (leftBarOverlay == null && rightBarOverlay == null) return;
		
		if (leftBarOverlay != null) {
			leftBarOverlay.setPosition(leftBar.x, leftBar.y);
			
			leftBarOverlay.clipRect.width = size;
			leftBarOverlay.clipRect.height = barHeight + 10;
			leftBarOverlay.clipRect.x = barOffset.x;
			leftBarOverlay.clipRect.y = barOffset.y;

			leftBarOverlay.clipRect = leftBarOverlay.clipRect;
		}

		if (rightBarOverlay != null) {
			rightBarOverlay.setPosition(rightBar.x, rightBar.y);
			
			rightBarOverlay.clipRect.width = barWidth - size;
			rightBarOverlay.clipRect.height = barHeight + 10;
			rightBarOverlay.clipRect.x = barOffset.x + size;
			rightBarOverlay.clipRect.y = barOffset.y;

			rightBarOverlay.clipRect = rightBarOverlay.clipRect;
		}
	}

	public function regenerateClips()
	{
		if(leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		if (leftBarOverlay != null) {
			leftBarOverlay.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			leftBarOverlay.updateHitbox();
			leftBarOverlay.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		if(rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		if (rightBarOverlay != null) {
			rightBarOverlay.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			rightBarOverlay.updateHitbox();
			rightBarOverlay.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		updateBar();
	}

	private function set_percent(value:Float)
	{
		var doUpdate:Bool = false;
		if(value != percent) doUpdate = true;
		percent = value;

		if(doUpdate) updateBar();
		return value;
	}

	private function set_leftToRight(value:Bool)
	{
		leftToRight = value;
		updateBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		regenerateClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		regenerateClips();
		return value;
	}
}

typedef BarSettings = {
	var emptyBar:String;
	var emptyBarLibrary:String;
	@:optional var emptyBarOverlay:String;
	@:optional var emptyBarOverlayAnimated:Bool;
	@:optional var emptyBarOverlayAnimationName:String;
	var emptyBarAnimated:Bool;
	@:optional var emptyBarAnimationName:String;
	var fullBar:String;
	var fullBarLibrary:String;
	@:optional var fullBarOverlay:String;
	@:optional var fullBarOverlayAnimated:Bool;
	@:optional var fullBarOverlayAnimationName:String;
	var fullBarAnimated:Bool;
	@:optional var fullBarAnimationName:String;
}