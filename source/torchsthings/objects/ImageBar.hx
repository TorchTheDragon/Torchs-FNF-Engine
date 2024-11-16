package torchsthings.objects;

import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;

class ImageBar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var bg:FlxSprite;
	public var valueFunction:Void->Float = null;
	public var percent(default, set):Float = 0;
	public var bounds:Dynamic = {min: 0, max: 1};
	public var leftToRight(default, set):Bool = true;
	public var barCenter(default, null):Float = 0;

	// you might need to change this if you want to use a custom bar
	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = new FlxPoint(-5, -5);
	public var barData:Array<String> = [];

	/*
		When choosing your bar, the array goes like this:
		1. Texture
		2. Library
		3. Is it animated
		4. Animation name

		All of these have to be a string, so number 3 would end up being either 'true' or 'false', not true or false... does that make sense?
	*/

	public function new(x:Float, y:Float, emptyBar:Array<String>, fullBar:Array<String>, enemyColor:FlxColor = 0xFFFF0000, playerColor:FlxColor = 0xFF00FF0D, valueFunction:Void->Float = null, minVal:Float = 0, maxVal:Float = 2)
	{
		super(x, y);

        if (emptyBar[0] == '' || emptyBar[0] == null) emptyBar[0] = 'new_healthBar_empty';
        if (emptyBar[1] == '') emptyBar[1] = null;
		if ((emptyBar[2] == '' || emptyBar[2] == null) || (emptyBar[3] == '' || emptyBar[3] == null)) {emptyBar[2] = 'false'; emptyBar[3] == 'none';}
		barData.insert(0, emptyBar[3]);

        if (fullBar[0] == '' || fullBar[0] == null) fullBar[0] = 'new_healthBar';
        if (fullBar[1] == '') fullBar[1] = null;
		if ((fullBar[2] == '' || fullBar[2] == null) || (fullBar[3] == '' || fullBar [3] == null)) {fullBar[2] = 'false'; fullBar[3] == 'none';}
		barData.insert(1, fullBar[3]);
		
		if (valueFunction == null) {
			valueFunction = function() return 1;
		}
		this.valueFunction = valueFunction;
		setBounds(minVal, maxVal);

		bg = new FlxSprite().loadGraphic(Paths.image(emptyBar[0], emptyBar[1], false), (emptyBar[2] == 'true')); //honestly, just here for sizing of everything

		leftBar = new FlxSprite().loadGraphic(Paths.image(emptyBar[0], emptyBar[1], false), (emptyBar[2] == 'true'));
		leftBar.antialiasing = antialiasing = ClientPrefs.data.antialiasing;
		if (emptyBar[2] == 'true') {
			bg.frames = Paths.getSparrowAtlas(emptyBar[0], emptyBar[1]);
			leftBar.frames = Paths.getSparrowAtlas(emptyBar[0], emptyBar[1]);
			animationAdd(true);
		}

		rightBar = new FlxSprite().loadGraphic(Paths.image(fullBar[0], fullBar[1], false), (fullBar[2] == 'true'));
		rightBar.antialiasing = ClientPrefs.data.antialiasing;
		if (fullBar[2] == 'true') {
			rightBar.frames = Paths.getSparrowAtlas(fullBar[0], fullBar[1]);
			animationAdd(false);
		}

		setColors(enemyColor, playerColor);

		barWidth = Std.int(bg.width + 10);
		barHeight = Std.int(bg.height + 10);

		add(bg);
		bg.visible = false;
		add(leftBar);
		add(rightBar);
		regenerateClips();
	}

	public function animationAdd(left:Bool) {
		if (left) {
			leftBar.animation.addByPrefix("idle", barData[0], 24, true);
			leftBar.animation.play("idle");
		} else {
			rightBar.animation.addByPrefix("idle", barData[1], 24, true);
			rightBar.animation.play("idle");
		}
	}

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
			percent = (value != null ? value : 0);
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
	}
	
	public function grabShaders():Array<FlxShader> {
		return [bg.shader, leftBar.shader, rightBar.shader];
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
	}

	public function regenerateClips()
	{
		if(leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			leftBar.updateHitbox();
			leftBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
		}
		if(rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(bg.width), Std.int(bg.height));
			rightBar.updateHitbox();
			rightBar.clipRect = new FlxRect(0, 0, Std.int(bg.width), Std.int(bg.height));
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