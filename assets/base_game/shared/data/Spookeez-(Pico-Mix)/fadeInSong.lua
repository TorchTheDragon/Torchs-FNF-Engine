function onCreate()
    makeLuaSprite('black', '', 0,0)
    makeGraphic('black', 1280, 720, '000000')
    setObjectCamera('black', 'hud')
    setObjectOrder('black', 0)
    addLuaSprite('black')
end


function onSongStart()
    doTweenAlpha('intro', 'black', 0, (crochet/2000)*48,'sineInOut')
end

function onStepHit()
	if curStep >= 12222 then
	cancelTween('intro')
        setProperty('black.alpha', 0)
    end
end