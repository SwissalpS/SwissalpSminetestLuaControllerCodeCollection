--do return end

local tl = { }
tl.c = { c = { } }
-- owner of this machine
tl.c.owner = 'SwissalpS'
-- variable types
tl.c.sNil = 'nil' tl.c.bool = 'boolean' tl.c.number = 'number' tl.c.string = 'string' tl.c.table = 'table' -- we ignore function for now as is not used in any of my projects

-- event.type
tl.c.e = {}
tl.c.e.digiline = 'digiline' tl.c.e.interrupt = 'interrupt' tl.c.e.off = 'off' tl.c.e.on = 'on' tl.c.e.program = 'program'

-- event.channel
tl.c.c.butts = 'b' --'buttons'
tl.c.c.jump = 'jumpdrive'
tl.c.c.debug = nil --'monitor'
tl.c.c.status = nil --'lcd0'
tl.c.c.touch = 't' --'touchscreen'

-- interrupt intervals
tl.c.i = {}
tl.c.i.nextJump = 40

-- event.iid (currently not available on pandorabox.io)
tl.c.id = {}
tl.c.id.nextJump = '_2'

-- bla blas
tl.c.b = {}
tl.c.b.sNA = 'n/a'

-- mode constants
tl.c.m = {}
tl.c.m.idle = 0
tl.c.m.dropping = 1
tl.c.m.jumpOut = 2
tl.c.m.jumpIn = 3
tl.c.m.calculating = 4

-- touch screen constants
tl.c.ts = {}
tl.c.ts.clear = 'clear'
tl.c.ts.ab = 'addbutton' -- name, label, X, Y, W, H
tl.c.ts.abe = 'addbutton_exit'  -- name, label, X, Y, W, H
tl.c.ts.add = 'adddropdown'  -- name, label, X, Y, W, H, selected_id, choices
tl.c.ts.af = 'addfield' -- name, label, X, Y, W, H, default
tl.c.ts.al = 'addlabel' -- name, label, X, Y
tl.c.ts.avl = 'addvertlabel' -- name, label, X, Y

tl.fdls = digiline_send


-- simple debugging wrapper
-- whatch out that you don't overload digiline
tl.fd = function(mMessage) if nil == tl.c.c.debug then return end tl.fdls(tl.c.c.debug, tl.fdump(mMessage)) end -- tl.fd -- fD


-- dump values for debugging
-- recursive function can't be local
-- strangely when in a local table, it works without having to be global
tl.fdump = function(mValue) local sOut = '' local sT = type(mValue) if tl.c.string == sT then return mValue elseif tl.c.number == sT then return tostring(mValue) elseif nil == mValue then return tl.c.sNil elseif tl.c.table == sT then for sKey, mVal in pairs(mValue) do sOut = sOut .. sKey .. ': ' .. tl.fdump(mVal) .. '--' end return sOut elseif tl.c.bool == sT then if mValue then return 'OK' else return 'KO' end else  return '?' .. sT .. '?' end end -- tl.fdump -- fDump


-- round numbers naturally and return integer
tl.fround = function(n) return n + 0.5 - (n - 0.5) % 1 end -- fRound


tl.fpossame = function(tPosA, tPosB)  if tPosA.x ~= tPosB.x then return false end  if tPosA.y ~= tPosB.y then return false end  if tPosA.z ~= tPosB.z then return false end  return true end -- tl.fpossame -- fIsSamePos


-- make sure you are passing valid position tables
tl.fposadd = function(tPosA, tPosB)  return { x = tPosA.x + tPosB.x, y = tPosA.y + tPosB.y, z = tPosA.z + tPosB.z } end -- tl.fposadd -- fAddVector


-- make a pos table from given values
tl.fmp = function(iX, iY, iZ) return { x = iX, y = iY, z = iZ } end

-- request info from jumpdrive
tl.fjdg = function() tl.fdls(tl.c.c.jump, { command = 'get' }) end


-- return a simplified one character error code of jump drive 'time' value
-- when 'success' is not true
-- pass event.msg.time as s
tl.fjdpe = function(s) local sFirst = s:sub(8, 8) or '!' local bSelf = 'j' ==  sFirst  local bObstructed = 'J' == sFirst or 'r' == sFirst  local bUncharted = ':' == sFirst  local bMapgen = 'm' == sFirst if bSelf then  return 'S' elseif bObstructed then  return 'O' elseif bUncharted then  return 'U' elseif bMapgen then  return 'M' else return 'P' end end -- tl.fjdpe -- fParseJDerror


