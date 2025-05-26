package backend;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup;

import objects.Note;
import objects.Character;
import torchsthings.objects.effects.ReflectedChar;
import states.stages.objects.ABotSpeaker;
import torchsthings.objects.SpeakerSkin;

/*
import lime.utils.Assets;
import torchsthings.objects.ImageBar;
import torchsthings.objects.ImageBar.BarSettings;*/ 
//This is used to add a custom healthbar for certain Stages 

enum Countdown {
	THREE;
	TWO;
	ONE;
	GO;
	START;
}

enum NeneState {
	STATE_DEFAULT;
	STATE_PRE_RAISE;
	STATE_RAISE;
	STATE_READY;
	STATE_LOWER;
}

class BaseStage extends FlxBasic {
	private var game(get, never):Dynamic;
	public var onPlayState(get, never):Bool;

	// some variables for convenience
	public var paused(get, never):Bool;
	public var songName(get, never):String;
	public var isStoryMode(get, never):Bool;
	public var seenCutscene(get, never):Bool;
	public var inCutscene(get, set):Bool;
	public var canPause(get, set):Bool;
	public var members(get, never):Array<FlxBasic>;

	public var boyfriend(get, never):Character;
	public var dad(get, never):Character;
	public var gf(get, never):Character;
	public var boyfriendGroup(get, never):FlxSpriteGroup;
	public var dadGroup(get, never):FlxSpriteGroup;
	public var gfGroup(get, never):FlxSpriteGroup;

	public var unspawnNotes(get, never):Array<Note>;

	public var reflectedBF:ReflectedChar;
	public var reflectedGF:ReflectedChar;
	public var reflectedDad:ReflectedChar;
	
	public var camGame(get, never):FlxCamera;
	public var camHUD(get, never):FlxCamera;
	public var camOther(get, never):FlxCamera;

	public var defaultCamZoom(get, set):Float;
	public var camFollow(get, never):FlxObject;

	public var ratingPos:FlxPoint = new FlxPoint(0, 0);
	public var comboCountPos:FlxPoint = new FlxPoint(0, 0);

	public function new() {
		if(game == null) {
			FlxG.log.error('Invalid state for the stage added!');
			destroy();
		} else {
			game.stages.push(this);
			super();
			create();
		}
		Paths.clearUnusedMemory();
	}

	//main callbacks
	public function create() {}
	public function createPost() {
		if (speaker != null) speaker.createPost(gf);
	}
	//public function update(elapsed:Float) {}
	public function countdownTick(count:Countdown, num:Int) {}
	public function startSong() {
		if (speaker != null) {
			speaker.snd = FlxG.sound.music;
			speaker.songStart();
		}	
	}

	// FNF steps, beats and sections
	public var curBeat:Int = 0;
	public var curDecBeat:Float = 0;
	public var curStep:Int = 0;
	public var curDecStep:Float = 0;
	public var curSection:Int = 0;
	public function beatHit() {
		if (speaker != null) speaker.beatHit();
	}
	public function stepHit() {}
	public function sectionHit() {
		if (speaker != null) speaker.updateABotEye(speaker.daCustomSpeaker);
	}

	// Substate close/open, for pausing Tweens/Timers
	public function closeSubState() {}
	public function openSubState(SubState:FlxSubState) {}

	// Events
	public function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {}
	public function eventPushed(event:EventNote) {}
	public function eventPushedUnique(event:EventNote) {}

	// Note Hit/Miss
	public function goodNoteHit(note:Note) {}
	public function opponentNoteHit(note:Note) {}
	public function noteMiss(note:Note) {}
	public function noteMissPress(direction:Int) {}

	// Things to replace FlxGroup stuff and inject sprites directly into the state
	function add(object:FlxBasic) return FlxG.state.add(object);
	function remove(object:FlxBasic, splice:Bool = false) return FlxG.state.remove(object, splice);
	function insert(position:Int, object:FlxBasic) return FlxG.state.insert(position, object);
	
