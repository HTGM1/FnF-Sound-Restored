package objects.menu.options;

import flxanimate.animate.FlxAnim;
import flxanimate.FlxAnimate;
import flixel.FlxSprite;

class OptionCheckmark extends FlxAnimate
{
	public var value:Bool = false;

	public function new(value:Bool = false, ?size:Float = 1)
	{
		super();
		this.value = value;
		isAnimateAtlas = true;
		loadAtlas(Paths.getPath('images/menu/Options/OptionsCheckbox'));
		anim.addBySymbol("true", "true", 36, false);
		anim.addBySymbol("false","false",36, false);
		anim.play(Std.string(value), true, false, (value ? 5 : 7));
		scale.set(size, size);
		updateHitbox();
	}

	public function setValue(value:Bool = false)
	{
		this.value = value;
		anim.play(Std.string(value));
	}

	override function updateHitbox()
	{
		super.updateHitbox();
		//offset.x -= 20 * scale.x;
		//offset.y += 22 * scale.y;
		offset.y += 18 * scale.y;
	}
}