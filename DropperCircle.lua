-- ALPHA CODE!!! THIS IS NOT GOOD FOR PRODUCTION
-- Version a0.1A
-- by SwissalpS and SwissaplS
-- Thanks to the contributions from int
-- Drop sand/gravel/snow in a circle to mark for building circular structures
-- Can also be used to place other node-types
-- fAngleOneNode by int-ua (and other help on the way, thanks int)

-- main switch (software-lock to stop any calculations just remove the --)
--if 1 == 1 then return end

-- radius of the circle. Use integer.
local iRadius = 40

-- centre around which to place the nodes
-- project starfish
local tCentre = {
    x = 30000,
    y = 9014, -- height
    z = 30000
}
-- colloseum
--local tCentre = { x = 9000,  y = 9518,  z = 4000 }

-- offset to jump to, to avoid 'jumping into self' errors
local tSafeVector = {
    x = 0,
    y = 5,
    z = 0
}

-- amount of nodes to place at each location
-- (only usefull for falling nodes like sand and gravel)
-- default to 1
local iDrops = 1

-- ignore angles in range
-- set to negative to not ignore any
-- TODO: multiple pairs so angles overlapping 0 can be ignored too
-- must be careful as we are at limit with heat/time-oun
local nAngleIgnoreLow = -315
local nAngleIgnoreHigh = 361

-- start at this angle [0 to n]
-- probably not used in version .14
local nAngleFirst = 0

-- stop at this angle e.g. 720
-- probably not used in version .14
local nAngleLast = 16000

--------------------------------------------------------------------------- know what you are doing here ----------------------

-- offset of deployer relative to jump-drive
local tOffset = {
    x = 1,
    y = 3,
    z = 1
}

-- port on which the button is on (upper case A,B,C,D)
-- currently not used -> using digiline button on channel 'b'
local sPinNameButton = 'B'

-- port on which the deployer is connected (lower case a,b,c,d)
local sPinDeployer = 'd'

--------------------------------------------------------------------- no more adjustables under this line ----------------------------------------------------------------


-- constant strings
local c = {}
-- owner of this machine
c.owner = 'SwissalpS'
-- variable types
c.sNil = 'nil'
c.bool = 'boolean'
c.number = 'number'
c.string = 'string'
c.table = 'table'
-- we ignore function for now as is not used in any of my projects

-- event.type
c.e = {}
c.e.digiline = 'digiline'
c.e.interrupt = 'interrupt'
c.e.off = 'off'
c.e.on = 'on'
c.e.program = 'program'

-- event.channel
c.c = {}
c.c.butts = 'b' --'buttons'
c.c.keyb = 'keyb'
c.c.jump = 'jumpdrive'
c.c.nic =  'nic0'
c.c.debug = 'lcd' -- nil --'monitor'
c.c.status = nil --'lcd0'
c.c.txt0 = 'txt0'
c.c.touch = 'ts'

-- interrupt intervals
c.i = {}
c.i.status = 500
c.i.deployer = 1.5
c.i.nextJump = 4

-- event.iid (currently not available on pandorabox.io)
c.id = {}
c.id.deployer = '_1'
c.id.nextJump = '_2'

-- bla blas
c.b = {}
c.b.sNA = 'n/a'

-- touch-screen constants
c.ts = {}
c.ts.clear = 'clear'
c.ts.ab = 'addbutton' -- name, label, X, Y, W, H
c.ts.abe = 'addbutton_exit'  -- name, label, X, Y, W, H
c.ts.add = 'adddropdown'  -- name, label, X, Y, W, H, selected_id, choices
c.ts.af = 'addfield' -- name, label, X, Y, W, H, default
c.ts.al = 'addlabel' -- name, label, X, Y
c.ts.avl = 'addvertlabel' -- name, label, X, Y

-- mode constants
c.m = {}
c.m.idle = 0
c.m.dropping = 1
c.m.jumpOut = 2
c.m.jumpIn = 3
c.m.calculating = 4


-- simpler find function
local fFind = function(sHaystack, sNeedle)
    return string.find(sHaystack, sNeedle, 0, true) ~= nil
end -- fFind


-- approximation division
local fDiv = function(nA, nB)
    return (nA - nA %  nB) / nB
