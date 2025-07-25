package states.stages.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import backend.BaseStage;
//import torchsthings.shaders.AdjustColorShader;

class TankmenSpeaker extends FlxGroup
{
    private var tankmen:FlxSprite;
    private var headtank:FlxSprite;
    private var thugmen:FlxSprite;
    private var headthugmen:FlxSprite;
	public var thestage:BaseStage;

	public function new (tankmenCords:Array<Float>, thugmenCords:Array<Float>)
	{
		super();
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

		add(tankmen);
		add(headtank);
		add(thugmen);
		add(headthugmen);
	}

	public function dance()
	{
		tankmen.animation.play("idle", false);
		headtank.animation.play("idle", false);
		thugmen.animation.play("idle", false);
		headthugmen.animation.play("idle", false);
	}

} 