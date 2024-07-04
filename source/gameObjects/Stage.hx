package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
//import flixel.addons.effects.FlxSkewedSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import states.PlayState;

class Stage extends FlxGroup
{
	public var curStage:String = "";

	// things to help your stage get better
	public var bfPos:FlxPoint  = new FlxPoint();
	public var dadPos:FlxPoint = new FlxPoint();
	public var gfPos:FlxPoint  = new FlxPoint();
	public var gfVersion:String = "";

	public var foreground:FlxGroup;

	public function new() {
		super();
		foreground = new FlxGroup();
	}

	public function reloadStageFromSong(song:String = "test"):Void
	{
		var stageList:Array<String> = [];
		
		stageList = switch(song)
		{
			default: ["stage"];
			
			case "collision": ["mugen"];
			
			case "senpai"|"roses": 	["school"];
			case "thorns": 			["school-evil"];
			
			//case "template": ["preload1", "preload2", "starting-stage"];
		};
		
		/*
		*	makes changing stages easier by preloading
		*	a bunch of stages at the create function
		*	(remember to put the starting stage at the last spot of the array)
		*/
		for(i in stageList)
			reloadStage(i);
	}

	public function reloadStage(curStage:String = "")
	{
		this.clear();
		foreground.clear();
		
		gfPos.set(660, 580);
		/*dadPos.set(100,700);
		bfPos.set(850, 700);*/
		dadPos.set(260, 700);
		bfPos.set(1100, 700);
		gfVersion = getGfVersion(curStage);
		// setting gf to "" makes her invisible
		
		PlayState.defaultCamZoom = 1.0;
		
		this.curStage = curStage;
		switch(curStage)
		{
			default:
				this.curStage = "stage";
				PlayState.defaultCamZoom = 0.9;
				
				var bg = new FlxSprite(-600, -600).loadGraphic(Paths.image("backgrounds/stage/stageback"));
				bg.scrollFactor.set(0.6,0.6);
				add(bg);
				
				var front = new FlxSprite(-580, 440);
				front.loadGraphic(Paths.image("backgrounds/stage/stagefront"));
				add(front);
				
				var curtains = new FlxSprite(-600, -400).loadGraphic(Paths.image("backgrounds/stage/stagecurtains"));
				curtains.scrollFactor.set(1.4,1.4);
				foreground.add(curtains);
				
			case "mugen":
				PlayState.defaultCamZoom = 0.7;
				//gfPos.y += 80;
				dadPos.x -= 100;
				
				var bg = new FlxSprite(-640, -1000).loadGraphic(Paths.image("backgrounds/mugen/mugen"));
				add(bg);
				
			case "school":
				bfPos.x -= 70;
				dadPos.x += 50;
				gfPos.x += 20;
				gfPos.y += 50;
				
				var bgSky = new FlxSprite().loadGraphic(Paths.image('backgrounds/school/weebSky'));
				bgSky.scrollFactor.set(0.1, 0.1);
				add(bgSky);
				
				var bgSchool:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('backgrounds/school/weebSchool'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				add(bgSchool);
				
				var bgStreet:FlxSprite = new FlxSprite(-200).loadGraphic(Paths.image('backgrounds/school/weebStreet'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				add(bgStreet);
				
				var fgTrees:FlxSprite = new FlxSprite(-200 + 170, 130).loadGraphic(Paths.image('backgrounds/school/weebTreesBack'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				add(fgTrees);
				
				var bgTrees:FlxSprite = new FlxSprite(-200 - 380, -1100);
				bgTrees.frames = Paths.getPackerAtlas('backgrounds/school/weebTrees');
				bgTrees.animation.add('treeLoop', CoolUtil.intArray(18), 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				
				var treeLeaves:FlxSprite = new FlxSprite(-200, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('backgrounds/school/petals');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.animation.play('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				add(treeLeaves);
				
				var bgGirls = new FlxSprite(-100, 175); // 190
				bgGirls.frames = Paths.getSparrowAtlas('backgrounds/school/bgFreaks');
				bgGirls.scrollFactor.set(0.9, 0.9);
				
				var girlAnim:String = "girls group";
				if(PlayState.SONG.song == 'roses')
					girlAnim = 'fangirls dissuaded';
				
				bgGirls.animation.addByIndices('danceLeft',  'BG $girlAnim', CoolUtil.intArray(14),		"", 24, false);
				bgGirls.animation.addByIndices('danceRight', 'BG $girlAnim', CoolUtil.intArray(30, 15), "", 24, false);
				bgGirls.animation.play('danceLeft');
				bgGirls._stepHit = function(curStep:Int)
				{
					if(curStep % 4 == 0)
					{
						if(bgGirls.animation.curAnim.name == 'danceLeft')
							bgGirls.animation.play('danceRight', true);
						else
							bgGirls.animation.play('danceLeft', true);
					}
				}
				add(bgGirls);
				
				// easier to manage
				for(rawItem in members)
				{
					if(Std.isOfType(rawItem, FlxSprite))
					{
						var item:FlxSprite = cast rawItem;
						item.antialiasing = false;
						item.isPixelSprite = true;
						item.scale.set(6,6);
						item.updateHitbox();
						item.x -= 170;
						item.y -= 145;
					}
				}
				
			case "school-evil":
				bfPos.x -= 70;
				dadPos.x += 50;
				gfPos.x += 20;
				gfPos.y += 50;
				
				var bg:FlxSprite = new FlxSprite(400, 100);
				bg.frames = Paths.getSparrowAtlas('backgrounds/school/animatedEvilSchool');
				bg.animation.addByPrefix('idle', 'background 2', 24);
				bg.animation.play('idle');
				bg.scrollFactor.set(0.8, 0.9);
				bg.antialiasing = false;
				bg.scale.set(6,6);
				add(bg);
		}
	}

	public function getGfVersion(curStage:String)
	{
		return switch(curStage)
		{
			case "mugen": "";
			case "school"|"school-evil": "gf-pixel";
			default: "gf";
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	public function stepHit(curStep:Int = -1)
	{
		// put your song stuff here
		
		// beat hit
		if(curStep % 4 == 0)
		{
			
		}
	}
}