end -- fDiv


-- wrapper functions fo Digiline to shorten typing...
local fDLs  = function(sChannel, mMessage)
    digiline_send(sChannel, mMessage)
end -- fDLs


-- simple debugging wrapper
-- whatch out that you don't overload digiline
local fD = function(mMessage)
    -- don't do anything if debugging is turned off in constants
    if nil == c.c.debug then return end

    fDLs(c.c.debug, fDump(mMessage))
end -- fD


-- dump values for debugging
-- recursive function can't be local
fDump = function(mValue)
    local sOut = ''
    local sT = type(mValue)
    if (c.string == sT) or (c.number == sT) then
        -- string or number given
        return mValue
    elseif nil == mValue then
        -- nil given
        return c.sNil
    elseif c.table == sT then
        -- table given
        for sKey, mVal in pairs(mValue) do
            sOut = sOut .. sKey .. ': ' .. fDump(mVal) .. '--' --'\n'
        end -- loop table
        return sOut
    elseif c.bool == sT then
        if mValue then return 'OK' else return 'KO' end
    else
        -- not yet coded type
        return '?' .. sT .. '?'
    end -- switch type
end -- fDump


-- read event
local sET = event.type
local sEC = event.channel or c.sNil
local mEM = event.msg or c.b.sNA
--local sEID = event.iid or c.sNil

-- debugging the event details
--fD(sET .. " " .. sEC .. " " .. sEID .. " " .. fDump(mEM))


-- round numbers naturally and return integer
local fRound = function(n)
    -- round the value splitting at 0.5
    return n + 0.5 - (n - 0.5) % 1
end -- fRound


local fAngleOneNode = function(iR)
    return math.deg(2 * (math.asin(math.sqrt(2) / (2 * iR))))
end -- fAngleOneNode


-- calculate coordinates for a certain angle (X, Z plane)
local fCirclePointHorizontal = function(iR, nAngleDegree)

    -- convert to radians
    local nAngle = nAngleDegree * math.pi / 180
    -- calculate coordinate and multiply with radius
    local nX = iR * math.cos(nAngle)
    local nZ = iR * math.sin(nAngle)

    -- return indexed table with rounded values
    return { x = fRound(nX), z = fRound(nZ) }

end -- fCirclePointHorizontal


-- calculate coordinates for a certain angle in X, Y plane
local fCirclePointVertical = function(iR, nAngleDegree)

    -- convert
    local nAngle = nAngleDegree * math.pi / 180
    -- calculate coordinate and multiply with radius
    local nX = iR * math.cos(nAngle)
    local nY = iR * math.sin(nAngle)

    -- return indexed table with rounded values
    return { x = fRound(nX), y = fRound(nY) }

end -- fCirclePointVertical


-- keep track of points we already dropped nodes at
-- rounding causes duplicates, we don't want to drop more than one
-- node at any given point
local fIsUsedHorizontal = function(tPos)

    -- can't have duplicate on first try (or you really are looking for it ;)
    if 0 == #mem.tPointsHorizontal then return false end

    -- loop through all the stored points we've been at
    local tP
    for i = 1, #mem.tPointsHorizontal do
        tP = mem.tPointsHorizontal[i]
        -- got a match?
        if (tP.x == tPos.x) and (tP.z == tPos.z) then return true end
    end -- loop i

    -- no match found
    return false

end -- fIsUsedHorizontal


local fIsUsedVertical = function(tPos)

    -- can't have duplicate on first try (or you really are looking for it ;)
    if 0 == #mem.tPointsVertical then return false end

    -- loop through all the stored points we've been at
    local tP
    for i = 1, #mem.tPointsVertical do
        tP = mem.tPointsVertical[i]
        -- got a match?
        if (tP.x == tPos.x) and (tP.y == tPos.y) then return true end
    end -- loop i

    -- no match found
    return false

end -- fIsUsedVertical


