-- ALPHA CODE!!! THIS IS NOT GOOD FOR PRODUCTION
-- Version a0.13b
-- by SwissalpS and SwissaplS
-- Thanks to the contributions from int
-- Drop sand/gravel/snow in a circle to mark for building circular structures
-- Can also be used to place other node-types
-- auto nAngleStep and every full circle increment by int
-- at some point refactor all this code: nAngle -> dAngle as it's not an int but a float and I use f for functions so d for double

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

-- amount of nodes to place at each location
-- (only usefull for falling nodes like sand and gravel)
-- default to 1
local iDrops = 1

-- start at this angle 0 to n
local nAngleFirst = 0

-- stop at this angle e.g. 720
local nAngleLast = 16000

-- steps to take in angle (odd numbers are good)
-- for radius 150 use .11
-- for radius under 40 1 seems ok
local nAngleStep = 40

-- every second jump go somewhere else.
-- default is 180 but you may want smth like 90 or 20 depending on location and size of ship
-- not used in version a0.11
local nAngleOddJumps = 45

-- ignore angles in range
-- set to negative to not ignore any
local nAngleIgnoreLow = -315
local nAngleIgnoreHigh = 361

--------------------------------------------------------------------------- know what you are doing here ----------------------

local iShipSize = 3

-- currently jumpdrive freezes with small steps
-- local nAngleStep = math.deg( 2 * ( math.asin( math.sqrt( iShipSize * iShipSize * 2 ) / ( 2 * iRadius ) ) ) )
local nAngleOneNode = math.deg( 2 * ( math.asin( math.sqrt( 2 ) / ( 2 * iRadius ) ) ) )

-- offset of deployer relative to jump-drive
local tOffset = {
    x = 1,
    y = 3,
    z = 1
}

-- port on which the button is on (upper case A,B,C,D)
-- currently not used -> using digiline button on channel 'b'
local sPortButton = 'B'

-- port on which the deployer is connected (lower case a,b,c,d)
local sPinDeployer = 'd'

-- use autopilot or not (not recommended as so many things can go wrong, keep at false)
-- not yet implemented, just use a blinky plant on button port
local bAutoPilot = true --false


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


-- round numbers naturally and return integer
local fRound = function(n)
    -- round the value splitting at 0.5
    return n + 0.5 - (n - 0.5) % 1
end -- fRound


-- calculate coordinates for a certain angle (X, Z plane)
local fCirclePointHorizontal = function(iR, nAngleDegree)

    -- convert
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


local fDoDrop = function()

    port[sPinDeployer] = not pin[sPinDeployer]

    mem.fCountDrops = mem.fCountDrops + .5
    if  mem.fCountDrops < iDrops then
        -- repeat
        interrupt(c.i.deployer)
    else
        -- reset counter
       mem.fCountDrops = 0
       mem.bDropping = false
       --fD('Done Dropping')
        if bAutoPilot then
            interrupt(c.i.nextJump)
        end -- auto pilot
    end -- if repeat

end -- fDoDrop

---------------------------------------------------------- fDoNext -----------------

local fDoNext = function()

    -- main switch toggeled on or not?
    if not mem.bMain then return end

    if nAngleLast < mem.nAngleCurrent then return end

    local nAngle = mem.nAngleCurrent
    -- adjust odd jumps
    --if not mem.bEven then nAngle = nAngle + nAngleOddJumps end

    -- calculate next coordinates
    local tPos = fCirclePointHorizontal(iRadius, nAngle)

    -- check if we used this point already
    if not fIsUsedHorizontal(tPos) then

        -- apply offset adjustments
        local iVal = tCentre.x + tOffset.x + tPos.x
        -- send to drive
        fDLs(c.c.jump, { command = 'set', key = 'x', value = iVal} )
        iVal = tCentre.z + tOffset.z + tPos.z
        fDLs(c.c.jump, { command = 'set', key = 'z', value = iVal} )

        -- only send y coordinate on first jump
        -- jump horizontally to avoid a 'jump into itself' error
        if nAngleFirst == mem.nAngleCurrent then
            iVal = tCentre.y + tOffset.y
            fDLs(c.c.jump, { command = 'set', key = 'y', value = iVal } )
        end -- if first jump

        mem.errorCode = false

        -- actually jump!  (but only when rest of program has run)
        fDLs(c.c.jump, { command = 'jump'} )

        table.insert(mem.tPointsHorizontal, tPos)

        -- we don't need interrupt here as we can wait
        -- for jd signal
        -- interrupt(c.i.deployer, c.id.deployer)

    else
        fD('pos used')
        -- we need an interrupt now to keep going
        interrupt(c.i.deployer)
    end -- if not used pos

    -- get out of infResete loops
    if mem.nAnglePrevious == mem.nAngleCurrent then
        mem.nAngleCurrentRetries = mem.nAngleCurrentRetries +1
        -- tried 4 times? that's enough
        if 4 == mem.nAngleCurrentRetries then
            mem.nAngleCurrent = mem.nAngleCurrent + nAngleStep
            mem.nAngleCurrentRetries = 0
        end
    else
        mem.nAngleCurrentRetries = 0
    end

    local nAngleAdditionalIncrement = 0
    -- check if crossing 0 angle
    if (mem.nAnglePrevious % 360 > 180) and (mem.nAngleCurrent % 360 < 180) then
        nAngleAdditionalIncrement = nAngleOneNode
        fD('+1 node angle')
    end

    mem.nAnglePrevious = mem.nAngleCurrent
    mem.nAngleCurrent = mem.nAngleCurrent + nAngleStep + nAngleAdditionalIncrement
    -- do we have an ignore-range? if not negative for low then yes
    if not (0 > nAngleIgnoreLow) then
        while (mem.nAngleCurrent % 360 > nAngleIgnoreLow)
          and (mem.nAngleCurrent % 360 < nAngleIgnoreHigh) do
            mem.nAngleCurrent = mem.nAngleCurrent + nAngleStep
        end -- loop out of ignore range
    end -- if using ignore

    mem.bEven = not mem.bEven

    -- output some info
    local sEvenOdd = 'Even'
    if not mem.bEven then sEvenOdd = 'Odd' end
    fD(tostring(mem.nAngleCurrentRetries) .. '-' .. sEvenOdd .. '-' .. tostring(nAngle))

