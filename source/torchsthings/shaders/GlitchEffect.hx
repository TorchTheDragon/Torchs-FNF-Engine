package torchsthings.shaders;

import lime.utils.Assets;
import flixel.addons.display.FlxRuntimeShader;
import flixel.util.FlxTimer;

class GlitchEffect extends FlxRuntimeShader {
    var glitchTimer:FlxTimer;
    public var chromatic:Bool = true;
    public var jitter:Bool = true;
    public var wave:Bool = true;
    public var scanlines:Bool = true;
    public var chunkShift:Bool = true;
    public var invert:Bool = false;
    public var doTimer(default, set):Bool = true;

    public function new(?chromatic:Bool = true, ?jitter:Bool = true, ?wave:Bool = true, ?scanlines:Bool = true, ?chunkShift:Bool = true, ?invert:Bool = false, ?doTimer:Bool = true) {
        var source = Assets.getText(Paths.shaderFragment('Glitch', 'torchs_assets'));
        source += "\n#define INSTANCE_ID_" + Std.string(Std.random(999)); // This makes sure you can have MULTIPLE of this effect if you want
        super(source);
        this.chromatic = chromatic;
        this.jitter = jitter;
        this.wave = wave;
        this.scanlines = scanlines;
        this.chunkShift = chunkShift;
        this.invert = invert;
        glitchTimer = new FlxTimer();
        this.doTimer = doTimer;
        randomizeGlitches();
    }

    var time:Float = 0.0;
    public function update(elapsed:Float):Void {
        time += elapsed;
        setFloat("iTime", time);
    }

    inline function intFromPercent(num:Float):Int {
        return Std.int(num * 100);
    }

    function superRandom():Float {
        // Old, might be lag cause
        //return FlxG.random.float(FlxG.random.float(FlxG.random.float(0, 1), FlxG.random.float(0, 1)), FlxG.random.float(FlxG.random.float(0, 1), FlxG.random.float(0, 1)));
        return FlxG.random.float(FlxG.random.float(0, 1), FlxG.random.float(0, 1)); //Reduced Amount, hopefully this helps.
    }

    public var chunkScaleInt:Array<Int> = [5, 10, 10, 20];
    public var chunkShiftScaleInt:Array<Int> = [2, 5, 5, 20];
    public var chunkInvertScaleInt:Array<Int> = [4, 8, 8, 24];

    public function randomizeGlitches():Void {
        /*
        // Old, might be lag cause
        if (chromatic == true) setBool("enableChromatic", FlxG.random.bool(intFromPercent(FlxG.random.float(superRandom(), superRandom()))));
        if (jitter == true) setBool("enableJitter", FlxG.random.bool(intFromPercent(FlxG.random.float(superRandom(), superRandom()))));
        if (wave == true) setBool("enableWave", FlxG.random.bool(intFromPercent(FlxG.random.float(superRandom(), superRandom()))));
        if (scanlines == true) setBool("enableScanlines", FlxG.random.bool(intFromPercent(FlxG.random.float(superRandom(), superRandom()))));
        if (chunkShift == true) setBool("enableChunkShift",  FlxG.random.bool(intFromPercent(FlxG.random.float(superRandom(), superRandom()))));
        if (invert == true) setBool("enableInvert", FlxG.random.bool(intFromPercent(FlxG.random.float(superRandom(), superRandom()))));
        */
        if (chromatic == true) setBool("enableChromatic", FlxG.random.bool(intFromPercent(superRandom())));
        if (jitter == true) setBool("enableJitter", FlxG.random.bool(intFromPercent(superRandom())));
        if (wave == true) setBool("enableWave", FlxG.random.bool(intFromPercent(superRandom())));
        if (scanlines == true) setBool("enableScanlines", FlxG.random.bool(intFromPercent(superRandom())));
        if (chunkShift == true) setBool("enableChunkShift",  FlxG.random.bool(intFromPercent(superRandom())));
        if (invert == true) setBool("enableInvert", FlxG.random.bool(intFromPercent(superRandom())));

        setFloat("glitchSeed", FlxG.random.float(0, superRandom() * 100));
        setFloat("chunkScale", FlxG.random.float(FlxG.random.int(chunkScaleInt[0], chunkScaleInt[1]), FlxG.random.int(chunkScaleInt[2], chunkScaleInt[3])));
        setFloat("chunkShiftScale", FlxG.random.float(FlxG.random.int(chunkShiftScaleInt[0], chunkShiftScaleInt[1]), FlxG.random.int(chunkShiftScaleInt[2], chunkShiftScaleInt[3])));
        setFloat("chunkInvertScale", FlxG.random.float(FlxG.random.int(chunkInvertScaleInt[0], chunkInvertScaleInt[1]), FlxG.random.int(chunkInvertScaleInt[2], chunkInvertScaleInt[3])));
    }

    function set_doTimer(value:Bool):Bool {
        doTimer = value;
        scheduleGlitchRefresh();
        return doTimer;
    }
    function scheduleGlitchRefresh():Void {
        if (glitchTimer != null) glitchTimer.cancel();
        if (doTimer) {
            var delay:Float = FlxG.random.float(0.5, FlxG.random.float(0.5, 5.0));
            glitchTimer.start(delay, (_) -> {
                randomizeGlitches();
                scheduleGlitchRefresh();
            });
        }
    }
}