local fCalculateCirclePointsHorizontal = function()

    fD('Calculating ' .. tostring(0.01 * fRound(100 * mem.nAngleCurrent)))

    local nAngleOneNode = fAngleOneNode(iRadius)
    local nAngle = mem.nAngleCurrent
    local tPos
    while nAngle < 363 do

        -- calculate coordinates for current angle
        tPos = fCirclePointHorizontal(iRadius, nAngle)

        -- add to list if not already
        if not fIsUsedHorizontal(tPos) then
            table.insert(mem.tPointsHorizontal, tPos)
        end

        -- increment angle
        nAngle = nAngle + nAngleOneNode

        -- check if we are ignoring any angles
        if not (0 > nAngleIgnoreLow) then
            while (nAngleIgnoreLow <= nAngle) and (nAngle <= nAngleIgnoreHigh) do
                nAngle = nAngle + nAngleOneNode
            end
        end -- if ignoring angles

        -- avoid time-outs
        if heat >= heat_max - 6 then
            mem.nAngleCurrent = nAngle
            interrupt(c.i.deployer)
            return
        end -- if done a batch

    end -- loop while

    fD('Done calculating')

    mem.iMode = c.m.jumpOut
    interrupt(c.i.deployer)

end -- fCalculateCirclePointsHorizontal


local fDoDrop = function()

    port[sPinDeployer] = not pin[sPinDeployer]

    mem.nCountDrops = mem.nCountDrops + .5
    if  mem.nCountDrops < iDrops then

        -- repeat
        interrupt(c.i.deployer)

    else

        -- reset counter
       mem.nCountDrops = 0

       mem.iMode = c.m.jumpOut

       --fD('Done Dropping')

       interrupt(c.i.nextJump)

    end -- if repeat

end -- fDoDrop


local fJumpTo = function(tPos)

    -- apply offset adjustments
    local iVal = tCentre.x + tOffset.x + tPos.x
    -- send to drive
    fDLs(c.c.jump, { command = 'set', key = 'x', value = iVal} )
    iVal = tCentre.z + tOffset.z + tPos.z
    fDLs(c.c.jump, { command = 'set', key = 'z', value = iVal} )
    iVal = tCentre.y + tOffset.y + tPos.y
    fDLs(c.c.jump, { command = 'set', key = 'y', value = iVal } )

    -- and actually attempt to jump
    fDLs(c.c.jump, { command = 'jump' } )

end -- fJumpTo


---------------------------------------------------------- fDoNext -----------------

local fDoNext = function()

    -- main switch toggeled on or not?
    if not mem.bMain then return end

    if mem.iMode == c.m.calculating then

        fCalculateCirclePointsHorizontal()

        return

    end -- if calculating

    if mem.iCountPoints > #mem.tPointsHorizontal then

        mem.iMode = c.m.idle

        if 0 == #mem.tPointsHorizontal then

            fD('Error: no points!')

        else

            fD('Done, returning to starting point')

            fDLs(c.c.jump, { command = 'set', key = 'x', value = mem.JDinfo.x} )
            fDLs(c.c.jump, { command = 'set', key = 'z', value = mem.JDinfo.z} )
            fDLs(c.c.jump, { command = 'set', key = 'y', value = mem.JDinfo.y} )

            -- and actually attempt to jump
            fDLs(c.c.jump, { command = 'jump' } )

        end -- which is it

        return

    end -- error or done

    local tPos0 = mem.tPointsHorizontal[mem.iCountPoints]
    tPos0.y = tCentre.y
    if mem.iMode == c.m.jumpOut then

        local tPos1 = {
            x = tPos0.x + tSafeVector.x,
            y = tPos0.y + tSafeVector.y,
            z = tPos0.z + tSafeVector.z
        }

        fJumpTo(tPos1)

    elseif mem.iMode == c.m.jumpIn then

        fJumpTo(tPos0)

    elseif mem.iMode == c.m.dropping then

        fDoDrop()

    else

        fD('unknown mode: ' .. tostring(mem.iMode))

    end -- switch mode

end -- fDoNext


local fHandleJDinfo = function()

    mem.JDinfo.radius = mEM.radius
    mem.JDinfo.x = mEM.target.x
    mem.JDinfo.y = mEM.target.y
    mem.JDinfo.z = mEM.target.z

    mem.iMode = c.m.calculating

    fDoNext()

end -- fHandleJDinfo


