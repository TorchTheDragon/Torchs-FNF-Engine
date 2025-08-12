package states;

import backend.Highscore;
import backend.StageData;
import backend.WeekData;
import backend.Song;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.util.FlxGradient;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;
import haxe.Json;
import tjson.TJSON;

import cutscenes.DialogueBoxPsych;

import states.StoryMenuState;
import states.FreeplayState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
import substates.GameOverSubstate;

#if !flash
import openfl.filters.ShaderFilter;
#end

import shaders.ErrorHandledShader;

import objects.VideoSprite;
import objects.Note.EventNote;
import objects.*;
import states.stages.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if HSCRIPT_ALLOWED
import psychlua.HScript.HScriptInfos;
import crowplexus.iris.Iris;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

import torchsfunctions.functions.Extras;

import torchsthings.states.ResultsScreen;
import torchsthings.objects.*;
import torchsthings.objects.ImageBar.BarSettings;
import torchsthings.objects.effects.*;
import torchsthings.utils.WindowUtils;

import lawsthings.objects.IconsAnimator;

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	//event variables
	public var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	//Credits
	public var creditsGroup:FlxSpriteGroup;
	public var creditsDisk:FlxSprite;
	public var creditsArtist:FlxText;
	public var creditsCharter:FlxText;
	public var creditsSongTitle:FlxText;
	public var creditsBG:FlxSprite;
	public var creditsFrontBG:FlxSprite;
	public var creditsIconP:HealthIcon;
	public var creditsIconEn:HealthIcon;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI(default, set):String = "normal";
	public static var uiPrefix:String = "";
	public static var uiPostfix:String = "";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function set_stageUI(value:String):String
	{
		uiPrefix = uiPostfix = "";
		if (value != "normal")
		{
			uiPrefix = value.split("-pixel")[0].trim();
			if (value == "pixel" || value.endsWith("-pixel")) uiPostfix = "-pixel";
		}
		return stageUI = value;
	}

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var focusedChar:Character;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var opponentStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var playerStrums:FlxTypedGroup<StrumNote> = new FlxTypedGroup<StrumNote>();
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash> = new FlxTypedGroup<NoteSplash>();

	// Strum Covers
	public var playerCovers:FlxTypedGroup<StrumCover> = new FlxTypedGroup<StrumCover>();
	public var opponentCovers:FlxTypedGroup<StrumCover> = new FlxTypedGroup<StrumCover>();
	public var strumLineCovers:FlxTypedGroup<StrumCover> = new FlxTypedGroup<StrumCover>();

	// Enemy Splashes
	public var enemyNoteSplashes:Bool = false;
	public var enemyCoverSplashes:Bool = false;

	public var cameraZoomTween:FlxTween;
	public var cameraFollowTween:FlxTween;
	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;
	var maxCombo:Int = 0;

	//public var healthBar:Bar;
	public var healthBar:ImageBar;
	public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;
	public var pressMissDamage:Float = 0.05;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignRatings:Array<Int> = [0, 0, 0, 0];
	public static var campaignPercents:Array<Float> = [];
	public static var campaignCombos:Array<Int> = [];
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	public var curNote:Int = 0;
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	//IconsDance
	var iconsAnimator:IconsAnimator;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;
	//
	public var isDad:Bool = true;
	// Wobbly Notes Stuff
	public var defaultStrumPosition:Array<Array<Float>>= [];
	public var playerStrumsWobble:Array<Int> = [0,0];
	public var opponentStrumsWobble:Array<Int> = [0,0];
	public var lerpSpeeds:Array<Float> = [0, 0, 0, 0];
	public var lerpTweens:Array<flixel.tweens.misc.NumTween> = [null];
	public var wobbleNotes:Bool = false;
	public var strumsWobbled:Array<Bool> = [/*enemy*/ false, /*player*/ false];

	private static var _lastLoadedModDirectory:String = '';
	public static var nextReloadAll:Bool = false;
	public static var healthBarSettings:BarSettings = null;
	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		_lastLoadedModDirectory = Mods.currentModDirectory;
		Paths.clearStoredMemory();
		if(nextReloadAll)
		{
			Paths.clearUnusedMemory();
			Language.reloadPhrases();
		}
		nextReloadAll = false;

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain');
		healthLoss = ClientPrefs.getGameplaySetting('healthloss');
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill');
		practiceMode = ClientPrefs.getGameplaySetting('practice');
		cpuControlled = ClientPrefs.getGameplaySetting('botplay');
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1)
			SONG.stage = StageData.vanillaSongStage(Paths.formatToSongPath(Song.loadedSongName));

		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		defaultCamZoom = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else if (stageData.isPixelStage == true) //Backward compatibility
			stageUI = "pixel";

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': new StageWeek1(); 			//Week 1
			case 'spooky': new Spooky();				//Week 2
			case 'philly': new Philly();				//Week 3
			case 'limo': new Limo();					//Week 4
			case 'mall': new Mall();					//Week 5 - Cocoa, Eggnog
			case 'mallEvil': new MallEvil();			//Week 5 - Winter Horrorland
			case 'school': new School();				//Week 6 - Senpai, Roses
			case 'schoolEvil': new SchoolEvil();		//Week 6 - Thorns
			case 'tank': new Tank();					//Week 7 - Ugh, Guns, Stress
			case 'phillyStreets': new PhillyStreets(); 	//Weekend 1 - Darnell, Lit Up, 2Hot
			case 'phillyBlazin': new PhillyBlazin();	//Weekend 1 - Blazin
			//The Erect Stages
			case 'stageErect': new StageErect();		//Erect
			case 'phillyErect': new PhillyErect();		//Philly Erect
			case 'limoErect': new LimoErect();			//Limo Erect
			case 'mallErect': new MallErect();			//Mall Erect
			case 'schoolErect': new SchoolErect();		//School Erect
			case 'schoolEvilErect': new SchoolEvilErect();	//School Evil Erect
			case 'tankErect': new TankErect();			//Tank Erect
			case 'phillyStreetsErect': new PhillyStreetsErect(); //Philly Streets Erect

			default: new Gray(); // Base Gray stage for visibility
		}
		if(isPixelStage) introSoundsSuffix = '-pixel';

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			//gfGroup.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		
		if(stageData.objects != null && stageData.objects.length > 0)
		{
			var list:Map<String, FlxSprite> = StageData.addObjectsToState(stageData.objects, !stageData.hide_girlfriend ? gfGroup : null, dadGroup, boyfriendGroup, this);
			for (key => spr in list)
				if(!StageData.reservedNames.contains(key))
					variables.set(key, spr);
		}
		else
		{
			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// "SCRIPTS FOLDER" SCRIPTS
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end
			
		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		// STAGE SCRIPTS
		#if LUA_ALLOWED startLuasNamed('stages/' + curStage + '.lua'); #end
		#if HSCRIPT_ALLOWED startHScriptsNamed('stages/' + curStage + '.hx'); #end

		// CHARACTER SCRIPTS
		if(gf != null) startCharacterScripts(gf.curCharacter);
		startCharacterScripts(dad.curCharacter);
		startCharacterScripts(boyfriend.curCharacter);
		#end

		uiGroup = new FlxSpriteGroup();
		comboGroup = new FlxSpriteGroup();
		noteGroup = new FlxTypedGroup<FlxBasic>();
		creditsGroup = new FlxSpriteGroup();
		add(creditsGroup);
		add(comboGroup);
		add(uiGroup);
		add(noteGroup);

		Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 20 : 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = updateTime = showTime;
		if(ClientPrefs.data.downScroll) timeTxt.y = FlxG.height - 44;
		if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		uiGroup.add(timeBar);
		uiGroup.add(timeTxt);

		noteGroup.add(strumLineNotes);
		noteGroup.add(strumLineCovers);

		if(ClientPrefs.data.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		generateSong();

		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject();
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		if (healthBarSettings == null) healthBarSettings = switch (ClientPrefs.data.healthBarSkin) {
			case "Char Based":
				var temp:String = '
				{
					"emptyBar": "${dad.healthBar}",
					"emptyBarLibrary": "${dad.healthBarLibrary}",
					"emptyBarOverlay": "${dad.healthBarOverlay}",
					"emptyBarOverlayAnimated": ${dad.animatedOverlay},
					"emptyBarOverlayAnimationName": "${dad.healthBarOverlayAnimation}",
					"emptyBarAnimated": ${dad.animatedBar},
					"emptyBarAnimationName": "${dad.healthBarAnimation}",
					"fullBar": "${boyfriend.healthBar}",
					"fullBarLibrary": "${boyfriend.healthBarLibrary}",
					"fullBarOverlay": "${boyfriend.healthBarOverlay}",
					"fullBarOverlayAnimated": ${boyfriend.animatedOverlay},
					"fullBarOverlayAnimationName": "${boyfriend.healthBarOverlayAnimation}",
					"fullBarAnimated": ${boyfriend.animatedBar},
					"fullBarAnimationName": "${boyfriend.healthBarAnimation}"
				}
				';
				haxe.Json.parse(temp);
			case "Reanimated":
				if (dad.curCharacter == 'spirit' && isPixelStage) {
					haxe.Json.parse(Assets.getText(Paths.json("healthbars/Reanimated-pixel-glitch", "shared").replace("data", "images")));
				} else if (isPixelStage) {
					haxe.Json.parse(Assets.getText(Paths.json("healthbars/Reanimated-pixel", "shared").replace("data", "images")));
				} else {
					haxe.Json.parse(Assets.getText(Paths.json("healthbars/Reanimated", "shared").replace("data", "images")));
				}
			case "Default":
				haxe.Json.parse(Assets.getText(Paths.json("healthbars/Default", "shared").replace("data", "images")));
			default:
				haxe.Json.parse(Assets.getText(Paths.json("healthbars/" + ClientPrefs.data.healthBarSkin, "shared").replace("data", "images")));
		}

		/*
		var healthBars:Array<Array<String>> = switch (ClientPrefs.data.healthBarSkin) {
			case "Char Based":
				[[dad.healthBar, dad.healthBarLibrary, '${dad.animatedBar}', dad.healthBarAnimation], [boyfriend.healthBar, boyfriend.healthBarLibrary, '${boyfriend.animatedBar}', boyfriend.healthBarAnimation]];
			case "Reanimated":
				[['Reanimated' + (isPixelStage ? ((dad.curCharacter == 'spirit') ? '-pixel-glitch' : '-pixel') : ''), 'shared', ((isPixelStage && dad.curCharacter == 'spirit') ? 'true' : 'false'), ((isPixelStage && dad.curCharacter == 'spirit') ? 'healthBar_pixel_glitched' : 'none')], ['Reanimated' + (isPixelStage ? '-pixel' : ''), 'shared', 'false', 'none']];
			case "Default":
				[['Default', 'shared', 'false', 'none'], ['Default', 'shared', 'false', 'none']];
			default:
				[[ClientPrefs.data.healthBarSkin.toLowerCase(), 'shared', 'false', 'none'], [ClientPrefs.data.healthBarSkin.toLowerCase(), 'shared', 'false', 'none']];
		}
		*/
		
		//healthBar = new Bar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		//healthBar = new ImageBar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.85 /*0.88*/: 0.06 /*0.12*/), healthBars[0], healthBars[1], FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]), function() return health, 0, 2);
		healthBar = new ImageBar(0, FlxG.height * (!ClientPrefs.data.downScroll ? 0.85 /*0.88*/: 0.06 /*0.12*/), healthBarSettings, FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]), FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]), function() return health, 0, 2);
		healthBar.screenCenter(X);
		healthBar.leftToRight = false;
		healthBar.scrollFactor.set();
		healthBar.visible = !ClientPrefs.data.hideHud;
		healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		reloadHealthBarColors();
		uiGroup.add(healthBar);
		healthBar.healthLerp = true; // Lerping Works

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		//iconP1.y = healthBar.y - 75;
		iconP1.y = healthBar.y - 50;
		iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		//iconP2.y = healthBar.y - 75;
		iconP2.y = healthBar.y - 50;
		iconP2.visible = !ClientPrefs.data.hideHud;
		iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP2);
		
		iconsAnimator = new IconsAnimator(iconP1, iconP2, iconP1.y);

		scoreTxt = new FlxText(0, healthBar.y + 70/*40*/, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 14 : 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = !ClientPrefs.data.hideHud;
		uiGroup.add(scoreTxt);

		botplayTxt = new FlxText(400, healthBar.y - 90, FlxG.width - 800, Language.getPhrase("Botplay").toUpperCase(), 32);
		botplayTxt.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 20 : 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		uiGroup.add(botplayTxt);
		if(ClientPrefs.data.downScroll)
			botplayTxt.y = healthBar.y + 70;

		uiGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		comboGroup.cameras = [camHUD];
		creditsGroup.cameras = [camOther];

		// Below didn't work so I shall give it a fix
		//var path = File.getContent(Paths.json(songName + '/credits')); 
		var path = "";
		if (FileSystem.exists(Paths.json(songName + '/credits'))) {
			path = File.getContent(Paths.json(songName + '/credits'));
		} 
		#if MODS_ALLOWED
		else 
		if (FileSystem.exists(Paths.modsJson(songName + '/credits'))){
			path = File.getContent(Paths.modsJson(songName + '/credits'));
		}
		#end
		else {
			path = '
			{
				"artist": "Unknown",
				"charter": "Unknown"
			}
			';		
		}

		var jsonObj = tjson.TJSON.parse(path);

		//creditsBG = new FlxSprite(-2500, 300).loadGraphic(Paths.image('rectangulofeo')).makeGraphic(2400, 170);
		//creditsBG.color = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var dadColor:FlxColor = FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]);
		var bfColor:FlxColor = FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]);
		creditsBG = FlxGradient.createGradientFlxSprite(2400, 170, [dadColor, dadColor, bfColor, bfColor, bfColor], 1, 0, false); // 2:3 ratio to make it look better
		creditsBG.x = -2500;
		creditsBG.y = 300;
		creditsFrontBG = new FlxSprite(-2500, 300);
		creditsFrontBG.makeGraphic(2400, 150, FlxColor.BLACK);

		creditsDisk = new FlxSprite(-1175, 300).loadGraphic(Paths.image("disk"));
		creditsDisk.setGraphicSize(Std.int(creditsDisk.width * 0.65));

		var textX:Int = -575;
		var creditsTextSize:Int = 25;

		creditsSongTitle = new FlxText(textX, 330);
		creditsSongTitle.text = "Now Playing  :  " + curSong;
		creditsSongTitle.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 20 : 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		creditsSongTitle.size = creditsTextSize;

		creditsArtist = new FlxText(textX, creditsSongTitle.y + 40);
		creditsArtist.text = "By: " + jsonObj.artist;
		creditsArtist.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 20 : 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		creditsArtist.size = creditsTextSize;

		creditsCharter = new FlxText(textX, creditsArtist.y + 40);
		creditsCharter.text = "Charter: " + jsonObj.charter;
		creditsCharter.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 20 : 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		creditsCharter.size = creditsTextSize;

		creditsIconP = new HealthIcon(boyfriend.healthIcon, true);
		creditsIconP.x = -170;
		creditsIconP.y = 315;

		creditsIconEn = new HealthIcon(dad.healthIcon, false);
		creditsIconEn.x = -170;
		creditsIconEn.y = 315; 

		creditsGroup.add(creditsBG);
		creditsGroup.add(creditsFrontBG);
		creditsGroup.add(creditsDisk);
		creditsGroup.add(creditsIconP);
		creditsGroup.add(creditsIconEn);
		creditsGroup.add(creditsArtist);
		creditsGroup.add(creditsSongTitle);
		creditsGroup.add(creditsCharter);
		creditsGroup.visible = ClientPrefs.data.showSongCredits;

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		if(eventNotes.length > 0) {
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}
		startCallback();
		RecalculateRating(false, false);

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');
		if(!ClientPrefs.data.ghostTapping) for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath(ClientPrefs.data.pauseMusic) != 'none')
			Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic));

		resetRPC();

		stagesFunc(function(stage:BaseStage) stage.createPost());
		callOnScripts('onCreatePost');
		
		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		var songTitleCased:String = songName.replace('-', ' ').toUpperCase();
		WindowUtils.changeDefaultTitle(WindowUtils.DEFAULT_TITLE); // Just doing this in case of things like restarting song
		WindowUtils.changeDefaultTitle(WindowUtils.baseTitle + ' - $songTitleCased', true);

		super.create();
		Paths.clearUnusedMemory();

		cacheCountdown();
		cachePopUpScore();

		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.offset = Reflect.hasField(PlayState.SONG, 'offset') ? (PlayState.SONG.offset / value) : 0;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		#if VIDEOS_ALLOWED
		if(videoCutscene != null && videoCutscene.videoSprite != null) videoCutscene.videoSprite.bitmap.rate = value;
		#end
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	public function reloadHealthBarColors() {
		healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(Iris.instances.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String):Dynamic
		return variables.get(tag);

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public var videoCutscene:VideoSprite = null;
	public function startVideo(name:String, forMidSong:Bool = false, canSkip:Bool = true, loop:Bool = false, playOnLoad:Bool = true)
	{
		#if VIDEOS_ALLOWED
		inCutscene = !forMidSong;
		canPause = forMidSong;

		var foundFile:Bool = false;
		var fileName:String = Paths.video(name);

		#if sys
		if (FileSystem.exists(fileName))
		#else
		if (OpenFlAssets.exists(fileName))
		#end
		foundFile = true;

		if (foundFile)
		{
			videoCutscene = new VideoSprite(fileName, forMidSong, canSkip, loop);
			if(forMidSong) videoCutscene.videoSprite.bitmap.rate = playbackRate;

			// Finish callback
			if (!forMidSong)
			{
				function onVideoEnd()
				{
					if (!isDead && generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
					{
						moveCameraSection();
						FlxG.camera.snapToTarget();
					}
					videoCutscene = null;
					canPause = true;
					inCutscene = false;
					startAndEnd();
				}
				videoCutscene.finishCallback = onVideoEnd;
				videoCutscene.onSkip = onVideoEnd;
			}
			if (GameOverSubstate.instance != null && isDead) GameOverSubstate.instance.add(videoCutscene);
			else add(videoCutscene);

			if (playOnLoad)
				videoCutscene.play();
			return videoCutscene;
		}
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		else addTextToDebug("Video not found: " + fileName, FlxColor.RED);
		#else
		else FlxG.log.error("Video not found: " + fileName);
		#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		#end
		return null;
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			canPause = true;
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted');

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${uiPrefix}UI/ready${uiPostfix}', '${uiPrefix}UI/set${uiPostfix}', '${uiPrefix}UI/go${uiPostfix}'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.data.antialiasing && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], antialias);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], antialias);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], antialias);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
				}

				if(!skipArrowStartTween)
				{
					notes.forEachAlive(function(note:Note) {
						if(ClientPrefs.data.opponentStrums || note.mustPress)
						{
							note.copyAlpha = false;
							note.alpha = note.multAlpha;
							if(ClientPrefs.data.middleScroll && !note.mustPress)
								note.alpha *= 0.35;
						}
					});
				}

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = antialias;
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	public dynamic function updateScore(miss:Bool = false, scoreBop:Bool = true)
	{
		var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
		if (ret == LuaUtils.Function_Stop)
			return;

		updateScoreText();
		if (!miss && !cpuControlled && scoreBop)
			doScoreBop();

		callOnScripts('onUpdateScore', [miss]);
	}

	public dynamic function updateScoreText()
	{
		var str:String = Language.getPhrase('rating_$ratingName', ratingName);
		if(totalPlayed != 0)
		{
			var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
			str += ' (${percent}%) - ' + Language.getPhrase(ratingFC);
		}

		var tempScore:String;
		if(!instakillOnMiss) tempScore = Language.getPhrase('score_text', 'Score: {1} | Misses: {2} | Rating: {3}', [songScore, songMisses, str]);
		else tempScore = Language.getPhrase('score_text_instakill', 'Score: {1} | Rating: {2}', [songScore, str]);
		scoreTxt.text = tempScore;
	}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		ratingFC = "";
		if(songMisses == 0)
		{
			if (bads > 0 || shits > 0) ratingFC = 'FC';
			else if (goods > 0) ratingFC = 'GFC';
			else if (sicks > 0) ratingFC = 'SFC';
		}
		else {
			if (songMisses < 10) ratingFC = 'SDCB';
			else ratingFC = 'Clear';
		}
	}

	public function doScoreBop():Void {
		if(!ClientPrefs.data.scoreZoom)
			return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time - Conductor.offset;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition < vocals.length)
		{
			vocals.time = time - Conductor.offset;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
			vocals.play();
		}
		else vocals.pause();

		if (Conductor.songPosition < opponentVocals.length)
		{
			opponentVocals.time = time - Conductor.offset;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
			opponentVocals.play();
		}
		else opponentVocals.pause();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();

		setSongTime(Math.max(0, startOnTime - 500) + Conductor.offset);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		stagesFunc(function(stage:BaseStage) stage.startSong());

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private var totalColumns: Int = 4;

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if(oppVocals != null && oppVocals.length > 0) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch (e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try
		{
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch (e:Dynamic) {}
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		try
		{
			var eventsChart:SwagSong = Song.getChart('events', songName);
			if(eventsChart != null)
				for (event in eventsChart.events) //Event Notes
					for (i in 0...event[1].length)
						makeEvent(event, i);
		}
		catch(e:Dynamic) {}

		var oldNote:Note = null;
		var sectionsData:Array<SwagSection> = PlayState.SONG.notes;
		var ghostNotesCaught:Int = 0;
		var daBpm:Float = Conductor.bpm;
	
		for (section in sectionsData)
		{
			if (section.changeBPM != null && section.changeBPM && section.bpm != null && daBpm != section.bpm)
				daBpm = section.bpm;

			for (i in 0...section.sectionNotes.length)
			{
				final songNotes: Array<Dynamic> = section.sectionNotes[i];
				var spawnTime: Float = songNotes[0];
				var noteColumn: Int = Std.int(songNotes[1] % totalColumns);
				var holdLength: Float = songNotes[2];
				var noteType: String = !Std.isOfType(songNotes[3], String) ? Note.defaultNoteTypes[songNotes[3]] : songNotes[3];
				if (Math.isNaN(holdLength))
					holdLength = 0.0;

				var gottaHitNote:Bool = (songNotes[1] < totalColumns);

				if (i != 0) {
					// CLEAR ANY POSSIBLE GHOST NOTES
					for (evilNote in unspawnNotes) {
						var matches: Bool = (noteColumn == evilNote.noteData && gottaHitNote == evilNote.mustPress && evilNote.noteType == noteType);
						if (matches && Math.abs(spawnTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON) {
							if (evilNote.tail.length > 0)
								for (tail in evilNote.tail) {
									tail.destroy();
									unspawnNotes.remove(tail);
								}
							evilNote.destroy();
							unspawnNotes.remove(evilNote);
							ghostNotesCaught++;
							//continue;
						}
					}
				}

				var swagNote:Note;
				if (gottaHitNote) swagNote = new Note(spawnTime, noteColumn, oldNote, boyfriend.usesPixelNotesSpecifically, noteType);
				else swagNote = new Note(spawnTime, noteColumn, oldNote, dad.usesPixelNotesSpecifically, noteType);
				var isAlt: Bool = section.altAnim && !gottaHitNote;
				swagNote.gfNote = (section.gfSection && gottaHitNote == section.mustHitSection);
				swagNote.animSuffix = isAlt ? "-alt" : "";
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = holdLength;
				swagNote.noteType = noteType;
				if (boyfriend.useNoteSkin && gottaHitNote && ClientPrefs.data.characterNoteColors == 'Enabled' && !Note.keepSkin.contains(swagNote.noteType)) {
					//swagNote.setNotePixel(boyfriend.usesPixelNotesSpecifically);
					swagNote.reloadNote(boyfriend.noteSkin, boyfriend.noteSkinLib);
				} else if (dad.useNoteSkin && !gottaHitNote && ClientPrefs.data.characterNoteColors != 'Disabled' && !Note.keepSkin.contains(swagNote.noteType)) {
					//swagNote.setNotePixel(dad.usesPixelNotesSpecifically);
					swagNote.reloadNote(dad.noteSkin, dad.noteSkinLib);
				}
				if (ClientPrefs.data.characterNoteColors != 'Disabled') {
					switch (swagNote.noteData) {
						case 0:
							if (gottaHitNote) {
								if (boyfriend.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
									if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && boyfriend.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.altNoteColors.left);
									else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.noteColors.left);
								} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
									swagNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[0] : ClientPrefs.data.arrowRGB[0]);
								}
							} else {
								if (dad.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && dad.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.altNoteColors.left);
								else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.noteColors.left);
							}
						case 1:
							if (gottaHitNote) {
								if (boyfriend.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
									if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && boyfriend.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.altNoteColors.down);
									else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.noteColors.down);
								} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
									swagNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[1] : ClientPrefs.data.arrowRGB[1]);
								}
							} else {
								if (dad.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && dad.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.altNoteColors.down);
								else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.noteColors.down);
							}
						case 2:
							if (gottaHitNote) {
								if (boyfriend.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
									if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && boyfriend.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.altNoteColors.up);
									else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.noteColors.up);
								} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
									swagNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[2] : ClientPrefs.data.arrowRGB[2]);
								}
							} else {
								if (dad.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && dad.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.altNoteColors.up);
								else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.noteColors.up);
							}
						case 3:
							if (gottaHitNote) {
								if (boyfriend.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
									if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && boyfriend.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.altNoteColors.right);
									else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(boyfriend.noteColors.right);
								} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
									swagNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[3] : ClientPrefs.data.arrowRGB[3]);
								}
							} else {
								if (dad.disableNoteRGB) swagNote.rgbShader.enabled = false;
								else if ((swagNote.noteType == 'Alt Animation' || swagNote.animSuffix == '-alt') && dad.hasAltColors && !swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.altNoteColors.right);
								else if (!swagNote.noCharShader) swagNote.rgbShader.changeRGB(dad.noteColors.right);
							}
					}
				}
	
				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
				final roundSus:Int = Math.round(swagNote.sustainLength / curStepCrochet);
				if(roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note;
						if (gottaHitNote) sustainNote = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, boyfriend.usesPixelNotesSpecifically, swagNote.noteType, true);
						else sustainNote = new Note(spawnTime + (curStepCrochet * susNote), noteColumn, oldNote, dad.usesPixelNotesSpecifically, swagNote.noteType, true);
						sustainNote.animSuffix = swagNote.animSuffix;
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;

						if (boyfriend.useNoteSkin && gottaHitNote && ClientPrefs.data.characterNoteColors == 'Enabled' && !Note.keepSkin.contains(sustainNote.noteType)) {
							//sustainNote.setNotePixel(boyfriend.usesPixelNotesSpecifically);
							sustainNote.reloadNote(boyfriend.noteSkin, boyfriend.noteSkinLib);
						} else if (dad.useNoteSkin && !gottaHitNote && ClientPrefs.data.characterNoteColors != 'Disabled' && !Note.keepSkin.contains(sustainNote.noteType)) {
							//sustainNote.setNotePixel(dad.usesPixelNotesSpecifically);
							sustainNote.reloadNote(dad.noteSkin, dad.noteSkinLib);
						}

						if (ClientPrefs.data.characterNoteColors != 'Disabled') {
							switch (sustainNote.noteData) {
								case 0:
									if (gottaHitNote) {
										if (boyfriend.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
											if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && boyfriend.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.altNoteColors.left);
											else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.noteColors.left);
										} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
											sustainNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[0] : ClientPrefs.data.arrowRGB[0]);
										}
									} else {
										if (dad.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && dad.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.altNoteColors.left);
										else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.noteColors.left);
									}
								case 1:
									if (gottaHitNote) {
										if (boyfriend.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
											if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && boyfriend.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.altNoteColors.down);
											else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.noteColors.down);
										} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
											sustainNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[1] : ClientPrefs.data.arrowRGB[1]);
										}
									} else {
										if (dad.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && dad.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.altNoteColors.down);
										else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.noteColors.down);
									}
								case 2:
									if (gottaHitNote) {
										if (boyfriend.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
											if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && boyfriend.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.altNoteColors.up);
											else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.noteColors.up);
										} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
											sustainNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[2] : ClientPrefs.data.arrowRGB[2]);
										}
									} else {
										if (dad.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && dad.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.altNoteColors.up);
										else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.noteColors.up);
									}
								case 3:
									if (gottaHitNote) {
										if (boyfriend.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if (ClientPrefs.data.characterNoteColors == 'Enabled') {
											if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && boyfriend.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.altNoteColors.right);
											else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(boyfriend.noteColors.right);
										} else if (ClientPrefs.data.characterNoteColors == 'Opponent\nOnly') {
											sustainNote.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[3] : ClientPrefs.data.arrowRGB[3]);
										}
									} else {
										if (dad.disableNoteRGB) sustainNote.rgbShader.enabled = false;
										else if ((sustainNote.noteType == 'Alt Animation' || sustainNote.animSuffix == '-alt') && dad.hasAltColors && !sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.altNoteColors.right);
										else if (!sustainNote.noCharShader) sustainNote.rgbShader.changeRGB(dad.noteColors.right);
									}
							}
						}

						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						var isPixel:Bool = PlayState.isPixelStage || swagNote.isNotePixel();
						if(!isPixel)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
							}

							if(ClientPrefs.data.downScroll)
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(noteColumn > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.data.middleScroll)
				{
					swagNote.x += 310;
					if(noteColumn > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}
				if(!noteTypes.contains(swagNote.noteType))
					noteTypes.push(swagNote.noteType);

				oldNote = swagNote;
			}
		}
		trace('["${SONG.song.toUpperCase()}" CHART INFO]: Ghost Notes Cleared: $ghostNotesCaught');
		for (event in songData.events) //Event Notes
			for (i in 0...event[1].length)
				makeEvent(event, i);

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		eventPushedUnique(event);
		if(eventsPushed.contains(event.event)) {
			return;
		}

		stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
		eventsPushed.push(event.event);
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true);
		if(returnedValue != null && returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		var subEvent:EventNote = {
			strumTime: event[0] + ClientPrefs.data.noteOffset,
			event: event[1][i][0],
			value1: event[1][i][1],
			value2: event[1][i][2]
		};
		eventNotes.push(subEvent);
		eventPushed(subEvent);
		callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
	}

	function skinChosen(player:Int, lib:Bool):String {
		if (ClientPrefs.data.characterNoteColors == 'Enabled' && player == 1 && boyfriend.useNoteSkin) {
			if (lib) return boyfriend.noteSkinLib;
			else return boyfriend.noteSkin;
		} else if (ClientPrefs.data.characterNoteColors != 'Disabled' && player == 0 && dad.useNoteSkin) {
			if (lib) return dad.noteSkinLib;
			else return dad.noteSkin;
		} else {
			if (lib) return 'shared';
			else return 'noteSkins/NOTE_assets' + Note.getNoteSkinPostfix();
		}
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player, skinChosen(player, false), skinChosen(player, true));

			var strumCover:StrumCover;
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else babyArrow.alpha = targetAlpha;

			if (player == 1) {
				babyArrow.pixelNote = boyfriend.usesPixelNotesSpecifically;
				babyArrow.reloadNote();
				strumCover = new StrumCover(babyArrow, boyfriend.strumSkin, boyfriend.strumSkinLib);
				if (ClientPrefs.data.characterNoteColors == 'Enabled') {
					if (boyfriend.disableNoteRGB) {
						babyArrow.disableRGB = true;
						strumCover.rgbShader.enabled = false;
					} else {
						switch (i) {
							case 0:
								babyArrow.rgbShader.changeRGB(boyfriend.noteColors.left);
								strumCover.rgbShader.changeRGB(boyfriend.noteColors.left);
							case 1:
								babyArrow.rgbShader.changeRGB(boyfriend.noteColors.down);
								strumCover.rgbShader.changeRGB(boyfriend.noteColors.down);
							case 2:
								babyArrow.rgbShader.changeRGB(boyfriend.noteColors.up);
								strumCover.rgbShader.changeRGB(boyfriend.noteColors.up);
							case 3:
								babyArrow.rgbShader.changeRGB(boyfriend.noteColors.right);
								strumCover.rgbShader.changeRGB(boyfriend.noteColors.right);
						}
					}
					babyArrow.rgbShader.enabled = false;
				} else {
					babyArrow.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[i] : ClientPrefs.data.arrowRGB[i]);
					strumCover.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[i] : ClientPrefs.data.arrowRGB[i]);
					babyArrow.rgbShader.enabled = false;
				}

				playerStrums.add(babyArrow);
				playerCovers.add(strumCover);
			} else {
				babyArrow.pixelNote = dad.usesPixelNotesSpecifically;
				babyArrow.reloadNote();
				strumCover = new StrumCover(babyArrow, dad.strumSkin, dad.strumSkinLib);
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				if (ClientPrefs.data.characterNoteColors != 'Disabled') {
					if (dad.disableNoteRGB) {
						babyArrow.disableRGB = true;
						strumCover.rgbShader.enabled = false;
					} else {
						switch (i) {
							case 0:
								babyArrow.rgbShader.changeRGB(dad.noteColors.left);
								strumCover.rgbShader.changeRGB(dad.noteColors.left);
							case 1:
								babyArrow.rgbShader.changeRGB(dad.noteColors.down);
								strumCover.rgbShader.changeRGB(dad.noteColors.down);
							case 2:
								babyArrow.rgbShader.changeRGB(dad.noteColors.up);
								strumCover.rgbShader.changeRGB(dad.noteColors.up);
							case 3:
								babyArrow.rgbShader.changeRGB(dad.noteColors.right);
								strumCover.rgbShader.changeRGB(dad.noteColors.right);
						}
					}
					babyArrow.rgbShader.enabled = false;
				} else {
					babyArrow.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[i] : ClientPrefs.data.arrowRGB[i]);
					strumCover.rgbShader.changeRGB(isPixelStage ? ClientPrefs.data.arrowRGBPixel[i] : ClientPrefs.data.arrowRGB[i]);
					babyArrow.rgbShader.enabled = false;
				}
				opponentStrums.add(babyArrow);
				//if (dad.useNoteSkin && dad.disableNoteRGB) babyArrow.rgbShader.enabled = false;
				opponentCovers.add(strumCover);
			}

			strumLineNotes.add(babyArrow);
			if (strumCover != null) strumLineCovers.add(strumCover);
			babyArrow.playerPosition();
			if (player == 1) defaultStrumPosition.insert(i + 4, [babyArrow.x, babyArrow.y]);
			else defaultStrumPosition.insert(i, [babyArrow.x, babyArrow.y]);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
		}

		super.openSubState(SubState);
	}

	public var canResync:Bool = true;
	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong && canResync)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	#if DISCORD_ALLOWED
	override public function onFocus():Void
	{
		super.onFocus();
		if (!paused && health > 0) {
			resetRPC(Conductor.songPosition > 0.0);
		}
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		if (!paused && health > 0 && autoUpdateRPC) {
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
	}
	#end
//All this functions are adapted from FNF's original code (emojiConLEnguaDeDinero)
	public function resetCamera(?resetZoom:Bool = true, ?cancelTweens:Bool = true):Void
		{
			// Cancel camera tweens if any are active.
			if (cancelTweens)
			{
				cancelAllCameraTweens();
			}
		  
			FlxG.camera.follow(camFollow, LOCKON, 0);
			FlxG.camera.targetOffset.set();
		  
			if (resetZoom)
			{
				resetCameraZoom();
			}
		  
		}
	
		public function tweenCameraToPosition(?x:Float, ?y:Float, ?duration:Float, ?ease:Null<Float->Float>):Void
		{
			camFollow.setPosition(x, y);
			tweenCameraToFollowPoint(duration, ease);
		}
	
		public function resetCameraZoom():Void
		{
			// Apply camera zoom level from stage data.
			FlxG.camera.zoom = defaultCamZoom;
		  
		}
		  
		public function tweenCameraToFollowPoint(?duration:Float, ?ease:Null<Float->Float>):Void
		{
			// Cancel the current tween if it's active.
			cancelCameraFollowTween();
		  
			if (duration == 0)
			{
			// Instant movement. Just reset the camera to force it to the follow point.
				resetCamera(false, false);
			}
			else
			{
				// Follow tween! Caching it so we can cancel/pause it later if needed.
				var followPos:FlxPoint = camFollow.getPosition() - FlxPoint.weak(FlxG.camera.width * 0.5, FlxG.camera.height * 0.5);
				cameraFollowTween = FlxTween.tween(FlxG.camera.scroll, {x: followPos.x, y: followPos.y}, duration,
				{
					ease: ease,
					onComplete: function(_) {
					  resetCamera(false, false); // Re-enable camera following when the tween is complete.
					}
				});
			}
		}
		  
		public function cancelCameraFollowTween()
		{
			if (cameraFollowTween != null)
			{
				cameraFollowTween.cancel();
			}
		}
		  
		public function tweenCameraZoom(?zoom:Float, ?duration:Float, ?direct:Bool, ?ease:Null<Float->Float>):Void
		{
			// Cancel the current tween if it's active.
			cancelCameraZoomTween();
		  
			// Direct mode: Set zoom directly.
			// Stage mode: Set zoom as a multiplier of the current stage's default zoom.
			var targetZoom = zoom * (direct ? FlxCamera.defaultZoom : defaultCamZoom);
		  
			if (duration == 0)
			{
				// Instant zoom. No tween needed.
				FlxG.camera.zoom = targetZoom;
			}
			else
			{
				// Zoom tween! Caching it so we can cancel/pause it later if needed.
				cameraZoomTween = FlxTween.tween(FlxG.camera, {zoom: targetZoom}, duration, {ease: ease});
			}
		}
		  
		public function cancelCameraZoomTween()
		{
			if (cameraZoomTween != null)
			{
				cameraZoomTween.cancel();
			}
		}
		  
		public function cancelAllCameraTweens()
		{
			cancelCameraFollowTween();
			cancelCameraZoomTween();
		}
	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		trace('resynced vocals at ' + Math.floor(Conductor.songPosition));

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		var checkVocals = [vocals, opponentVocals];
		for (voc in checkVocals)
		{
			if (FlxG.sound.music.time < vocals.length)
			{
				voc.time = FlxG.sound.music.time;
				#if FLX_PITCH voc.pitch = playbackRate; #end
				voc.play();
			}
			else voc.pause();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	override public function update(elapsed:Float)
		{
			if(!inCutscene && !paused && !freezeCamera) {
				FlxG.camera.followLerp = 0.04 * cameraSpeed * playbackRate;
				var idleAnim:Bool = (boyfriend.getAnimationName().startsWith('idle') || boyfriend.getAnimationName().startsWith('danceLeft') || boyfriend.getAnimationName().startsWith('danceRight'));
				if(!startingSong && !endingSong && idleAnim) {
					boyfriendIdleTime += elapsed;
					if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
						boyfriendIdled = true;
					}
				} else {
					boyfriendIdleTime = 0;
				}
	
				if(!isCameraOnForcedPos && !inCutscene)
				{
					if(focusedChar == dad)
					{
						camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
						camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
						tweenCamIn();
					}
					if(focusedChar == boyfriend)
					{
						camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
						camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
						camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
				
						if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
						{
							cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
								function (twn:FlxTween)
								{
									cameraTwn = null;
								}
							});
						}
					}
					if(focusedChar == gf)
					{
						camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
						camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
						camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
						tweenCamIn();
					}
					if(focusedChar.animation.curAnim!=null){
						if(focusedChar.getAnimationName().startsWith('idle')){ curNote = 69; }
						else
						if(focusedChar.getAnimationName().startsWith('dance')){ curNote = 69; }
						switch (curNote){
							case 2:
								camFollow.y -=  ClientPrefs.data.extraCamMovementAmount;
							case 1:
								camFollow.y +=  ClientPrefs.data.extraCamMovementAmount;
							case 0:
								camFollow.x -=  ClientPrefs.data.extraCamMovementAmount;
							case 3:
								camFollow.x +=  ClientPrefs.data.extraCamMovementAmount;
						}
					}
				}
	
			}
		else FlxG.camera.followLerp = 0;
		callOnScripts('onUpdate', [elapsed]);

		for (i in 0...lerpSpeeds.length) {
			if (lerpTweens[i] != null) lerpSpeeds[i] = lerpTweens[i].value;
		}
		if (wobbleNotes) {
			for (i in 0...playerStrums.length) {
				playerStrums.members[i].x = FlxMath.lerp(playerStrums.members[i].x, defaultStrumPosition[i + 4][0] + (playerStrumsWobble[0] * Math.sin(((((Conductor.songPosition) / 1000) * (Conductor.bpm / 60)) + (i + 4) * 0.25) * Math.PI)), lerpSpeeds[0]); // Man I love having parentheses embeded into parentheses embeded into parentheses embeded into parentheses embeded into parentheses, it's quite fun - Torch
				playerStrums.members[i].y = FlxMath.lerp(playerStrums.members[i].y, defaultStrumPosition[i + 4][1] + (playerStrumsWobble[1] * Math.cos(((((Conductor.songPosition) / 1000) * (Conductor.bpm / 60)) + (i + 4) * 0.25) * Math.PI)), lerpSpeeds[1]); // Man I love having parentheses embeded into parentheses embeded into parentheses embeded into parentheses embeded into parentheses, it's quite fun - Torch
			}
	
			for (i in 0...opponentStrums.length) {
				opponentStrums.members[i].x = FlxMath.lerp(opponentStrums.members[i].x, defaultStrumPosition[i][0] + (opponentStrumsWobble[0] * Math.sin(((((Conductor.songPosition) / 1000) * (Conductor.bpm / 60)) + i * 0.25) * Math.PI)), lerpSpeeds[2]); // Man I love having parentheses embeded into parentheses embeded into parentheses embeded into parentheses embeded into parentheses, it's quite fun - Torch
				opponentStrums.members[i].y = FlxMath.lerp(opponentStrums.members[i].y, defaultStrumPosition[i][1] + (opponentStrumsWobble[1] * Math.cos(((((Conductor.songPosition) / 1000) * (Conductor.bpm / 60)) + i * 0.25) * Math.PI)), lerpSpeeds[3]); // Man I love having parentheses embeded into parentheses embeded into parentheses embeded into parentheses embeded into parentheses, it's quite fun - Torch
			}
		} else {
			for (i in 0...opponentStrums.length) {
				opponentStrums.members[i].x = FlxMath.lerp(opponentStrums.members[i].x, defaultStrumPosition[i][0], lerpSpeeds[2]);
				opponentStrums.members[i].y = FlxMath.lerp(opponentStrums.members[i].y, defaultStrumPosition[i][1], lerpSpeeds[3]);
			}
			for (i in 0...playerStrums.length) {
				playerStrums.members[i].x = FlxMath.lerp(playerStrums.members[i].x, defaultStrumPosition[i + 4][0], lerpSpeeds[0]);
				playerStrums.members[i].y = FlxMath.lerp(playerStrums.members[i].y, defaultStrumPosition[i + 4][1], lerpSpeeds[1]);
			}
		}

		super.update(elapsed);

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnScripts('onPause', null, true);
			if(ret != LuaUtils.Function_Stop) {
				openPauseMenu();
			}
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1'))
				openChartEditor();
			else if (controls.justPressed('debug_2'))
				openCharacterEditor();
		}

		if (healthBar.bounds.max != null && health > healthBar.bounds.max)
			health = healthBar.bounds.max;

		updateIconsScale(elapsed);
		iconsAnimator.updateIconsPosition();

		if (startedCountdown && !paused)
		{
			Conductor.songPosition += elapsed * 1000 * playbackRate;
			if (Conductor.songPosition >= Conductor.offset)
			{
				Conductor.songPosition = FlxMath.lerp(FlxG.sound.music.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 5));
				var timeDiff:Float = Math.abs((FlxG.sound.music.time + Conductor.offset) - Conductor.songPosition);
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= Conductor.offset)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5 + Conductor.offset;
		}
		else if (!paused && updateTime)
		{
			var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			songPercent = (curTime / songLength);

			var songCalc:Float = (songLength - curTime);
			if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if(secondsTotal < 0) secondsTotal = 0;

			if(ClientPrefs.data.timeBarType != 'Song Name')
				timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);

			WindowUtils.changeTitle(WindowUtils.baseTitle + " - " + FlxStringUtil.formatTime(secondsTotal, false));
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.data.noReset && controls.RESET && canReset && !inCutscene && startedCountdown && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();
				else
					playerDance();

				if(notes.length > 0)
				{
					if(startedCountdown)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						var i:Int = 0;
						while(i < notes.length)
						{
							var daNote:Note = notes.members[i];
							if(daNote == null) continue;

							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress)
							{
								if(cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
							if(daNote.exists) i++;
						}
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);

		playerCovers.forEach(function(c:StrumCover) {
			for (i in 0...keysArray.length) {
				if (!controls.pressed(keysArray[i]) && i == c.strumNote.noteData && c.animation.curAnim.name == 'hold' && !cpuControlled && c.visible != false) c.end();
			}

			for (thing in playerStrums.members) {
				if (thing.noteData == c.strumNote.noteData && thing.animation.curAnim.name != 'confirm' && !c.endAnimAlreadyPlayed) c.end();
			}
		});

		opponentCovers.forEach(function(c:StrumCover) {
			if (c.animation.curAnim.name == 'hold' && !enemyCoverSplashes) c.end();
			
			for (thing in opponentStrums.members) {
				if (thing.noteData == c.strumNote.noteData && thing.animation.curAnim.name != 'confirm' && !c.endAnimAlreadyPlayed) c.end(); 
			}
		});

		if (maxCombo < combo) maxCombo = combo;
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	var iconsAnimations:Bool = true;
	function set_health(value:Float):Float // You can alter how icon animations work here
	{
		value = FlxMath.roundDecimal(value, 5); //Fix Float imprecision
		if(!iconsAnimations || healthBar == null || !healthBar.enabled || healthBar.valueFunction == null)
		{
			health = value;
			return health;
		}

		// update health bar
		health = value;
		var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
		healthBar.percent = (newPercent != null ? newPercent : 0);

		//iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
		//iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)

		if (healthBar.percent < 30) // Player Losing
			iconP1.animation.curAnim.curFrame = healthBar.leftToRight ? 2 : 1;
		else if (healthBar.percent > 75) // Player Winning
			iconP1.animation.curAnim.curFrame = healthBar.leftToRight ? 1 : 2;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 75) // Enemy Losing
			iconP2.animation.curAnim.curFrame = healthBar.leftToRight ? 2 : 1;
		else if (healthBar.percent < 30) // Enemy Winning
			iconP2.animation.curAnim.curFrame = healthBar.leftToRight ? 1 : 2;
		else
			iconP2.animation.curAnim.curFrame = 0;

		return health;
	}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		chartingMode = true;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		canResync = false;
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		if(vocals != null)
			vocals.pause();
		if(opponentVocals != null)
			opponentVocals.pause();

		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	public var gameOverTimer:FlxTimer;
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead && gameOverTimer == null)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop)
			{
				FlxG.animationTimeScale = 1;
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;
				canResync = false;
				canPause = false;
				#if VIDEOS_ALLOWED
				if(videoCutscene != null)
				{
					videoCutscene.destroy();
					videoCutscene = null;
				}
				#end

				persistentUpdate = false;
				persistentDraw = false;
				FlxTimer.globalManager.clear();
				FlxTween.globalManager.clear();
				FlxG.camera.setFilters([]);

				if(GameOverSubstate.deathDelay > 0)
				{
					gameOverTimer = new FlxTimer().start(GameOverSubstate.deathDelay, function(_)
					{
						vocals.stop();
						opponentVocals.stop();
						FlxG.sound.music.stop();
						openSubState(new GameOverSubstate(boyfriend));
						gameOverTimer = null;
					});
				}
				else
				{
					vocals.stop();
					opponentVocals.stop();
					FlxG.sound.music.stop();
					openSubState(new GameOverSubstate(boyfriend));
				}

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	var zoomTweens:Array<FlxTween> = [null];
	public var eventExisted:Bool = true;
    public var shadowEffects:Array<Array<ShadowEffect.Shadow>> = [];

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;
		
		eventExisted = true;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(ClientPrefs.data.camZooms && FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					FlxG.camera.zoom += flValue1;
					camHUD.zoom += flValue2;
				}

			case "Enemy Splashes":
				var val1:Bool = (value1.toLowerCase().trim() == 'true');
				var val2:Bool = (value2.toLowerCase().trim() == 'true');
				enemyNoteSplashes = val1;
				enemyCoverSplashes = val2;

			case 'Updated Camera Zoom' | "Torch's Custom Zoom": 
				// I will not remove the old one, instead, I will just add my own. Eventually, I will get to replacing the old ones to use my new zoom function.
				// The only reason this is also labeled "Torch's Custom Zoom" is for compatibilty with old charts that use my old event name. 
				if (ClientPrefs.data.camZooms) {
					var val1:String = 'regular';
					if (value1 != null && value1 != 'regular' && value1 != '') val1 = value1.toLowerCase().trim();
					var vals2:Array<String> = value2.split(',');

					var zoomAmount:Float = Std.parseFloat(vals2[0].trim());
					var zoomTime:Float = Std.parseFloat(vals2[1].trim());
					var easeType:EaseFunction = Extras.stringToEase(vals2[2].trim());

					if (zoomTweens[0] != null && (val1 == 'main' || val1 == 'both' || val1 == 'reset')) zoomTweens[0].cancel();
					if (zoomTweens[1] != null && (val1 == 'hud' || val1 == 'both' || val1 == 'reset')) zoomTweens[1].cancel();

					switch (val1) {
						case 'main':
							zoomTweens[0] = FlxTween.tween(camGame, {zoom: zoomAmount}, zoomTime, {ease: easeType,
							onComplete: function(t:FlxTween) {
								defaultCamZoom = camGame.zoom;
							}});
						case 'hud':
							zoomTweens[1] = FlxTween.tween(camHUD, {zoom: zoomAmount}, zoomTime, {ease: easeType});
						case 'both':
							zoomTweens[1] = FlxTween.tween(camHUD, {zoom: zoomAmount}, zoomTime, {ease: easeType});
							zoomTweens[0] = FlxTween.tween(camGame, {zoom: zoomAmount}, zoomTime, {ease: easeType,
							onComplete: function(t:FlxTween) {
								defaultCamZoom = camGame.zoom;
							}});
						case 'reset':
							zoomTweens[1] = FlxTween.tween(camHUD, {zoom: 1}, 0.5, {ease: FlxEase.linear});
							zoomTweens[0] = FlxTween.tween(camGame, {zoom: StageData.getStageFile(SONG.stage).defaultZoom}, 0.5, {ease: FlxEase.linear,
							onComplete: function(t:FlxTween) {
								defaultCamZoom = camGame.zoom;
							}});
						case "soft" | "soft reset" | "sr":
							zoomTweens[1] = FlxTween.tween(camHUD, {zoom: 1}, zoomTime, {ease: easeType});
							zoomTweens[0] = FlxTween.tween(camGame, {zoom: StageData.getStageFile(SONG.stage).defaultZoom}, zoomTime, {ease: easeType,
							onComplete: function(t:FlxTween) {
								defaultCamZoom = camGame.zoom;
							}});
						default:
							FlxG.camera.zoom += zoomAmount;
							camHUD.zoom += zoomAmount;
					}
				}

			case "Wobble Notes" | "Wobbly Notes": // I am doing a simply rename to Wobbly because I felt that made more sense grammatically 
				var vals1:Array<String> = value1.trim().split(',');
				var val1:Array<Null<Int>> = [Std.parseInt(vals1[0]), Std.parseInt(vals1[1])];
				var who:String = 'none';
				
				switch (value2.toLowerCase().trim()) {
					case 'enemy' | 'dad' | 'opponent' | 'opp' | 'p1':
						strumsWobbled[0] = true;
						who = "dad";
					case 'player' | 'bf' | 'boyfriend' | 'p2':
						strumsWobbled[1] = true;
						who = 'bf';
					case 'none' | 'stop' | 'disable' | 'neither' | 'end':
						strumsWobbled = [false, false];
						val1[0] = 0;
						val1[1] = 0;
						who = "none";
					case 'both' | 'together':
						strumsWobbled = [true, true];
						who = 'both';
					case 'stop1' | 'stopopponent' | 'stopdad' | 'stopenemy' | 'stopleft' | 'stopopp' | 'stopp1':
						strumsWobbled[0] = false;
						val1[0] = 0;
						val1[1] = 0;
						who = 'dad';
					case 'stop2' | 'stopbf' | 'stopplayer' | 'stopright' | 'stopp2':
						strumsWobbled[1] =  false;
						val1[0] = 0;
						val1[1] = 0;
						who = 'bf';
				}

				for (i in 0...lerpSpeeds.length) {
					lerpSpeeds[i] = 0;
					if (lerpTweens[i] != null) lerpTweens[i].cancel();
					lerpTweens[i] = FlxTween.num(lerpSpeeds[i], 1.0, 5.0);
				}

				if ((val1[0] == 0 || val1[0] == null) && (val1[1] == 0 || val1[1] == null)) wobbleNotes = false;
				else {
					if (val1[0] != null && val1[1] != null) {
						switch (who) {
							case "dad":
								opponentStrumsWobble = [val1[0], val1[1]];
							case "bf":
								playerStrumsWobble = [val1[0], val1[1]];
							case "both":
								opponentStrumsWobble = [val1[0], val1[1]];
								playerStrumsWobble = [val1[0], val1[1]];
							case "none":
								opponentStrumsWobble = [0,0];
								playerStrumsWobble = [0,0];
						}
					}

					if (strumsWobbled[0] || strumsWobbled[1]) { //The false is honestly just a failsafe
						wobbleNotes = true;
					} /*else if (strumsWobbled[0] && !strumsWobbled[1]) {
						wobbleNotes = true;
						playerStrumsWobble = [0,0];
					} else if (!strumsWobbled[0] && strumsWobbled[1]) {
						wobbleNotes = true;
						opponentStrumsWobble = [0,0];
					}*/ else {
						wobbleNotes = false;
						playerStrumsWobble = [0,0];
						opponentStrumsWobble = [0,0];
					}
				}
				
			case "Spawn Shadow":
				var vals1:Array<String> = [];
				vals1 = value1.split(',');

				var color:FlxColor = 0xFF009CB1;
				if (vals1[2] != null && vals1[2] != '') {
					color = FlxColor.fromString(vals1[2].trim());
				}

				var vals2:Array<String> = [];
				if (value2 != null && value2 != '') 
					vals2 = value2.split(',');
				if (Std.parseInt(vals2[2].trim()) > 10) vals2[2] = '10';
				function grabObject(name:String) {
					switch (name) { // Eventually, I this to be able to edit whatever object you add to it
						case 'dad', 'enemy':
							return dad;
						case 'gf', 'girlfriend':
							return gf;
						case 'bf', 'player', 'boyfriend':
							return boyfriend;
						default:
							var reflect = Reflect.hasField(instance.members, name);
							if (reflect) return cast(Reflect.field(instance.members, name), Character);
							else return null;
					}
				}
				var effect = ShadowEffect.createShadows(grabObject(vals1[0].trim().toLowerCase()), color, Std.parseFloat(vals2[0].trim()), vals1[1].trim(), Std.parseInt(vals2[1].trim()), Std.parseFloat(vals2[2].trim()));
				shadowEffects.push(effect);
				for (shadow in effect) {
					switch (vals1[0].trim().toLowerCase()) {
						case 'dad', 'enemy':
							addBehindDad(shadow);
						case 'gf', 'girlfriend':
							addBehindGF(shadow);
						case 'bf', 'player', 'boyfriend':
							addBehindBF(shadow);
						default:
							var reflect = Reflect.field(instance.members, value1.trim());
							if (reflect != null) {
								insert(members.indexOf(reflect), shadow);
							}
					}
				}
			
			case 'Remove Shadow':
				for (effect in shadowEffects) {
					if (effect[0].shadowID == value1) {
						for (shadow in effect) shadow.destroy();
					}
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
                if(camFollow != null)
                {
                    isCameraOnForcedPos = false;
                    if(flValue1 != null || flValue2 != null)
                    {
                        isCameraOnForcedPos = true;
                        if(flValue1 == null) flValue1 = 0;
                        if(flValue2 == null) flValue2 = 0;

                   
                        var tweenDuration:Float = 0;
                        var tweenEase:Null<Float->Float> = null;
                        var vals:Array<String> = value2.split(",");
                        if (vals.length >= 3) {

                            var dur = Std.parseFloat(vals[1].trim());
                            if (!Math.isNaN(dur)) tweenDuration = dur;
                            var easeStr = vals[2].trim();
                            if (easeStr != "") tweenEase = Extras.stringToEase(easeStr);
                        }
                        if (tweenDuration > 0) {
                            FlxTween.tween(camFollow, {x: flValue1, y: flValue2}, tweenDuration, {ease: tweenEase});
                        } else {
                            camFollow.x = flValue1;
                            camFollow.y = flValue2;
                        }
                    }
                }

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var trueValue:Dynamic = value2.trim();
					if (trueValue == 'true' || trueValue == 'false') trueValue = trueValue == 'true';
					else if (flValue2 != null) trueValue = flValue2;
					else trueValue = value2;

					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], trueValue);
					} else {
						LuaUtils.setVarInArray(this, value1, trueValue);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			default: // I only have this file for more complicated events that need a lot of code or something
				eventExisted = false;
		}

		// These have to state that the event DOES exist by calling upon the playstate instance, so PlayState.instance.eventExisted = true;
		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		for (lua in luaArray) { // This makes sure that CustomEvents doesn't get called.
			if (lua.scriptName.contains(eventName)) {
				eventExisted = true;
				break;
			}
		}
		for (hscript in hscriptArray) { // Not sure if this one does work, just copied from Lua one above... I should probably test this huh... nah, someone'll let me know
			if (hscript.origin.contains(eventName)) {
				eventExisted = true;
				break;
			}
		}
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);

		if (!eventExisted) CustomEvents.onEvent(eventName, value1, value2);
	}

	public function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			focusedChar = gf;
			callOnScripts('onMoveCamera', ['gf']);
		}

		isDad = (SONG.notes[sec].mustHitSection != true);
 		moveCamera(isDad, sec);
 		callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
	}
	
	/*public function moveCameraToGirlfriend()
	{
		camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
		camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
		camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
		tweenCamIn();
	}*/

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool, ?sec:Null<Int>)	{
		if(sec == null) sec = curSection;
 			if(sec < 0) sec = 0;
 			if (isDad)
				{
				if (gf != null && SONG.notes[sec].gfSection)
					{
						focusedChar = gf;
					}
					else
					{
						focusedChar = dad;
					}
				}
				else
				{
					focusedChar = boyfriend;
		}
	}

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
			endCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
				endCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat
		if(!startingSong)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			});
			for (daNote in unspawnNotes)
			{
				if(daNote != null && daNote.strumTime < songLength - Conductor.safeZoneOffset)
					health -= 0.05 * healthLoss;
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', #if BASE_GAME_FILES 'debugger' #end]);
		#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			var percent:Float = ratingPercent;
			if(Math.isNaN(percent)) percent = 0;
			var oldScore:Int = Highscore.getScore(SONG.song, storyDifficulty);
			
			Highscore.saveScore(Song.loadedSongName, songScore, storyDifficulty, percent);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;
				campaignRatings[0] += ratingsData[0].hits;
				campaignRatings[1] += ratingsData[1].hits;
				campaignRatings[2] += ratingsData[2].hits;
				campaignRatings[3] += ratingsData[3].hits;
				campaignPercents.push(ratingPercent);
				campaignCombos.push(maxCombo);
				var oldWeekScore:Int = Highscore.getWeekScore(WeekData.getWeekFileName(), storyDifficulty);

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					Mods.loadTopMod();
					//FlxG.sound.playMusic(Paths.music('freakyMenu'));
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

					canResync = false;
					//MusicBeatState.switchState(new StoryMenuState());
					var campaignPercent:Float = 0;
					for (i in campaignPercents) {
						campaignPercent += i;
					}
					campaignPercent /= campaignPercents.length;
					var campaignCombo:Int = 0;
					for (i in campaignCombos) {
						if (i > campaignCombo) campaignCombo = i;
					}

					var tempWeekData:WeekData = WeekData.getCurrentWeek();

					LoadingState.loadAndSwitchState(new ResultsScreen(tempWeekData.storyName, ratingName, campaignScore, Difficulty.getString(), [campaignRatings[0], campaignRatings[1], campaignRatings[2], campaignRatings[3], campaignMisses, campaignCombo, Math.floor(campaignPercent * 100)], oldWeekScore, true, boyfriend.curCharacter));

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
						Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					canResync = false;
					LoadingState.prepareToSong();
					LoadingState.loadAndSwitchState(new PlayState(), false, false);
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				Mods.loadTopMod();
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

				canResync = false;
				//MusicBeatState.switchState(new FreeplayState());
				LoadingState.loadAndSwitchState(new ResultsScreen(SONG.song, ratingName, songScore, Difficulty.getString(), [ratingsData[0].hits, ratingsData[1].hits, ratingsData[2].hits, ratingsData[3].hits, songMisses, maxCombo, Math.floor(ratingPercent * 100)], oldScore, false, boyfriend.curCharacter));
				//FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;
	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	private function cachePopUpScore()
	{
		var uiFolder:String = "";
		if (stageUI != "normal")
			uiFolder = uiPrefix + "UI/";

		for (rating in ratingsData)
			Paths.image(uiFolder + rating.image + uiPostfix);
		for (i in 0...10)
			Paths.image(uiFolder + 'num' + i + uiPostfix);
	}

	var notesHit:Int = 0;
	var minNotesHit:Int = 10;
	var resetTimer:FlxTimer;

	function endCombo(miss:Bool = false) {
		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/";
			antialias = !isPixelStage;
		}

		var endComboTxt:FlxText = new FlxText(0, 0, 600, miss ? 'Combo Break:' : 'Note Combo:', 50);
		endComboTxt.setFormat(Paths.font(isPixelStage ? "pixel-latin.ttf" : "vcr.ttf"), isPixelStage ? 40 : 50, miss ? FlxColor.RED : FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		endComboTxt.screenCenter();
		endComboTxt.borderSize = 2;
		endComboTxt.updateHitbox();
		comboGroup.add(endComboTxt);

		var seperatedHits:String = Std.string(notesHit);
		var hitLoop:Int = 0;
		for (i in 0...seperatedHits.length) {
			var num:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(seperatedHits.charAt(i)) + uiPostfix));
			num.screenCenter();
			num.x = endComboTxt.x  + (endComboTxt.width * 0.8) + (43 * hitLoop) + ClientPrefs.data.comboOffset[2];
			num.y += 80 - ClientPrefs.data.comboOffset[3];
			if (!PlayState.isPixelStage) num.setGraphicSize(Std.int(num.width * 0.5));
			else num.setGraphicSize(Std.int(num.width * daPixelZoom));
			num.updateHitbox();

			num.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			num.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			num.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			num.visible = !ClientPrefs.data.hideHud;
			num.antialiasing = antialias;
			if (miss) num.color = FlxColor.RED;

			comboGroup.add(num);

			FlxTween.tween(num, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween) {num.destroy();},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			hitLoop++;
		}

		FlxTween.tween(endComboTxt, {y: endComboTxt.y - (FlxG.random.int(50, 70) * playbackRate), alpha: 0}, 0.2 / playbackRate, {
			onComplete: __ -> {
				endComboTxt.kill();
				endComboTxt.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;
		notesHit += 1;

		if (resetTimer != null) resetTimer.cancel();
		resetTimer = new FlxTimer().start(1.5, _ -> {
			if (notesHit >= minNotesHit) endCombo();
			notesHit = 0;
			// You can do more here but I am just making this basic for now.
			// For example, you could have an image pop up that says 
			// "Note Combo" before fading away when this timer finishes.
		});

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;

				comboGroup.remove(spr);
				spr.destroy();
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating(false);
			}
		}

		var uiFolder:String = "";
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (stageUI != "normal")
		{
			uiFolder = uiPrefix + "UI/";
			antialias = !isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiFolder + daRating.image + uiPostfix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		stagesFunc(function(stage:BaseStage) {
			var tempPoint:FlxPoint = new FlxPoint(0, 0);
			tempPoint.x = stage.ratingPos.x;
			tempPoint.y = stage.ratingPos.y;
			if (tempPoint.x != 0) rating.x = tempPoint.x; else rating.x += ClientPrefs.data.comboOffset[0];
			if (tempPoint.y != 0) rating.y = tempPoint.y; else rating.y -= ClientPrefs.data.comboOffset[1];
		});
		rating.antialiasing = antialias;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + uiPostfix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		stagesFunc(function(stage:BaseStage) {
			var tempPoint:FlxPoint = new FlxPoint(0, 0);
			tempPoint.x = stage.comboPos.x;
			tempPoint.y = stage.comboPos.y;
			if (tempPoint.x != 0) comboSpr.x = tempPoint.x; else comboSpr.x += ClientPrefs.data.comboOffset[0];
			if (tempPoint.y != 0) comboSpr.y = tempPoint.y; else comboSpr.y -= ClientPrefs.data.comboOffset[1];
		});
		comboSpr.antialiasing = antialias;
		comboSpr.y += 60;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo && notesHit >= minNotesHit)
			comboGroup.add(comboSpr);

		var separatedScore:String = Std.string(combo);
		var comboPoint:FlxPoint = new FlxPoint(0, 0);
		stagesFunc(function(stage:BaseStage) {
			comboPoint.x = stage.comboCountPos.x;
			comboPoint.y = stage.comboCountPos.y;
		});
		for (i in 0...separatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + uiPostfix));
			numScore.screenCenter();
			if (comboPoint.x != 0) numScore.x = (43 * daLoop) + comboPoint.x; else numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			if (comboPoint.y != 0) numScore.y = comboPoint.y; else numScore.y += 80 - ClientPrefs.data.comboOffset[3];
			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = antialias;

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = n != null && !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else
		{
			if (ClientPrefs.data.ghostTapping)
				callOnScripts('onGhostTap', [key]);
			else
				noteMissPress(key);
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if(strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...arr.length)
			{
				var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
				for (noteKey in note)
					if(key == noteKey)
						return i;
			}
		}
		return -1;
	}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();

			#if ACHIEVEMENTS_ALLOWED
			else checkForAchievement(['oversinging']);
			#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
		stagesFunc(function(stage:BaseStage) stage.noteMiss(daNote));
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.data.ghostTapping) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		stagesFunc(function(stage:BaseStage) stage.noteMissPress(direction));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = pressMissDamage;
		if(note != null) subtract = note.missHealth;

		if(notesHit >= minNotesHit) endCombo(true);
		notesHit = 0;
		if (resetTimer != null) resetTimer.cancel();

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is - [REDACTED]
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		combo = 0;

		health -= subtract * healthLoss;
		songScore -= 10;
		if(!endingSong) songMisses++;
		totalPlayed++;
		RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var postfix:String = '';
			if(note != null) postfix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + postfix;
			char.playAnim(animToPlay, true);

			if(char != gf && lastCombo > 5 && gf != null && gf.hasAnimation('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}
		}
		vocals.volume = 0;
	}

	public var dontChangeOppRGB:Bool = false;

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('opponentNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		if (songName != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.hasAnimation('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		if(!note.noAnimation)
		{
			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;
			if(note.gfNote) char = gf;

			if(char != null)
			{
				var canPlay:Bool = true;
				if(note.isSustainNote)
				{
					var holdAnim:String = animToPlay + '-hold';
					if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
					if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
				}

				if (char == focusedChar){ curNote = note.noteData;}
 				char.playAnim(animToPlay, true);
 				char.holdTimer = 0;
			}

			switch(note.noteType) {
				case 'Ghost Effect' | 'Ghost Effect Alt':
					if (!note.isSustainNote) GhostEffect.createGhost(dad, 0, note);
			}
		}

		if(opponentVocals.length <= 0) vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
		
		stagesFunc(function(stage:BaseStage) stage.opponentNoteHit(note));
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (ClientPrefs.data.characterNoteColors != 'Disabled' && !dontChangeOppRGB) {
			switch (note.noteData) {
				case 0:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) {
						opponentCovers.members[0].rgbShader.changeRGB(dad.altNoteColors.left);
						opponentStrums.members[0].rgbShader.changeRGB(dad.altNoteColors.left);
					} else {
						opponentCovers.members[0].rgbShader.changeRGB(dad.noteColors.left);
						opponentStrums.members[0].rgbShader.changeRGB(dad.noteColors.left);
					}
				case 1:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) {
						opponentCovers.members[1].rgbShader.changeRGB(dad.altNoteColors.down);
						opponentStrums.members[1].rgbShader.changeRGB(dad.altNoteColors.down);
					} else {
						opponentCovers.members[1].rgbShader.changeRGB(dad.noteColors.down);
						opponentStrums.members[1].rgbShader.changeRGB(dad.noteColors.down);
					}
				case 2:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) {
						opponentCovers.members[2].rgbShader.changeRGB(dad.altNoteColors.up);
						opponentStrums.members[2].rgbShader.changeRGB(dad.altNoteColors.up);
					} else {
						opponentCovers.members[2].rgbShader.changeRGB(dad.noteColors.up);
						opponentStrums.members[2].rgbShader.changeRGB(dad.noteColors.up);
					}
				case 3:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) {
						opponentCovers.members[3].rgbShader.changeRGB(dad.altNoteColors.right);
						opponentStrums.members[3].rgbShader.changeRGB(dad.altNoteColors.right);
					} else {
						opponentCovers.members[3].rgbShader.changeRGB(dad.noteColors.right);
						opponentStrums.members[3].rgbShader.changeRGB(dad.noteColors.right);
					}
			}
		}
		if (!note.noteSplashData.disabled && !note.isSustainNote && enemyNoteSplashes) spawnNoteSplashOnNote(note, 0);
		if (!note.isSustainNote) invalidateNote(note); else {
			opponentCovers.forEach(function(c:StrumCover) {
				c.enemySplash = enemyCoverSplashes;
				c.showSplash = enemyCoverSplashes;
				if (Math.abs(note.noteData) == c.strumNote.noteData && (note.prevNote == null || !note.prevNote.isSustainNote) && enemyCoverSplashes && note.prevNote.sustainLength >= c.minSustainLength) c.start(note);
			});
		}
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) result = callOnHScript('goodNoteHitPre', [note]);

		if(result == LuaUtils.Function_Stop) return;

		note.wasGoodHit = true;

		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(!note.hitCausesMiss) //Common notes
		{
			if(!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + note.animSuffix;

				var char:Character = boyfriend;
				var animCheck:String = 'hey';
				if(note.gfNote)
				{
					char = gf;
					animCheck = 'cheer';
				}

				if(char != null)
				{
					var canPlay:Bool = true;
					if(note.isSustainNote)
					{
						var holdAnim:String = animToPlay + '-hold';
						if(char.animation.exists(holdAnim)) animToPlay = holdAnim;
						if(char.getAnimationName() == holdAnim || char.getAnimationName() == holdAnim + '-loop') canPlay = false;
					}
					if (char == focusedChar){ curNote = note.noteData; }
					if(canPlay) char.playAnim(animToPlay, true);
					char.holdTimer = 0;

					if(note.noteType == 'Hey!')
					{
						if(char.hasAnimation(animCheck))
						{
							char.playAnim(animCheck, true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
			}

			if(!cpuControlled)
			{
				var spr = playerStrums.members[note.noteData];
				if(spr != null) spr.playAnim('confirm', true);
			}
			else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				combo++;
				if(combo > 9999) combo = 9999;
				popUpScore(note);
			}
			var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
			if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
			if (gainHealth) health += note.hitHealth * healthGain;

			switch(note.noteType) {
				case 'Ghost Effect' | 'Ghost Effect Alt':
					if (!note.isSustainNote) GhostEffect.createGhost(boyfriend, 1, note);
			}
		}
		else //Notes that count as a miss if you hit them (Hurt notes for example)
		{
			if(!note.noMissAnimation)
			{
				switch(note.noteType)
				{
					case 'Hurt Note':
						if(boyfriend.hasAnimation('hurt'))
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if(!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
		}

		if (ClientPrefs.data.characterNoteColors == 'Enabled') {
			switch (note.noteData) {
				case 0:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) {
						playerCovers.members[0].rgbShader.changeRGB(boyfriend.altNoteColors.left);
						playerStrums.members[0].rgbShader.changeRGB(boyfriend.altNoteColors.left);
					} else {
						playerCovers.members[0].rgbShader.changeRGB(boyfriend.noteColors.left);
						playerStrums.members[0].rgbShader.changeRGB(boyfriend.noteColors.left);
					}
				case 1:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) {
						playerCovers.members[1].rgbShader.changeRGB(boyfriend.altNoteColors.down);
						playerStrums.members[1].rgbShader.changeRGB(boyfriend.altNoteColors.down);
					} else {
						playerCovers.members[1].rgbShader.changeRGB(boyfriend.noteColors.down);
						playerStrums.members[1].rgbShader.changeRGB(boyfriend.noteColors.down);
					}
				case 2:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) {
						playerCovers.members[2].rgbShader.changeRGB(boyfriend.altNoteColors.up);
						playerStrums.members[2].rgbShader.changeRGB(boyfriend.altNoteColors.up);
					} else {
						playerCovers.members[2].rgbShader.changeRGB(boyfriend.noteColors.up);
						playerStrums.members[2].rgbShader.changeRGB(boyfriend.noteColors.up);
					}
				case 3:
					if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) {
						playerCovers.members[3].rgbShader.changeRGB(boyfriend.altNoteColors.right);
						playerStrums.members[3].rgbShader.changeRGB(boyfriend.altNoteColors.right);
					} else {
						playerCovers.members[3].rgbShader.changeRGB(boyfriend.noteColors.right);
						playerStrums.members[3].rgbShader.changeRGB(boyfriend.noteColors.right);
					}
			}
		}

		stagesFunc(function(stage:BaseStage) stage.goodNoteHit(note));
		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);
		if(!note.isSustainNote) invalidateNote(note); else sickStrum(note);
	}

	private function sickStrum(note:Note = null):Void {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);
		playerCovers.forEach(function(c:StrumCover) {
			if (daRating.noteSplash && Math.abs(note.noteData) == c.strumNote.noteData && (note.prevNote == null || !note.prevNote.isSustainNote) && note.prevNote.sustainLength >= c.minSustainLength) c.start(note);
		});
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note, ?player:Int = 1) {
		if(note != null) {
			var strum:StrumNote = (player == 1) ? playerStrums.members[note.noteData] : opponentStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
		}
	}

	public function spawnNoteSplash(x:Float = 0, y:Float = 0, ?data:Int = 0, ?note:Note, ?strum:StrumNote, ?player:Int = 0) {
		//var splash:NoteSplash = new NoteSplash();
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.babyArrow = strum;
		/*
		if ((boyfriend.splashSkin != '' && boyfriend.splashSkin != null) && player == 1) {
			splash.spawnSplashNote(x, y, data, note, true, boyfriend.splashSkin, boyfriend.splashSkinLib);
			trace('boyfie sing... ye');
		} else if ((dad.splashSkin != '' && dad.splashSkin != null) && player == 0) {
			splash.spawnSplashNote(x, y, data, note, true, dad.splashSkin, dad.splashSkinLib);
		} else splash.spawnSplashNote(x, y, data, note);
		*/
		splash.spawnSplashNote(x, y, data, note, true, player == 1 ? boyfriend.splashSkin : dad.splashSkin, player == 1 ? boyfriend.splashSkinLib : dad.splashSkinLib);
		if (ClientPrefs.data.characterNoteColors != 'Disabled') {
			switch (note.noteData) {
				case 0:
					if (note.mustPress && ClientPrefs.data.characterNoteColors == 'Enabled') {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) splash.rgbShader.changeRGB(boyfriend.altNoteColors.left);
						else splash.rgbShader.changeRGB(boyfriend.noteColors.left);
					} else if (note.mustPress == false) {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) splash.rgbShader.changeRGB(dad.altNoteColors.left);
						else splash.rgbShader.changeRGB(dad.noteColors.left);
					}
				case 1:
					if (note.mustPress && ClientPrefs.data.characterNoteColors == 'Enabled') {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) splash.rgbShader.changeRGB(boyfriend.altNoteColors.down);
						else splash.rgbShader.changeRGB(boyfriend.noteColors.down);
					} else if (note.mustPress == false) {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) splash.rgbShader.changeRGB(dad.altNoteColors.down);
						else splash.rgbShader.changeRGB(dad.noteColors.down);
					}
				case 2:
					if (note.mustPress && ClientPrefs.data.characterNoteColors == 'Enabled') {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) splash.rgbShader.changeRGB(boyfriend.altNoteColors.up);
						else splash.rgbShader.changeRGB(boyfriend.noteColors.up);
					} else if (note.mustPress == false) {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) splash.rgbShader.changeRGB(dad.altNoteColors.up);
						else splash.rgbShader.changeRGB(dad.noteColors.up);
					}
				case 3:
					if (note.mustPress && ClientPrefs.data.characterNoteColors == 'Enabled') {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && boyfriend.hasAltColors) splash.rgbShader.changeRGB(boyfriend.altNoteColors.right);
						else splash.rgbShader.changeRGB(boyfriend.noteColors.right);
					} else if (note.mustPress == false) {
						if ((note.noteType == 'Alt Animation' || note.animSuffix == '-alt') && dad.hasAltColors) splash.rgbShader.changeRGB(dad.altNoteColors.right);
						else splash.rgbShader.changeRGB(dad.noteColors.right);
					}
			}
		}
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		if (psychlua.CustomSubstate.instance != null)
		{
			closeSubState();
			resetSubState();
		}
		healthBarSettings = null;
		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = null;
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				if(script.exists('onDestroy')) script.call('onDestroy');
				script.destroy();
			}

		hscriptArray = null;
		#end
		stagesFunc(function(stage:BaseStage) stage.destroy());

		#if VIDEOS_ALLOWED
		if(videoCutscene != null)
		{
			videoCutscene.destroy();
			videoCutscene = null;
		}
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		FlxG.camera.setFilters([]);

		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		FlxG.animationTimeScale = 1;

		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();

		NoteSplash.configs.clear();
		instance = null;
		super.destroy();
	}

	var lastStepHit:Int = -1;
	var creditsTweens:Array<FlxTween> = []; //This might end up being a bit of tweens but at the very least it will allow me to cancel or finish one to start the next faster
	override function stepHit() {
		switch(curStep) {
			case 3:
				creditsTweens[0] = FlxTween.tween(creditsBG, {x: -120}, 2.6, {ease:FlxEase.expoOut});
				creditsTweens[1] = FlxTween.tween(creditsFrontBG, {x: -100}, 3.1, {ease:FlxEase.expoOut});
				creditsTweens[2] = FlxTween.tween(creditsIconP, {x: 1095}, 2, {ease:FlxEase.expoOut});	
				creditsTweens[3] = FlxTween.tween(creditsDisk, {x: 390}, 2.6, {ease:FlxEase.expoOut});
				FlxTween.tween(creditsDisk, {angle: 2000}, 15, {   
					ease:FlxEase.expoOut, 
					onComplete: 
					function(twn:FlxTween) {
						remove(creditsGroup);
					}
				});
				creditsTweens[4] = FlxTween.tween(creditsSongTitle, {x: 530}, 2.6, {ease:FlxEase.expoOut});
				creditsTweens[5] = FlxTween.tween(creditsArtist, {x: 530}, 2.6, {ease:FlxEase.expoOut});
				creditsTweens[6] = FlxTween.tween(creditsCharter, {x: 530}, 2.6, {ease:FlxEase.expoOut});
			case 7:
				creditsTweens[7] = FlxTween.tween(creditsIconEn, {x: 30}, 2.3, {ease: FlxEase.expoOut});
			case 25:
				if (creditsTweens[2] != null) creditsTweens[2].cancel();
				creditsTweens[2] = FlxTween.tween(creditsIconP, {x: 2075}, 2.1, {ease:FlxEase.expoIn});
			case 26:
				if (creditsTweens[0] != null) creditsTweens[0].cancel();
				if (creditsTweens[1] != null) creditsTweens[1].cancel();
				if (creditsTweens[3] != null) creditsTweens[3].cancel();
				if (creditsTweens[4] != null) creditsTweens[4].cancel();
				if (creditsTweens[5] != null) creditsTweens[5].cancel();
				if (creditsTweens[6] != null) creditsTweens[6].cancel();
				if (creditsTweens[7] != null) creditsTweens[7].cancel();

				creditsTweens[0] = FlxTween.tween(creditsBG, {x: 1400}, 2.3, {ease:FlxEase.expoIn});
				creditsTweens[1] = FlxTween.tween(creditsFrontBG, {x: 1400}, 2.6, {ease:FlxEase.expoIn});
				creditsTweens[7] = FlxTween.tween(creditsIconEn, {x: 2075}, 2.1, {ease:FlxEase.expoIn});
				creditsTweens[3] = FlxTween.tween(creditsDisk, {x: 2075}, 1.9, {ease:FlxEase.expoIn});
				creditsTweens[4] = FlxTween.tween(creditsSongTitle, {x: 2075}, 1.8, {ease:FlxEase.expoIn});
				creditsTweens[5] = FlxTween.tween(creditsArtist, {x: 2075}, 1.8, {ease:FlxEase.expoIn});
				creditsTweens[6] = FlxTween.tween(creditsCharter, {x: 2075}, 1.8, {ease:FlxEase.expoIn});
			}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		var curDadAnimation = dad.isAnimateAtlas ? (dad.atlas.anim.curSymbol != null ? dad.atlas.anim.curSymbol.name : "idle") : (dad.animation.curAnim != null ? dad.animation.curAnim.name : "idle");
		var curBoyfriendAnimation = boyfriend.isAnimateAtlas ? (boyfriend.atlas.anim.curSymbol != null ? boyfriend.atlas.anim.curSymbol.name : "idle") : (boyfriend.animation.curAnim != null ? boyfriend.animation.curAnim.name : "idle");
		iconsAnimator.updateIcons(curBeat, ClientPrefs.data.iconAnims, curBoyfriendAnimation, curDadAnimation);
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if(curStep % 2 == 0)
			{
		if (creditsIconP != null && creditsIconEn != null) {
        var creditsAnimP = curBoyfriendAnimation;
        var creditsAnimEn = curDadAnimation;
        lawsthings.objects.IconsAnimator.updateIconsStatic(
            creditsIconP, creditsIconEn, creditsIconP.y,
            curBeat, ClientPrefs.data.iconAnims, creditsAnimP, creditsAnimEn
        );
        creditsIconP.setGraphicSize(Std.int(creditsIconP.width * 0.65));
        creditsIconEn.setGraphicSize(Std.int(creditsIconP.width * 0.65));
        creditsIconP.updateHitbox();
        creditsIconEn.updateHitbox();
   		}
	}
		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();
		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
	}

	public function playerDance():Void
	{
		var anim:String = boyfriend.getAnimationName();
		if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
			boyfriend.dance();
	}

	override function sectionHit()
	{
		if (SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.data.camZooms)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (Iris.instances.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		var newScript:HScript = null;
		try {
			newScript = new HScript(null, file);
			if (newScript.exists('onCreate')) newScript.call('onCreate');
			trace('initialized hscript interp successfully: $file');
			hscriptArray.push(newScript);
		}
		catch(e:IrisError) {
			var pos:HScriptInfos = cast {fileName: file, showLine: false};
			Iris.error(Printer.errorToString(e, false), pos);
			var newScript:HScript = cast (Iris.instances.get(file), HScript);
			if(newScript != null)
				newScript.destroy();
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;

		for(script in hscriptArray)
		{
			@:privateAccess
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var callValue = script.call(funcToCall, args);
			if(callValue != null) {
				var callValue = script.call(funcToCall, args);
				var myValue:Dynamic = callValue.returnValue;

				if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
				{
					returnVal = myValue;
					break;
				}

				if(myValue != null && !excludeValues.contains(myValue))
					returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating(badHit:Bool = false, scoreBop:Bool = true) {
		setOnScripts('score', songScore);
		setOnScripts('misses', songMisses);
		setOnScripts('hits', songHits);
		setOnScripts('combo', combo);

		var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
		if(ret != LuaUtils.Function_Stop)
		{
			ratingName = '?';
			if(totalPlayed != 0) //Prevent divide by 0
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				if(ratingPercent < 1)
					for (i in 0...ratingStuff.length-1)
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
			}
			fullComboFunction();
		}
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
		setOnScripts('totalPlayed', totalPlayed);
		setOnScripts('totalNotesHit', totalNotesHit);
		updateScore(badHit, scoreBop); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null)
	{
		if(chartingMode) return;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
		if(cpuControlled) return;

		for (name in achievesToCheck) {
			if(!Achievements.exists(name)) continue;

			var unlock:Bool = false;
			if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
			{
				switch(name)
				{
					case 'ur_bad':
						unlock = (ratingPercent < 0.2 && !practiceMode);

					case 'ur_good':
						unlock = (ratingPercent >= 1 && !usedPractice);

					case 'oversinging':
						unlock = (boyfriend.holdTimer >= 10 && !usedPractice);

					case 'hype':
						unlock = (!boyfriendIdled && !usedPractice);

					case 'two_keys':
						unlock = (!usedPractice && keysPressed.length <= 2);

					case 'toastie':
						unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !ClientPrefs.data.antialiasing);

					#if BASE_GAME_FILES
					case 'debugger':
						unlock = (songName == 'test' && !usedPractice);
					#end
				}
			}
			else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
			{
				if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
					&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
					unlock = true;
			}

			if(unlock) Achievements.unlock(name);
		}
	}
	#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public function createRuntimeShader(shaderName:String):ErrorHandledRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new ErrorHandledRuntimeShader(shaderName);

		#if (!flash && sys)
		if(!runtimeShaders.exists(shaderName) && !initLuaShader(shaderName))
		{
			FlxG.log.warn('Shader $shaderName is missing!');
			return new ErrorHandledRuntimeShader(shaderName);
		}

		var arr:Array<String> = runtimeShaders.get(shaderName);
		return new ErrorHandledRuntimeShader(shaderName, arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (!flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
}