	public function addBehindGF(obj:FlxBasic) return insert(members.indexOf(game.gfGroup), obj);
	public function addBehindBF(obj:FlxBasic) return insert(members.indexOf(game.boyfriendGroup), obj);
	public function addBehindDad(obj:FlxBasic) return insert(members.indexOf(game.dadGroup), obj);
	public function setDefaultGF(name:String) { //Fix for the Chart Editor on Base Game stages
		var gfVersion:String = PlayState.SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			gfVersion = name;
			PlayState.SONG.gfVersion = gfVersion;
		}
	}

	public function getStageObject(name:String) //Objects can only be accessed *after* create(), use createPost() if you want to mess with them on init
		return game.variables.get(name);

	//start/end callback functions
	public function setStartCallback(myfn:Void->Void) {
		if(!onPlayState) return;
		PlayState.instance.startCallback = myfn;
	}
	public function setEndCallback(myfn:Void->Void) {
		if(!onPlayState) return;
		PlayState.instance.endCallback = myfn;
	}

	// overrides
	function startCountdown() if(onPlayState) return PlayState.instance.startCountdown(); else return false;
	function endSong() if(onPlayState)return PlayState.instance.endSong(); else return false;
	function moveCameraSection() if(onPlayState) moveCameraSection();
	function moveCamera(isDad:Bool) if(onPlayState) PlayState.instance.moveCamera(isDad);
	inline private function get_paused() return game.paused;
	inline private function get_songName() return game.songName;
	inline private function get_isStoryMode() return PlayState.isStoryMode;
	inline private function get_seenCutscene() return PlayState.seenCutscene;
	inline private function get_inCutscene() return game.inCutscene;
	inline private function set_inCutscene(value:Bool) {
		game.inCutscene = value;
		return value;
	}
	inline private function get_canPause() return game.canPause;
	inline private function set_canPause(value:Bool) {
		game.canPause = value;
		return value;
	}
	inline private function get_members() return game.members;

	inline private function get_game() return cast FlxG.state;
	inline private function get_onPlayState() return (Std.isOfType(FlxG.state, states.PlayState));

	inline private function get_boyfriend():Character return game.boyfriend;
	inline private function get_dad():Character return game.dad;
	inline private function get_gf():Character return game.gf;

	inline private function get_boyfriendGroup():FlxSpriteGroup return game.boyfriendGroup;
	inline private function get_dadGroup():FlxSpriteGroup return game.dadGroup;
	inline private function get_gfGroup():FlxSpriteGroup return game.gfGroup;

	inline private function get_unspawnNotes():Array<Note> {
		return cast game.unspawnNotes;
	}
	
	inline private function get_camGame():FlxCamera return game.camGame;
	inline private function get_camHUD():FlxCamera return game.camHUD;
	inline private function get_camOther():FlxCamera return game.camOther;

	inline private function get_defaultCamZoom():Float return game.defaultCamZoom;
	inline private function set_defaultCamZoom(value:Float):Float {
		game.defaultCamZoom = value;
		return game.defaultCamZoom;
	}
	inline private function get_camFollow():FlxObject return game.camFollow;

	function playWeekSound(name:String, ?modsAllowed:Bool = true) { // So you don't have to add the "true" to everything in case you forget
		return Paths.sound(name, '', true, modsAllowed);
	}

	function playWeekMusic(name:String, ?modsAllowed:Bool = true) {
		return Paths.music(name, '', true, modsAllowed);
	}
	
	function randomWeekSound(name:String, min:Int, max:Int, ?modsAllowed:Bool = true) {
		return Paths.soundRandom(name, min, max, '', true, modsAllowed);
	}

	function changeComboGroupCamera(mode:CameraMode) { // Needs to be in createPost(), does not work in create() function
		switch (mode) {
			case Base:
				PlayState.instance.comboGroup.cameras = [camGame];
			case Other:
				PlayState.instance.comboGroup.cameras = [camOther];
			case Hud:
				PlayState.instance.comboGroup.cameras = [camHUD];
			default:
				changeComboGroupCamera(Base);
		}
	}

	/*var settings:BarSettings = haxe.Json.parse(Assets.getText(Paths.json("healthbars/5peso", "shared").replace("data", "images")));
	PlayState.healthBarSettings = settings; // These 2 lines are to verify which healthbar you want to add

	PlayState.instance.iconP2.visible = false;*/ //and this one in case you want to deactivate the icons or just the opponent's, It has to be in "createPost"

	// New Speaker Shits
	var speaker:SpeakerSkin;
	public var defaultSpeaker:String = 'base'; // This is only used for setting a default speaker per stage if someone doesn't change the speaker themselves

	function addSpeaker(?xOffset:Float = 0.0, ?yOffset:Float = 550.0, ?scrollFactorX:Float = 1.0, ?scrollFactorY:Float = 1.0) {
		var skin:String = switch (ClientPrefs.data.speakerSkin.toLowerCase()) {
			case "stage":
				defaultSpeaker;
			case "christmas":
				"base-christmas";
			case "nene":
				"abot";
			case "nene-pixel":
				"abot-pixel";
			case 'default':
				'base';
			default:
				ClientPrefs.data.speakerSkin.toLowerCase();
		}

		speaker = new SpeakerSkin(xOffset, yOffset, skin);
		speaker.scrollFactor.set(scrollFactorX, scrollFactorY);
		add(speaker);
	}
}

enum CameraMode {
	Hud;
	Other;
	Base;
}