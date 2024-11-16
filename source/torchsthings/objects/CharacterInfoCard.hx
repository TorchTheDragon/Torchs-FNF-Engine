package torchsthings.objects;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import objects.HealthIcon;

// This is just added for preperation of use in the Character Menu - Torch
class CharacterInfoCard extends FlxSprite {
    private var character = "";
    private var biography = "";

    var charName:FlxText;
    var bio:FlxText;
    var icon:HealthIcon;
    var background:FlxSprite;
    var overlay:FlxSprite;

    public function new(character:String = "bf", biography:String = "") {
        super();
        getCharacter(character);
        this.biography = biography;
    }

    function getCharacter(character:String) {
        this.character = character;
        icon = new HealthIcon(character, true);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    }
}

typedef CharInfoData = {
    var name:String;
    var description:String;
    var offsets:Array<Float>;
    var color:Array<Int>;
}