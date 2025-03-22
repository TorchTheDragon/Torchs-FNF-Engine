package backend;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.group.FlxGroup;

import objects.Note;
import objects.Character;
import torchsthings.objects.effects.ReflectedChar;
import states.stages.objects.ABotSpeaker;

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
	}

	//main callbacks
	public function create() {}
	public function createPost() {}
	//public function update(elapsed:Float) {}
	public function countdownTick(count:Countdown, num:Int) {}
	public function startSong() {}

	// FNF steps, beats and sections
	public var curBeat:Int = 0;
	public var curDecBeat:Float = 0;
	public var curStep:Int = 0;
	public var curDecStep:Float = 0;
	public var curSection:Int = 0;
	public function beatHit() {}
	public function stepHit() {}
	public function sectionHit() {}

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

	// Abot stuff
	var abot:ABotSpeaker;
	var blinkCountdown:Int = 3;
	final VULTURE_THRESHOLD:Float = 0.5;
	final MIN_BLINK_DELAY:Int = 3;
	final MAX_BLINK_DELAY:Int = 7;
	var animationFinished:Bool = false;

	// As I can't make this permanently be in every stage, you will have to at least throw this function into createP.
	/* Example:
	override function create() {
		addAbot();
	}
	*/
	function addAbot(?xOffset:Float = 0.0, ?yOffset:Float = 550.0, ?scrollFactorX:Float = 1.0, ?scrollFactorY:Float = 1.0) {
		if (PlayState.SONG.gfVersion == 'nene' || PlayState.SONG.gfVersion == 'nene-opp'|| PlayState.SONG.gfVersion == 'nene-christmas') {
			abot = new ABotSpeaker(gfGroup.x + xOffset, gfGroup.y + yOffset);
			abot.scrollFactor.set(scrollFactorX, scrollFactorY);
			updateABotEye(true);
			add(abot);
		}
	//Example;
	//addAbot(0, 0, 1, 1);
	}
	
	// Small changes after abot is made.
	/* Example:
	override function createPost() {
		addAbotPost();
	}
	*/
	function addAbotPost() {
		if(gf != null) {
			gf.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int) {
				switch(currentNeneState) {
					case STATE_PRE_RAISE:
						if (name == 'danceLeft' && frameNumber >= 14) {
							animationFinished = true;
							transitionState();
						}
					default:
						// Ignore.
				}
			}
		}
	}
	// Put this in sectionHit
	/*
	override function sectionHit() {
		updateABotEye();
	}
	*/
	function updateABotEye(finishInstantly:Bool = false) {
		if (abot != null) {
			if(PlayState.SONG.notes[Std.int(FlxMath.bound(curSection, 0, PlayState.SONG.notes.length - 1))].mustHitSection == true)
				abot.lookRight();
			else
				abot.lookLeft();
	
			if(finishInstantly) abot.eyes.anim.curFrame = abot.eyes.anim.length - 1;
		}
	}
	// Put this in startSong 
	/*
	override function startSong() {
		abotSongStart();
	}
	*/
	function abotSongStart() {
		if (abot != null) abot.snd = FlxG.sound.music;
		gf.animation.finishCallback = onNeneAnimationFinished;
	}
	// Put this in update
	/*
	override function update(elapsed:Float) {
		abotUpdate();
	}
	*/
	function abotUpdate() {
		animationFinished = gf.isAnimationFinished();
		transitionState();
	}
	// Put this in beatHit
	/*
	override function beatHit() {
		abotBeatHit();
	}
	*/
	function abotBeatHit() {
		switch(currentNeneState) {
			case STATE_READY:
				if (blinkCountdown == 0) {
					gf.playAnim('idleKnife', false);
					blinkCountdown = FlxG.random.int(MIN_BLINK_DELAY, MAX_BLINK_DELAY);
				}
				else blinkCountdown--;
			default:
				// In other states, don't interrupt the existing animation.
		}
	}
	var currentNeneState:NeneState = STATE_DEFAULT;
	function onNeneAnimationFinished(name:String) {
		if(!game.startedCountdown) return;
		switch(currentNeneState) {
			case STATE_RAISE, STATE_LOWER:
				if (name == 'raiseKnife' || name == 'lowerKnife') {
					animationFinished = true;
					transitionState();
				}
			default:
				// Ignore.
		}
	}
	function transitionState() {
		switch (currentNeneState) {
			case STATE_DEFAULT:
				if (game.health <= VULTURE_THRESHOLD) {
					currentNeneState = STATE_PRE_RAISE;
					gf.skipDance = true;
				}
			case STATE_PRE_RAISE:
				if (game.health > VULTURE_THRESHOLD) {
					currentNeneState = STATE_DEFAULT;
					gf.skipDance = false;
				} else if (animationFinished) {
					currentNeneState = STATE_RAISE;
					gf.playAnim('raiseKnife');
					gf.skipDance = true;
					gf.danced = true;
					animationFinished = false;
				}
			case STATE_RAISE:
				if (animationFinished) {
					currentNeneState = STATE_READY;
					animationFinished = false;
				}
			case STATE_READY:
				if (game.health > VULTURE_THRESHOLD) {
					currentNeneState = STATE_LOWER;
					gf.playAnim('lowerKnife');
				}
			case STATE_LOWER:
				if (animationFinished) {
					currentNeneState = STATE_DEFAULT;
					animationFinished = false;
					gf.skipDance = false;
				}
		}
	}
}

enum CameraMode {
	Hud;
	Other;
	Base;
}