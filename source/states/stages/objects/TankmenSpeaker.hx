package states.stages.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import backend.BaseStage;
import shaders.DropShadowShader;
import shaders.DropShadowScreenspace;

class TankmenSpeaker extends FlxGroup
{
	private var tankmen:FlxSprite;
    private var headtank:FlxSprite;
    private var thugmen:FlxSprite;
    private var headthugmen:FlxSprite;
	public var thestage:BaseStage;
	public var doShader:Bool = true;

	public function new (tankmenCords:Array<Float>, thugmenCords:Array<Float>, stage:BaseStage, ?shader:Bool = true)
	{
		super();
		thestage = stage;
		tankmen = new FlxSprite(300 + tankmenCords[0], 330 + tankmenCords[1]);
		tankmen.frames = Paths.getSparrowAtlas("Tankmens/Tankmen_Body"); // Use the correct extension
		tankmen.animation.addByPrefix('idle','Tankmen', 24, false);
		tankmen.animation.play('idle', true);
		tankmen.antialiasing = ClientPrefs.data.antialiasing;

		headtank = new FlxSprite(tankmen.x + -30, tankmen.y + -120);
		headtank.frames = Paths.getSparrowAtlas("Tankmens/Tankmen_Head");
		headtank.animation.addByPrefix('idle','Tankmen', 24, false);
		headtank.animation.play('idle');
		headtank.antialiasing = ClientPrefs.data.antialiasing;

		thugmen = new FlxSprite(970 + thugmenCords[0], 330 + thugmenCords[1]);
		thugmen.frames = Paths.getSparrowAtlas("Tankmens/Thugmen_Body"); // Use the correct extension
		thugmen.animation.addByPrefix('idle','Thugmen', 24, false);
		thugmen.animation.play('idle', true);
		thugmen.antialiasing = ClientPrefs.data.antialiasing;

		headthugmen = new FlxSprite(thugmen.x + -60, thugmen.y + -120);
		headthugmen.frames = Paths.getSparrowAtlas("Tankmens/Thugmen_Head");
		headthugmen.animation.addByPrefix('idle','Thugmen', 24, false);
		headthugmen.animation.play('idle');
		headthugmen.antialiasing = ClientPrefs.data.antialiasing;

		doShader = shader;

		if (doShader)
		{
			applyShader(tankmen);
		    applyShader(headtank);
			applyShader(thugmen);
			applyShader(headthugmen);
		}
		thestage.addBehindSpeaker(tankmen);
		add(headtank);
		thestage.addBehindSpeaker(thugmen);
		add(headthugmen);
	}

	public function dance()
	{
		tankmen.animation.play("idle", false);
		headtank.animation.play("idle", false);
		thugmen.animation.play("idle", false);
		headthugmen.animation.play("idle", false);
	}

	function applyShader(sprite:FlxSprite)
	{
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
		rim.threshold = 0.7;
		rim.antialiasAmt = 0;
		rim.attachedSprite = sprite;
		rim.angle = 90;
		sprite.shader = rim;
		sprite.animation.callback = function(anim, frame, index)
		{
			rim.updateFrameInfo(sprite.frame);

		};
	}
}