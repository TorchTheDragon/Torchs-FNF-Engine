package states.stages;

import states.stages.objects.*;
import objects.Character;
import openfl.filters.ShaderFilter;
import flixel.util.typeLimit.*;

class Philly extends BaseStage
{
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;
	var streetBehind:BGSprite;

	//For Philly Glow events
	var blammedLightsBlack:FlxSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var phillyWindowEvent:BGSprite;
	var curLightEvent:Int = -1;


	override function create()
	{
		if(!ClientPrefs.data.lowQuality) {
			var bg:BGSprite = new BGSprite('philly/sky', -330, -50, 0.1, 0.1);
			add(bg);
		}

		var city:BGSprite = new BGSprite('philly/city', -240, 50, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
		phillyWindow = new BGSprite('philly/windows', city.x, city.y, 0.3, 0.3);
		phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
		phillyWindow.updateHitbox();
		add(phillyWindow);
		phillyWindow.alpha = 0;

		if(!ClientPrefs.data.lowQuality) {
			streetBehind = new BGSprite('philly/behindTrain', -320, 150);
			add(streetBehind);
		}

		phillyTrain = new PhillyTrain(2000, 360);
		add(phillyTrain);

		phillyStreet = new BGSprite('philly/street', -320, 150);
		add(phillyStreet);

		
	}
	override function createPost() {
		super.createPost();
		addReflectedChar(boyfriend);
	}

	override function eventPushed(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case "Philly Glow":
				if (!torchsthings.objects.CustomEvents.stageEvents.contains("Philly Glow")) torchsthings.objects.CustomEvents.stageEvents.push("Philly Glow");
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/windows', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlowGradient(-400, 225);
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.data.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				Paths.image('philly/particle'); //precache philly glow particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}
	}

	override function update(elapsed:Float)
	{
		phillyWindow.alpha -= (Conductor.crochet / 1000) * elapsed * 1.5;
		if(phillyGlowParticles != null)
		{
			phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
			{
				if(particle.alpha <= 0)
					particle.kill();
			});
		}
	}

	override function beatHit()
	{
		phillyTrain.beatHit(curBeat);
		if (curBeat % 4 == 0)
		{
			curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
			phillyWindow.color = phillyLightsColors[curLight];
			phillyWindow.alpha = 1;
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case "Philly Glow":
				PlayState.instance.eventExisted = true;
				if(flValue1 == null || flValue1 <= 0) flValue1 = 0;
				var lightId:Int = Math.round(flValue1);

				var chars:Array<FlxSprite> = [boyfriend, gf, dad];
				//if (abot != null) chars.push(abot);
				if (speaker != null) chars.push(speaker);
				switch(lightId)
				{
					case 0:
						if(phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for (who in chars)
							{
								who.color = FlxColor.WHITE;
							}
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: //turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length-1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(!phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.data.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.data.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;

						for (who in chars)
						{
							who.color = charColor;
						}
						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
						{
							particle.color = color;
						});
						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(!ClientPrefs.data.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = phillyGlowParticles.recycle(PhillyGlowParticle);
									particle.x = -400 + width * i + FlxG.random.float(-width / 5, width / 5);
									particle.y = phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40);
									particle.color = color;
									particle.start();
									phillyGlowParticles.add(particle);
								}
							}
						}
						phillyGlowGradient.bop();
				}
		}
	}

	function doFlash()
	{
		var color:FlxColor = FlxColor.WHITE;
		if(!ClientPrefs.data.flashing) color.alphaFloat = 0.5;

		FlxG.camera.flash(color, 0.15, null, true);
	}
}