local singAnims = {'singLEFT', 'singDOWN', 'singUP', 'singRIGHT'}

function onCreatePost()
    if difficulty ~= 2 then
        return close('Diff Not Hard!')
    end
    setProperty('mom.x', 0)

    triggerEvent('Change Character', 'mom', 'spirit')
    setProperty('mom.x', getProperty('dad.x') - 100)
    setProperty('mom.y', getProperty('dad.y') - 300)
    playDadSing = false
    setProperty('mom.alpha', 0)
end

function opponentNoteHit(membersIndex, noteData, noteType, isSustainNote, dType)
    if dType == 0 then
        playAnimOld('dad', singAnims[noteData + 1], true)
        setProperty("dad.holdTimer", 0)
    elseif dType == 1 then
        playAnimOld('mom', singAnims[noteData + 1], true)
        setProperty("mom.holdTimer", 0)
    elseif dType == 2 then
        playAnimOld('dad', singAnims[noteData + 1], true)
        setProperty("dad.holdTimer", 0)
        playAnimOld('mom', singAnims[noteData + 1], true)
        setProperty("mom.holdTimer", 0)
    end
end

function onStepHit()
    if curStep == 318 or curStep == 382 or curStep == 448 then
        doTweenAlpha('spiritAlpha1', 'mom', 0.3, 2, 'linear')
    end

    if curStep == 351 or curStep == 399 then
        doTweenAlpha('spiritAlpha2', 'mom', 0, 1, 'linear')
    end
end