local fHandleJDresponse = function()

    -- is it response to 'get' command?
    if nil ~= mEM.radius then

        fHandleJDinfo(mEM)

        return

    end -- if response to 'get'

    mem.bSuccess = mEM['success']

    local sOut
    if mem.bSuccess then

        sOut = 'good'

        if mem.iMode == c.m.jumpIn then

            mem.iMode = c.m.dropping

            interrupt(c.i.deployer)

        else

            mem.iMode = c.m.jumpIn

            interrupt(c.i.nextJump)

        end -- switch mode

    else
        --fD('fail')

        sOut = 'fail'

        if mEM.time then

            mem.sJDinfo = mEM.time
            --fD('<'..mem.sJerror..'>')
            local s = mem.sJDinfo

            -- check for obstructed/self -> move to next angle
            -- or else it's mapgen/power/uncharted -> wait
            local sFirst = s:sub(8, 8) or '!'
            local bSelf = 'j' ==  sFirst
            local bObstructed = 'J' == sFirst
            local bUncharted = 'r' == sFirst
            local bMapgen = 'm' == sFirst

            if bSelf then

                fD('Error: jump into self')
                sOut = sOut .. ' S'

                -- should no longer happen, so we halt here

            elseif bObstructed then -- move on to next point

                sOut = sOut .. ' O'

                interrupt(c.i.deployer)

                mem.iCountPoints = mem.iCountPoints + 1

            else --if bUncharted or bMapgen or power --> wait

                interrupt(c.i.nextJump)

                if bUncharted then

                    sOut = sOut .. ' U'

                elseif bMapgen then

                    sOut = sOut .. ' M'

                else

                    sOut = sOut .. ' P'

                end -- switch error

            end -- switch error

        else
            -- did not have time value in event.msg

            mem.sJDinfo = ''

            sOut = sOut .. ' ?'

        end -- if got time value

    end -- switch success or fail

    fD(sOut .. ' ' .. tostring(mem.iCountPoints))

end -- fHandleJDresponse


local fReset = function()

    -- reset values kept in mem
    mem.bMain = false
    mem.bSuccess = false
    mem.iCountPoints = 1
    mem.iMode = c.m.idle
    mem.JDinfo = {}
    mem.JDinfo.radius = 0
    mem.nAngleCurrent = 0
    mem.nCountDrops = 0
    mem.sJDinfo = ''
    mem.tPointsHorizontal = {}
    mem.tPointsVertical = {}

    fDLs(c.c.jump, { command = 'reset'} )
    fDLs(c.c.jump, { command = 'get'} )

    fD('Reset')

end -- fReset


-- 'First run' (when 'Execute' is clicked on code-edit-form)
-- this is the 'init' portion --------------------------------------------------------init---------------------------------------------
if c.e.program == sET then

    fReset()

-- digiline events ------------------------------------------------------------digilines-------------------------------------
elseif c.e.digiline ==  sET then

----------------------------------------------------------------------------jumpdrive-------------------------
    if c.c.jump == sEC then
        --fD('got jumpdrive resp')

        fHandleJDresponse()

    ------------------------------------------------------------buttons-----------------------
    elseif c.c.butts == sEC then

        mem.bMain = not mem.bMain

        if mem.bMain then return fDoNext() end

        -- buttons ----------------------------END buttons-------------------

    end -- stwitch channel

    -- END digiline -------------------------------------END digiline-----------------------------
-- pin high events -------------------------------------pin high----------------------
elseif c.e.on == sET then

    -- END pin high --------------------------------------END pin high----------------------------
-- pin low events --------------------------------------------------pin low-------------------------------------
elseif c.e.off == sET then

    local sPin = event.pin.name
    --fD('Pin: ' .. sPin)
--[[
    if sPinNameButton == sPin then
        --fD('butt nxt')

        --fDoNext()
        mem.nAngleCurrent = mem.nAngleCurrent + nAngleStep

    end -- switch pin
--]]

    -- END pin low ------------------------------------------------------END pin low----------------------
-- interrupt events -------------------------------------------------------------interrupt events -----------------------------------
elseif c.e.interrupt == sET then
    --fD('interrupt')

    fDoNext()

-- END interrupt ---------------------------------------------------------------END interrrupts-----------------------------------------
-- uncaught events
else

    fD('uncaught event')

end -- switch event-type
