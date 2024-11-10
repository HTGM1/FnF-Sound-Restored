package states;

import backend.game.GameData.MusicBeatState;
import backend.song.Conductor;
import backend.song.SongData;
import flxanimate.animate.FlxAnim;
import flxanimate.FlxAnimate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import objects.menu.Alphabet;
import states.menu.MainMenuState;

using StringTools;

class TitleState extends MusicBeatState
{
	var textGroup:FlxTypedGroup<Alphabet>;
	var curWacky:Array<String> = ['',''];
	var ngSpr:FlxSprite;
	
	var blackScreen:FlxSprite;
	var gf:FlxAnimate;
	var logoBump:FlxAnimate;
	var HTGMLogo:FlxAnimate;
	
	var enterTxt:FlxSprite;
	var gfCurAnim:String = 'danceLeft';
	
	static var introEnded:Bool = false;


	override function create()
	{
		super.create();
		if(!introEnded)
		{
			new FlxTimer().start(0.5, function(tmr:FlxTimer) {
				CoolUtil.playMusic("freakyMenu");
			});
			
			var allTexts:Array<String> = CoolUtil.coolTextFile('introText');
			curWacky = allTexts[FlxG.random.int(0, allTexts.length - 1)].split('--');
		}
		
		DiscordIO.changePresence("In Title Screen");
		FlxG.mouse.visible = false;
		
		persistentUpdate = true;
		Conductor.setBPM(102);

		

		logoBump = new FlxAnimate(25, 25);
		logoBump.isAnimateAtlas = true;
		logoBump.loadAtlas(Paths.getPath('images/menu/title/logoBumpin'));
		logoBump.showPivot = false;
		logoBump.anim.addBySymbol('bump', 'logoBump', 23, false);
		logoBump.anim.play('bump');
		logoBump.scale.set(1.65,1.65);
		add(logoBump);
		
		gf = new FlxAnimate();
		gf.loadAtlas(Paths.getPath('images/menu/title/gfTitleBump'));
		gf.anim.addBySymbol('danceLeft', 'DanceLeft', 24, false);
		gf.anim.addBySymbol('danceRight', 'Dance Right', 24, false);
		gf.x = FlxG.width - gf.width - 200;
		gf.y = FlxG.height - gf.height - 250;
		gf.scale.set(1.15,1.15);
		add(gf);
		gf.anim.play('danceLeft');
		
		enterTxt = new FlxSprite(1200 / 4);
		enterTxt.frames = Paths.getSparrowAtlas('menu/title/titleEnter');
		enterTxt.animation.addByPrefix('idle', 'Press Enter to Begin', 24, true);
		enterTxt.animation.addByPrefix('pressed', 'ENTER PRESSED', 24, true);
		enterTxt.animation.play('idle');
		enterTxt.y = FlxG.height - enterTxt.height - 60;
		enterTxt.scale.set(1.25,1.25);
		add(enterTxt);
		
		blackScreen = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
		blackScreen.screenCenter();
		add(blackScreen);
		
		textGroup = new FlxTypedGroup<Alphabet>();
		add(textGroup);
		
		ngSpr = new FlxSprite().loadGraphic(Paths.image('menu/title/newgrounds_logo'));
		ngSpr.screenCenter();
		ngSpr.y = FlxG.height - ngSpr.height - 120;
		ngSpr.visible = false;
		ngSpr.scale.set(1.25,1.25);
		add(ngSpr);

		HTGMLogo = new FlxAnimate();
		HTGMLogo.screenCenter();
		HTGMLogo.y = FlxG.height - ngSpr.height - 0;
		HTGMLogo.isAnimateAtlas = true;
		HTGMLogo.loadAtlas(Paths.getPath('images/menu/title/HTGMLogo'));
		HTGMLogo.showPivot = false;
		HTGMLogo.anim.addBySymbol('logoLoop', 'logoLoop', 60, true);
		HTGMLogo.anim.play('logoLoop');
		HTGMLogo.visible = false;
		HTGMLogo.scale.set(.5 ,.5);
		add(HTGMLogo);

		addText([]);
		
		if(introEnded)
			skipIntro(true);
	}
	
	var pressedEnter:Bool = false;
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.sound.music != null)
			if(FlxG.sound.music.playing)
				Conductor.songPos = FlxG.sound.music.time;
		
		if(Controls.justPressed(ACCEPT))
		{
			if(introEnded)
			{
				if(!pressedEnter)
				{
					pressedEnter = true;
					enterTxt.animation.play('pressed');
					FlxG.sound.play(Paths.sound('menu/confirmMenu'));
					CoolUtil.flash(FlxG.camera, 1, 0xFFFFFFFF);
					new FlxTimer().start(2.0, function(tmr:FlxTimer)
					{
						Main.switchState(new MainMenuState());
					});
				}
			}
			else
				skipIntro();
		}
	}
	
	override function beatHit()
	{
		super.beatHit();
		if(!introEnded)
		{
			switch(curBeat)
			{
				case 1:
					addText(['HunterTronGames&Music'], true);
					HTGMLogo.visible = true;
				case 3:
					addText(['present'], false);
				case 4:
					addText([]);
					HTGMLogo.visible = false;
					
				case 5:
					//addText(['In association', 'with']);
					addText(['Not associated', 'with']);
				case 7:
					addText(['newgrounds'], false);
					ngSpr.visible = true;
				case 8:
					addText([]);
					ngSpr.visible = false;
					
				case 9:
					addText([curWacky[0]]);
				case 11:
					addText([curWacky[1]], false);
				case 12:
					addText([]);
				
				//case 13:
					addText(['Friday']);
				case 13:
					addText(['Night'], false);
				case 14:
					addText(['Funkin'], false);
				case 15:
					addText(['Sound Restored!'], false);

				case 16:
					skipIntro();
			}
		}
		
		logoBump.anim.play('bump', true);
		if(gfCurAnim == 'danceLeft') {
     		gf.anim.play('danceRight');
     		gfCurAnim = 'danceRight';
		}
		else {
     		gf.anim.play('danceLeft');
    		gfCurAnim = 'danceLeft';
			}
	}
	
	
	public function skipIntro(force:Bool = false)
	{
		if(introEnded && !force) return;
		introEnded = true;
		
		addText([]);
		ngSpr.visible = false;
		HTGMLogo.visible = false;
		CoolUtil.flash(FlxG.camera, Conductor.crochet * 4 / 1000, 0xFFFFFFFF);
		remove(blackScreen);
	}
	
	public function addText(newText:Array<String>, clearTxt:Bool = true, mainY:Int = 130)
	{
		if(clearTxt) textGroup.clear();
		
		for(i in newText)
		{
			var item = new Alphabet(0, 0, i.toUpperCase(), true);
			item.align = CENTER;
			item.x = FlxG.width / 2;
			item.y = mainY + item.boxHeight * textGroup.members.length;
			item.updateHitbox();
			textGroup.add(item);
		}
	}
}
