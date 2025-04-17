package torchsthings.objects;

import backend.Rating;
import shaders.RGBPalette;
import shaders.RGBPalette.RGBShaderReference;
import objects.NoteSplash.PixelSplashShaderRef;
import objects.StrumNote;
import objects.Note;
import flixel.system.FlxAssets.FlxShader;
import openfl.utils.Assets;

using StringTools;
using flixel.util.FlxStringUtil;

class StrumCover extends FlxSprite {
	public static var defaultCoverSkin(default, never):String = 'strumCovers/NOTE_covers';
    public static var defaultLibrary(default, never):String = 'shared';
    var colArray:Array<String> = Note.colArray;
    public var strumNote:StrumNote;
    var posOffset:Array<Int> = [-25, -5];
    var animOffsets:Array<Array<Int>> = [/*start*/[20, 15], /*hold*/[-25, -5], /*end*/[-65, -40]]; // Please note that the "start" offset is kind of useless if you have a 1 frame animation
    public var rgbShader:PixelSplashShaderRef;
    var assets:String = '';
    public var showSplash:Bool = false;
    public var enemySplash:Bool = false;
    var ratingsToShowUpOn:Array<String> = ['sick'];
    public var minSustainLength:Float = 100.0; // Just change this to be whatever you want in case you don't want the splashes to show up too soon or too late

    public function new(refNote:StrumNote, ?texture:String = 'strumCovers/NOTE_covers', ?library:String = 'shared') {
        super(0, 0);

        strumNote = refNote;
        setMinimumSustainLength();
        if(texture == null) texture = defaultCoverSkin;
        if(library == null) library = defaultLibrary;

        rgbShader = new PixelSplashShaderRef(PlayState.isPixelStage);
        shader = rgbShader.shader;

        var tempShader:RGBPalette = Note.globalRgbShaders[strumNote.noteData % Note.colArray.length];
        rgbShader.copyValues(tempShader);

        reloadCover(texture, library);

        visible = false;
    }

    function getOffsetsFromFile(?coverTexture:String = 'strumCovers/NOTE_covers', ?library:String = 'shared'):Array<Array<Int>> {
        var tempOffsetArray = Assets.getText(Paths.txt(coverTexture, library).replace('data/', 'images/')).trim().split("\n");
        var returnArr:Array<Array<Int>> = [/*start*/[20, 15], /*hold*/[-25, -5], /*end*/[-65, -40]];

        for (i in 0...tempOffsetArray.length) {
            var arr1:Array<String> = tempOffsetArray[i].split(":");
            var arr2:Array<String> = arr1[1].split(",");
            switch(arr1[0]) {
                case 'start':
                    returnArr.insert(0, [Std.parseInt(arr2[0]), Std.parseInt(arr2[1])]);
                case 'hold':
                    returnArr.insert(1, [Std.parseInt(arr2[0]), Std.parseInt(arr2[1])]);
                case 'end':
                    returnArr.insert(2, [Std.parseInt(arr2[0]), Std.parseInt(arr2[1])]);
            }
        }

        return returnArr;
    }
    
    public function setMinimumSustainLength(?length:Float, ?multBySpeed:Bool = false) {
        if (length != null && length != minSustainLength) {
            minSustainLength = length;
            if (multBySpeed) minSustainLength *= PlayState.SONG.speed / 1.5;
        } else {
            minSustainLength *= PlayState.SONG.speed / 1.5;
        }
        var noteColor:String = colArray[strumNote.noteData].toTitleCase();
        var char:String = (strumNote.player == 0) ? 'Enemy' : 'Player';
        trace('New $char $noteColor Strum Cover sustain length is $minSustainLength.');
    }

    override function update(elapsed:Float) {
        if (strumNote == null) {destroy();}
        setOffset();
        super.update(elapsed);
    }

    function getRatingFromNote(note:Note):String {
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		var daRating:Rating = Conductor.judgeNote(PlayState.instance.ratingsData, noteDiff / PlayState.instance.playbackRate);
        return daRating.name;
    }

    public function start(?note:Note = null) {
        if (!enemySplash) showSplash = (ratingsToShowUpOn.contains(getRatingFromNote(note)));
        visible = showSplash;
        setOffset(0);
        animation.play("start");
        endAnimAlreadyPlayed = false;
    }

    function setOffset(?anim:Int) {
        if (anim != null) posOffset = animOffsets[anim];
        x = strumNote.x + posOffset[0];
        y = strumNote.y + posOffset[1];
    }

    public var endAnimAlreadyPlayed:Bool = false;

    public function end(?force:Bool) {
        if (force != null) visible = force; else visible = showSplash;
        setOffset(2); // For End Anim Offset
        if (endAnimAlreadyPlayed == false) {
            endAnimAlreadyPlayed = true;
            animation.play("end", true);
        }
    }

    function daCallback(anim:String) {
        switch (anim) {
            case "start":
                setOffset(1); // For Hold Anim Offset
                animation.play("hold");

            case "end":
                setOffset(0); // For Start Anim Offset
                showSplash = false;
                visible = false;
        }
    }

    function strumFinishCallback(anim:String) {
        switch (anim) {
            case "confirm":
                if(!endAnimAlreadyPlayed) end();
        }
    }

    public static function getStrumSkinPostfix() {
        var skin:String = '';
        if(ClientPrefs.data.strumSkin != ClientPrefs.defaultData.strumSkin)
            skin = '-' + ClientPrefs.data.strumSkin.trim().toLowerCase().replace(' ', '_');
        return skin;
    }

    public function reloadCover(?texture:String = 'strumCovers/NOTE_covers', ?library:String = 'shared') {
        var lastAnim:String = null;
        if(animation.curAnim != null) lastAnim = animation.curAnim.name;

        // Failsafe
        if ((texture.startsWith('strumCovers/') && !Paths.fileExists('images/' + texture + '.png', IMAGE, true, library))) {
            texture = 'strumCovers/NOTE_covers';
            library = 'shared';
        }

        var skinPostFix:String = getStrumSkinPostfix();
        
        assets = texture + skinPostFix;

        frames = Paths.getSparrowAtlas(texture + skinPostFix, library);
        animation.addByPrefix('start', colArray[strumNote.noteData] + "CoverStart0", 24, false);
        animation.addByPrefix('hold', colArray[strumNote.noteData] + "Cover0", 24, true);
        animation.addByPrefix('end', colArray[strumNote.noteData] + "CoverEnd0", 24, false);
        animation.finishCallback = daCallback;
        if (strumNote != null) strumNote.animation.finishCallback = strumFinishCallback;
        antialiasing = ClientPrefs.data.antialiasing;
        animation.play("end");

        if(lastAnim != null) {animation.play(lastAnim, true);}

        if (Paths.fileExists('images/' + texture + skinPostFix + '.txt', TEXT, true, library)) {
            animOffsets = getOffsetsFromFile(texture + skinPostFix, library);
        }

        alpha = ClientPrefs.data.splashAlpha;
    }
}