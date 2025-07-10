package states.stages.objects;

class MallCrowdErect extends BGSprite 
{
    public function new(x:Float = 0, y:Float = 0, sprite:String = 'christmas/erect/bottomBop', idle:String = 'bottomBop0', hey:String = 'Bottom Level Boppers HEY')
    {
        super(sprite, x, y, 0.9, 0.9, [idle]);
        antialiasing = ClientPrefs.data.antialiasing;
    }
}