-- jump jumpdrive
tl.fjdj = function() tl.fdls(tl.c.c.jump, { command = 'jump' }) end


-- simulate jump (jumpdrive)
tl.fjds = function() tl.fdls(tl.c.c.jump, { command = 'show' }) end


-- reset jumpdrive
tl.fjdreset = function() tl.fdls(tl.c.c.jump, { command = 'reset' }) end


-- set target position for jumpdrive
tl.fjdp = function(tPos) tl.fdls(tl.c.c.jump, { command = 'set', key = 'x', value = tPos.x }) tl.fdls(tl.c.c.jump, { command = 'set', key = 'z', value = tPos.z }) tl.fdls(tl.c.c.jump, { command = 'set', key = 'y', value = tPos.y }) end -- tl.fjdp -- fJDsetPos


-- jump to a position giving position table
tl.fjdj2 = function(tPos) tl.fjdp(tPos) tl.fjdj() end -- tl.fjdj2 -- fJumpTo

-- jump to a position giving coordinates as arguments
tl.fjdj2xyz = function(iX, iY, iZ) return tl.fjdj2(tl.fmp(iX, iY, iZ)) end -- tl.fjdj2xyz
tl.fjdpxyz = function(iX, iY, iZ) return tl.fjdp(tl.fmp(iX, iY, iZ)) end -- tl.jdpxyz

-- set radius on jumpdrive
tl.fjdr = function(iR) return tl.fdls(tl.c.c.jump, { command = 'set', key = 'radius', value = iR }) end

-- backwards compatibility
local fDLs = tl.fdls
local fJDsetRadius = tl.fjdr
local fParseJDerror = tl.fjdpe
local fJumpTo = tl.fjdj2
local fMP = tl.fmp


local tDiffs = {}
tDiffs.idle = nil
tDiffs.down = fMP(0, -50, 0)
tDiffs.charging = fMP(14, -6, 0)
tDiffs.north = fMP(0, 0, 24)
tDiffs.south = fMP(0, 0, -24)
tDiffs.west = fMP(0, 0, -24)
tDiffs.east = fMP(0, 0, 24)
tDiffs.payload = fMP(0, -20, 0)
tDiffs.uSW = fMP(-3, 3, -3)
tDiffs.uSE = fMP(3, 3, -3)
tDiffs.uNW = fMP(-3, 3, 3)
tDiffs.uNE = fMP(3, 3, 3)
tDiffs.dSW = fMP(-3, -3, -3)
tDiffs.dSE = fMP(3, -3, -3)
tDiffs.dNW = fMP(-3, -3, 3)
tDiffs.dNE = fMP(3, -3, 3)


-- read event
local sET = event.type
local sEC = event.channel or tl.c.sNil
local mEM = event.msg or tl.c.b.sNA
local sEID = event.iid or tl.c.sNil


local fUpdateTouch = function()
    tl.fdls(tl.c.c.touch, { command = 'clear' })
    local sOut = 'Current location: x: ' .. tostring(mem.JDinfo.x) .. ' y: ' .. tostring(mem.JDinfo.y) .. ' z: ' .. tostring(mem.JDinfo.z) .. ' r: '  .. tostring(mem.JDinfo.radius)
    sOut = sOut .. ' Mothership location: '
    if nil == mem.tMothership then sOut = sOut .. 'not set' else sOut = sOut .. ' x: ' .. tostring(mem.tMothership.x) .. ' y: ' .. tostring(mem.tMothership.y) .. ' z: ' .. tostring(mem.tMothership.z) end
    sOut = sOut .. ' Next Mothership location: '
    if nil == mem.tNext then sOut = sOut .. 'not set' else sOut = sOut .. ' x: ' .. tostring(mem.tNext.x) .. ' y: ' .. tostring(mem.tNext.y) .. ' z: ' .. tostring(mem.tNext.z) end

    tl.fdls(tl.c.c.touch, { command = tl.c.ts.al, name = 'z', label = sOut, X = 0, Y = 0 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.al, name = 'y', label = mem.sError, X = 0, Y = 8 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.ab, name = 'a', label = 'Set Mothership location', X = 0, Y = 1, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'b', label = 'R1 into Mothership', X = 7, Y = 1, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.ab, name = 'c', label = 'Read from drive', X = 0, Y = 2, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'd', label = 'R11 to payload bay', X = 7, Y = 2, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'e', label = 'R12 down', X = 0, Y = 3, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'f', label = 'R1 down', X = 7, Y = 3, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'g', label = 'R1 to charging', X = 0, Y = 4, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.ab, name = 'h', label = 'Set next Mothership location', X = 0, Y = 5, W = 2, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'i', label = 'R1 u SW', X = 5, Y = 4, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'j', label = 'R1 u NW', X = 6, Y = 4, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'k', label = 'R1 u SE', X = 7, Y = 4, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'l', label = 'R1 u NE', X = 8, Y = 4, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'm', label = 'R1 d SW', X = 5, Y = 5, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'n', label = 'R1 d NW', X = 6, Y = 5, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'o', label = 'R1 d SE', X = 7, Y = 5, W = 1, H = 1 })
    tl.fdls(tl.c.c.touch, { command = tl.c.ts.abe, name = 'p', label = 'R1 d NE', X = 8, Y = 5, W = 1, H = 1 })