end -- fDoNext


local fHandleJDresponse = function(mEM)

    local sOut
    mem.errorCode = not mEM['success']
    if mem.errorCode then
        --fD('fail')
        sOut = 'fail'
        mem.bDropping = false
        interrupt(c.i.nextJump)

        if event.msg.time then
            mem.sJerror = event.msg.time
            --fD('<'..mem.sJerror..'>')
            local s = mem.sJerror

            -- check for obstructed/self/uncharted -> move to next angle
            -- or else it's mapgen/power -> wait
            local sFirst = s:sub(8, 8) or '!'
            local bSelf = 'j' ==  sFirst
            local bObstructed = 'J' == sFirst
            local bUncharted = 'r' == sFirst
            local bMapgen = 'm' == sFirst

            if bSelf or bObstructed then -- Jump target is obstructed

                -- wait and try next
                if bSelf then sOut = sOut .. ' S' else sOut = sOut .. ' O' end

            else

                -- wait and try again
                mem.nAngleCurrent = mem.nAngleCurrent - nAngleStep
                mem.bEven = not mem.bEven
                table.remove(mem.tPointsHorizontal)
                if bMapgen then sOut = sOut ..  ' M'
                  else sOut = sOut .. ' P' end

            end -- switch error type

        else

            mem.sJerror = ''
            sOut = sOut .. ' ?'

        end -- if got time message, normally do but jic

    else -- if success or not

        sOut = 'good'
        mem.bDropping = true
        interrupt(c.i.deployer)

    end -- if success

    fD(sOut .. ' ' .. tostring(mem.nAngleCurrent))

end -- fHandleJDresponse


local fReset = function()

    nAngleStep = math.deg( 2 * ( math.asin( math.sqrt( iShipSize * iShipSize * 2 ) / ( 2 * iRadius ) ) ) )
    nAngleStep = fRound(nAngleStep * 100) * 0.01

    -- reset values kept in mem
    mem.nAngleCurrent = nAngleFirst
    mem.fCountDrops = 0
    mem.tPointsHorizontal = {}
    mem.tPointsVertical = {}
    mem.bEven = true
    mem.sJerror = ''
    mem.errorCode = 0
    mem.nAngleCurrentRetries = 0
    mem.nAnglePrevious = nAngleFirst -1
    mem.bDropping = false
    mem.bMain = false

end -- fReset


-- read event
local sET = event.type
local sEC = event.channel or c.sNil
local mEM = event.msg or c.b.sNA
--local sEID = event.iid or c.sNil

-- debugging the event details
--fD(sET .. " " .. sEC .. " " .. sEID .. " " .. fDump(mEM))

-- 'First run' (when 'Execute' is clicked on code-edit-form)
-- this is the 'init' portion --------------------------------------------------------init---------------------------------------------
if c.e.program == sET then

    fReset()

-- digiline events ------------------------------------------------------------digilines-------------------------------------
elseif c.e.digiline ==  sET then
----------------------------------------------------------------------------jumpdrive-------------------------
    if c.c.jump == sEC then
        --fD('got jumpdrive resp')
        fHandleJDresponse(mEM)
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
    if sPortButton == sPin then
        --fD('butt nxt')

        --fDoNext()
        mem.nAngleCurrent = mem.nAngleCurrent + nAngleStep

    end -- switch pin

    -- END pin low ------------------------------------------------------END pin low----------------------
-- interrupt events -------------------------------------------------------------interrupt events -----------------------------------
elseif c.e.interrupt == sET then
    --fD('irr')

    if not mem.bDropping then
        fDoNext()
        return
    end -- if not dropping but autopilot

    if mem.errorCode then return end

    fDoDrop()

    return

-- END interrupt ---------------------------------------------------------------END interrrupts-----------------------------------------
-- uncaught events
else
    fD('uncaught event')
    return
end -- switch event-type
