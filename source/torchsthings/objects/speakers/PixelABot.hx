package torchsthings.objects.speakers;

#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end
import flixel.system.FlxAssets.FlxShader;
//import torchsthings.utils.MathUtil;
import torchsfunctions.functions.MathTools;

class PixelABot extends FlxSpriteGroup {
	final VIZ_MAX = 7; //ranges from viz1 to viz7
	final VIZ_POS_X:Array<Float> = [0, 42, 48, 54, 60, 36, 42];
	final VIZ_POS_Y:Array<Float> = [0, -12, -6, 0, 0, 6, 12];

	public var bg:FlxSprite;
	public var vizSprites:Array<FlxSprite> = [];
    public var abotHead:FlxSprite;
    public var speaker:FlxSprite;
    var pixelScale:Float = 6;

	#if funkin.vis
	var analyzer:SpectralAnalyzer;
	#end
	var volumes:Array<Float> = [];

    public function setShader(sdr:FlxShader) {
		this.shader = sdr;
		bg.shader = sdr;
		for (sprite in vizSprites) sprite.shader = sdr;
		abotHead.shader = sdr;
		speaker.shader = sdr;
		return sdr;
	}

    public var snd(default, set):FlxSound;
	function set_snd(changed:FlxSound)
	{
		snd = changed;
		#if funkin.vis
		initAnalyzer();
		#end
		return snd;
	}

    public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		var antialias = /*ClientPrefs.data.antialiasing*/ false;

        bg = new FlxSprite(260, 123).loadGraphic(Paths.image('abot/pixel/aBotPixelBack'));
		bg.antialiasing = antialias;
		add(bg);

		var vizX:Float = 0;
		var vizY:Float = 0;
		var vizFrames = Paths.getSparrowAtlas('abot/pixel/aBotVizPixel');
        for (i in 1...VIZ_MAX + 1) {
            volumes.push(0.0);
            vizX += VIZ_POS_X[i-1];
            vizY += VIZ_POS_Y[i-1];
            var viz:FlxSprite = new FlxSprite(vizX + 140, vizY + 74);
            viz.frames = vizFrames;
            viz.animation.addByPrefix('VIZ', 'viz$i', 0);
            viz.animation.play('VIZ', true);
            viz.animation.curAnim.finish(); //make it go to the lowest point
            viz.antialiasing = antialias;
			viz.scale.set(pixelScale,pixelScale);
            vizSprites.push(viz);
            viz.updateHitbox();
            viz.centerOffsets();
            add(viz);
        }

        abotHead = new FlxSprite(-3, 202).loadGraphic(Paths.image('abot/pixel/abotHead'));
		abotHead.frames = Paths.getSparrowAtlas('abot/pixel/abotHead');
        abotHead.antialiasing = antialias;
        abotHead.animation.addByPrefix('left', 'left', 24);
        abotHead.animation.addByPrefix('toLeft', 'toleft', 24, false);
        abotHead.animation.addByPrefix('right', 'right', 24);
        abotHead.animation.addByPrefix('toRight', 'toright', 24, false);
        abotHead.animation.play('toLeft', true);
        abotHead.animation.finishCallback = function(name:String) {
            if (name == 'toLeft') {
                abotHead.animation.play('left');
            } else if (name == 'toRight') {
                abotHead.animation.play('right');
            }
        }
        add(abotHead);

        speaker = new FlxSprite(242, 128).loadGraphic(Paths.image('abot/pixel/aBotPixel'));
		speaker.frames = Paths.getSparrowAtlas('abot/pixel/aBotPixel');
        speaker.antialiasing = antialias;
        speaker.animation.addByPrefix('bop', 'idle', 24, false);
        speaker.animation.play('bop', true);
        add(speaker);

		for (item in [speaker, abotHead, bg]) item.scale.set(pixelScale,pixelScale);
    }

    #if funkin.vis
	var levels:Array<Bar>;
	var levelMax:Int = 0;
	override function update(elapsed:Float):Void {
		super.update(elapsed);
		if(analyzer == null) return;

		if (this.shader != null && bg.shader != this.shader) {// I just chose a random object that'll get the shader
			setShader(this.shader);
		}

		levels = analyzer.getLevels(levels);
		var oldLevelMax = levelMax;
		levelMax = 0;
		for (i in 0...Std.int(Math.min(vizSprites.length, levels.length)))
		{
			var animFrame:Int = Math.round(levels[i].value * 5);
			
			#if desktop
			if (ClientPrefs.data.volumeDependantBop) animFrame = Math.round(animFrame * MathTools.logToLinear(FlxG.sound.volume));
			#end
			
			animFrame = Math.floor(Math.min(5, animFrame));
			animFrame = Math.floor(Math.max(0, animFrame));
			animFrame = Std.int(Math.abs(animFrame - 5)); // shitty dumbass flip, cuz dave got da shit backwards lol!
				
			vizSprites[i].animation.curAnim.curFrame = animFrame;
			levelMax = Std.int(Math.max(levelMax, 5 - animFrame));
		}

		if(levelMax >= 4)
		{
			//trace(levelMax);
			if(oldLevelMax <= levelMax /*&& (levelMax >= 5 || speaker.anim.curFrame >= 3)*/)
				beatHit();
		}
	}
	#end

    public function beatHit() {
        speaker.animation.play('bop', true);
    }

    #if funkin.vis
	public function initAnalyzer() {
		@:privateAccess
		analyzer = new SpectralAnalyzer(snd._channel.__audioSource, 7, 0.1, 40);
	
		// This is from Vanilla Funkin Source

		// A-Bot tuning...
		analyzer.minDb = -65;
		analyzer.maxDb = -25;
		analyzer.maxFreq = 22000;
		// we use a very low minFreq since some songs use low low subbass like a boss
		analyzer.minFreq = 10;

		// End of base funkin code

		#if desktop
		// On desktop it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
		// So we want to manually change it!
		analyzer.fftN = 256;
		#end
	}
	#end

    var lookingAtRight:Bool = true;
	public function lookLeft()
	{
		if(lookingAtRight) abotHead.animation.play('toLeft', true);
		lookingAtRight = false;
	}
	public function lookRight()
	{
		if(!lookingAtRight) abotHead.animation.play('toRight', true);
		lookingAtRight = true;
	}
}