end


local fHandleJDinfo = function()

    mem.JDinfo.radius = mEM.radius
    mem.JDinfo.x = mEM.target.x
    mem.JDinfo.y = mEM.target.y
    mem.JDinfo.z = mEM.target.z

    fUpdateTouch()

end -- fHandleJDinfo


local fHandleJDresponse = function()

    -- is it response to 'get' command?
    if nil ~= mEM.radius then

        fHandleJDinfo(mEM)

        return

    end -- if response to 'get'

    local bSuccess = mEM['success']

    local sOut
    if bSuccess then

        sOut = ''

        mem.bLastWasOK = true

    else

        mem.bLastWasOK = false

        sOut = 'Error: '

        if mEM.time then

            mem.sJDinfo = mEM.time
            sOut = sOut .. ' ' .. fParseJDerror(mEM.time)

        else
            -- did not have time value in event.msg

            mem.sJDinfo = ''

            sOut = sOut .. ' ?'

        end -- if got time value

    end -- switch success or fail

    mem.sError = sOut
    tl.fjdg()

end -- fHandleJDresponse


local fReset = function()

    -- reset values kept in mem
    mem.bMain = false
    mem.bLastWasOK = true
    mem.JDinfo = {}
    mem.JDinfo.radius = 0
    mem.sJDinfo = ''
    mem.sError = ''

    tl.fjdreset()
    tl.fjdg()

end -- fReset


-- debugging the event details
--tl.fd(sET .. " " .. sEC .. " " .. sEID .. " " .. tl.fdump(mEM))

if tl.c.e.program == sET then
    fReset()
elseif tl.c.e.digiline == sET then
    if tl.c.c.jump == sEC then
        fHandleJDresponse()
    elseif tl.c.c.touch == sEC then
        if mEM.clicker ~= tl.c.owner then return end
        if mEM.a then
            mem.tMothership = tl.fmp(mem.JDinfo.x, mem.JDinfo.y, mem.JDinfo.z)
            fUpdateTouch()
        elseif mEM.b and (nil ~= mem.tMothership) then
            tl.fjdr(1)
            tl.fjdj2(mem.tMothership)
        elseif mEM.c then
            tl.fjdg()
        elseif mEM.d and (nil ~= mem.tMothership) then
            tl.fjdr(11)
            tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.payload))
        elseif mEM.e and (nil ~= mem.tMothership) then
            tl.fjdr(12)
            tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.down))
        elseif mEM.f and (nil ~= mem.tMothership) then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.down))
        elseif mEM.g and (nil ~= mem.tMothership) then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.charging))
        elseif mEM.h then
            mem.tNext = tl.fmp(mem.JDinfo.x, mem.JDinfo.y, mem.JDinfo.z)
            fUpdateTouch()
        elseif nil == mem.tNext then
            return
        elseif mEM.i then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uSW))
        elseif mEM.j then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uNW))
        elseif mEM.k then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uSE))
        elseif mEM.l then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uNE))
        elseif mEM.m then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dSW))
        elseif mEM.n then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dNW))
        elseif mEM.o then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dSE))
        elseif mEM.p then
            tl.fjdr(1)
            tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dNE))
        end
    end
end