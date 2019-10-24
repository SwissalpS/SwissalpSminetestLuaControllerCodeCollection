--do return end
-- Quarry.lua v20191024
-- Jump Drive code for quarry where scout is also jd for mothership.
-- by SwissalpS
-- Defaults to radius 1 scout in centre of radius 12 quarry mothership
-- Use touchscreen to navigate the repetitive movements of getting the
-- next target area clear with scout to quarry system.
-- This program expects quarry to dig directly under centre of mothership.

--[[
1) Set Mothership Location
2) Jump with scout to next location and [Set Next Mothership Location] over where you want quarry to dig next.
3) [R1 d SE] (or [R11 Payload Bay] first and dig that away if needed)
4) [R11 Payload Bay]
5) [R1 into Mother Ship]
6) Restart quarry
7) [R1 d NW] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
8) [R1 d SW] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
9) [R1 d NE] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
10) [R1 u SE] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
11) [R1 u NW] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
12) [R1 u SW] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
13) [R1 u NE] -> [R11 Payload Bay] -> [R1 into Mother Ship] -> dig
14) [R12 down] or if mothership is not directly over next location step 14b
14b) you need to jump to next position manually
15) return to step 1 and at 2 just do [R1 down] and [Set Next Mothership Location]
--]]


-- Radius when scout, expected to be considerably smaller than mothership radius.
local iRadiusScout = 1
-- Radius of mothership
local iRadiusMother = 12
-- If you have multiple quarries then this is the combined radius of the hole they make.
local iRadiusQuarry = 11
-- currently quarry digs 50 deep on pandorabox.io, so that's the down/up step
local iQuarryDepth = 50

-- without further modifications bellow, this program expects the quarry(ies) to be
-- on lowest mothership node facing inward.

-- This code uses an attempt of what could be put into a mod as library
-- it is in condensed form, so not that easy to read
-- Some functions and variables are not used in this program. I want
-- to know to what extent a library mod could work. If loading code
-- directly from luac or through the mod should not be a difference, I hope.
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
tl.c.m.quarry = 1
tl.c.m.scout = 2
tl.c.m.scoutAuto = 3
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


-- touch screen 'print'
tl.fdlt = function(tCommand) tl.fdls(tl.c.c.touch, tCommand) end


-- round numbers naturally and return integer
tl.fround = function(n) return n + 0.5 - (n - 0.5) % 1 end -- fRound


tl.fpossame = function(tPosA, tPosB)  if tPosA.x ~= tPosB.x then return false end  if tPosA.y ~= tPosB.y then return false end  if tPosA.z ~= tPosB.z then return false end  return true end -- tl.fpossame -- fIsSamePos


-- make sure you are passing valid position tables
tl.fposadd = function(tPosA, tPosB)  return { x = tPosA.x + tPosB.x, y = tPosA.y + tPosB.y, z = tPosA.z + tPosB.z } end -- tl.fposadd -- fAddVector

-- make sure you are passing valid position tables
tl.fpossubtract = function(tPosA, tPosB)  return { x = tPosA.x - tPosB.x, y = tPosA.y - tPosB.y, z = tPosA.z - tPosB.z } end -- tl.fpossubtract -- fSubtractVector


-- check if two rectangles intersect
tl.fposintersect = function(tPosA, iRadiusA, tPosB, iRadiusB)
    local tAR = {x = iRadiusA, y = iRadiusA, z = iRadiusA}
	local tA1 = tl.fpossubtract(tPosA, tAR)
	local tA2 = tl.fposadd(tPosA, tAR)

    local tBR = {x = iRadiusB, y = iRadiusB, z = iRadiusB}
	local tB1 = tl.fpossubtract(tPosB, tBR)
	local tB2 = tl.fposadd(tPosB, tBR)

	local bX = (tB1.x <= tA2.x and tB1.x >= tA1.x) or (tB2.x <= tA2.x and tB2.x >= tA1.x)
	local bY = (tB1.y <= tA2.y and tB1.y >= tA1.y) or (tB2.y <= tA2.y and tB2.y >= tA1.y)
	local bZ = (tB1.z <= tA2.z and tB1.z >= tA1.z) or (tB2.z <= tA2.z and tB2.z >= tA1.z)

	return bX and bY and bZ
end -- fposintersect


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
tDiffs.up = fMP(0, iQuarryDepth, 0)
tDiffs.down = fMP(0, -1 * iQuarryDepth, 0)
-- this may need to be set manually. This assumes power is on east side of mothership and west on scout
tDiffs.charging = fMP(1 + iRadiusMother + iRadiusScout, -6, 0)

local iDiameterMother = 1 + (2 * iRadiusMother)
local iDiameterScout = 1 + (2 * iRadiusScout) -- not used
local iDiameterQuarry = 1 + (2 * iRadiusQuarry) -- not used
local iDiameterMotherNeg = -1 * iDiameterMother
local iDiameterScoutNeg = -1 * iDiameterScout -- not used
local iDiameterQuarryNeg = -1 * iDiameterQuarry -- not used
tDiffs.north = fMP(0, 0, iDiameterMother)
tDiffs.south = fMP(0, 0, iDiameterMotherNeg)
tDiffs.west = fMP(iDiameterMotherNeg, 0, 0)
tDiffs.east = fMP(iDiameterMother, 0, 0)
tDiffs.payload = fMP(0, -1 * (iRadiusMother + iRadiusQuarry -3), 0)
tDiffs.uSW = fMP(-3, 3, -3)
tDiffs.uSE = fMP(3, 3, -3)
tDiffs.uNW = fMP(-3, 3, 3)
tDiffs.uNE = fMP(3, 3, 3)
tDiffs.dSW = fMP(-3, -3, -3)
tDiffs.dSE = fMP(3, -3, -3)
tDiffs.dNW = fMP(-3, -3, 3)
tDiffs.dNE = fMP(3, -3, 3)

local tModes = { 'OFF', 'Quarry', 'Scout', 'Scout Auto' }

-- read event
local sET = event.type
local sEC = event.channel or tl.c.sNil
local mEM = event.msg or tl.c.b.sNA
local sEID = event.iid or tl.c.sNil


-- basic clear and info
local fUpdateTouchBasic = function()
    local sOut = 'Current location:                 x: ' .. tostring(mem.JDinfo.x) .. ' y: ' .. tostring(mem.JDinfo.y) .. ' z: ' .. tostring(mem.JDinfo.z) .. ' r: '  .. tostring(mem.JDinfo.radius)
    sOut = sOut .. '\nMothership location:          '
    if nil == mem.tMothership then sOut = sOut .. 'not set' else sOut = sOut .. ' x: ' .. tostring(mem.tMothership.x) .. ' y: ' .. tostring(mem.tMothership.y) .. ' z: ' .. tostring(mem.tMothership.z) end
    sOut = sOut .. '\nNext Mothership location: '
    if nil == mem.tNext then sOut = sOut .. 'not set' else sOut = sOut .. ' x: ' .. tostring(mem.tNext.x) .. ' y: ' .. tostring(mem.tNext.y) .. ' z: ' .. tostring(mem.tNext.z) end

    tl.fdlt({ command = 'clear' })
    tl.fdlt({ command = tl.c.ts.add, name = 'x', label = 'x', X = 7, Y = 0, W = 2, H = 1, selected_id = mem.iMode +1, choices = tModes })
    tl.fdlt({ command = tl.c.ts.al, name = 'y', label = mem.sError, X = 0, Y = 8 })
    tl.fdlt({ command = tl.c.ts.al, name = 'z', label = sOut, X = 0, Y = 0 })
end -- fUpdateTouchBasic


local fUpdateTouchModeQuarry = function()
    local sRM = 'R' .. tostring(iRadiusMother)
    local sRS = 'R' .. tostring(iRadiusScout)
    local sRQ = 'R' .. tostring(iRadiusQuarry)
    tl.fdlt({ command = tl.c.ts.ab, name = 'a', label = 'Set\nMothership Location', X = 4, Y = 2, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'b', label = sRS .. ' into\nMothership', X = 2, Y = 2, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'c', label = 'Read from drive', X = 4, Y = 0, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'd', label = sRQ .. ' to Payload Bay', X = 7, Y = 2, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'e', label = sRM .. ' down', X = 0, Y = 3, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'f', label = sRS .. ' bellow', X = 7, Y = 3, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'g', label = sRS .. ' to charging', X = 0, Y = 2, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'h', label = 'Set\nNext Mothership Location', X = 4, Y = 6, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'i', label = sRS .. ' u SW', X = 7, Y = 4, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'j', label = sRS .. ' u NW', X = 8, Y = 4, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'k', label = sRS .. ' u SE', X = 7, Y = 5, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'l', label = sRS .. ' u NE', X = 8, Y = 5, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'm', label = sRS .. ' d SW', X = 7, Y = 6, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'n', label = sRS .. ' d NW', X = 8, Y = 6, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'o', label = sRS .. ' d SE', X = 7, Y = 7, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'p', label = sRS .. ' d NE', X = 8, Y = 7, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'q', label = sRS .. ' above', X = 7, Y = 1, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.avl, name = 'r', label = 'Relative to MSL', X = 6, Y = 1 })
    tl.fdlt({ command = tl.c.ts.avl, name = 's', label = 'Relative to NMSL', X = 6, Y = 5 })
    tl.fdlt({ command = tl.c.ts.al, name = 't', label = 'Read comment in code for more information\nd SE -> d NW -> d SW, d NE, u SE, u NW, u SW, u NE', X = 0, Y = 5 })
    tl.fdlt({ command = tl.c.ts.al, name = 'u', label = mem.sHistory, X = 0, Y = 6 })
end -- fUpdateTouchModeQuarry


local fUpdateTouchModeScout = function()
    tl.fdlt({ command = tl.c.ts.ab, name = 'c', label = 'Read from drive', X = 4, Y = 0, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.al, name = 'sa', label = 'Jump Vector', X = 1, Y = 4 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'sb', label = 'Jump', X = 0, Y = 1, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.abe, name = 'ss', label = 'Show', X = 2, Y = 1, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'st', label = 'Reset', X = 4, Y = 1, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sc', label = '++E++', X = 2, Y = 2, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sd', label = '+E+', X = 2, Y = 3, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'se', label = '++U++', X = 4, Y = 2, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sf', label = '+U+', X = 4, Y = 3, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sg', label = '++N++', X = 5, Y = 2, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sh', label = '+N+', X = 5, Y = 3, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'si', label = '-W-', X = 2, Y = 5, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sj', label = '--W--', X = 2, Y = 6, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sk', label = '-D-', X = 4, Y = 5, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sl', label = '--D--', X = 4, Y = 6, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sm', label = '-S-', X = 5, Y = 5, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'sn', label = '--S--', X = 5, Y = 6, W = 1, H = 1 })
    tl.fdlt({ command = tl.c.ts.ab, name = 'so', label = 'Set Radius 1', X = 8, Y = 4, W = 2, H = 1 })
    tl.fdlt({ command = tl.c.ts.af, name = 'sx', label = 'sx', X = 3, Y = 4, W = 1, H = 1, default = tostring(mem.tScout.tVector.x) })
    tl.fdlt({ command = tl.c.ts.af, name = 'sy', label = 'sy', X = 4, Y = 4, W = 1, H = 1, default = tostring(mem.tScout.tVector.y) })
    tl.fdlt({ command = tl.c.ts.af, name = 'sz', label = 'sz', X = 5, Y = 4, W = 1, H = 1, default = tostring(mem.tScout.tVector.z) })
    tl.fdlt({ command = tl.c.ts.af, name = 'sr', label = 'sr', X = 7, Y = 4, W = 1, H = 1, default = tostring(mem.tScout.iRadius) })
end -- fUpdateTouchModeScout


local fUpdateTouch = function()
    fUpdateTouchBasic()
    if tl.c.m.quarry == mem.iMode then
        fUpdateTouchModeQuarry()
    elseif tl.c.m.scout == mem.iMode then
        fUpdateTouchModeScout()
    end
end -- fUpdateTouch


local fCheckIntersectWithMother = function()
    if tl.fposintersect(mem.tMothership, iRadiusMother, mem.JDinfo, iRadiusQuarry) then
      mem.sError = 'That would damage mothership!'
      fUpdateTouch()
      return true
    end
    return false
end -- fCheckIntersectWithMother


local fHandleTouchQuarry = function()
    if mEM.a then
        mem.tMothership = tl.fmp(mem.JDinfo.x, mem.JDinfo.y, mem.JDinfo.z)
        fUpdateTouch()
        return true
    elseif mEM.b and (nil ~= mem.tMothership) then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(mem.tMothership)
        return true
    elseif mEM.c then
        tl.fjdg()
        return true
    elseif mEM.d and (nil ~= mem.tMothership) then
        tl.fjdr(iRadiusQuarry)
    if fCheckIntersectWithMother() then return true end
        tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.payload))
        return true
    elseif mEM.e and (nil ~= mem.tMothership) then
        tl.fjdr(iRadiusMother)
        -- TODO: find a way to allow using this without having to be in mothership but also not damaging when near it
        tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.down))
        return true
    elseif mEM.f and (nil ~= mem.tMothership) then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.down))
        return true
    elseif mEM.g and (nil ~= mem.tMothership) then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.charging))
        return true
    elseif mEM.h then
        mem.sHistory = ''
        mem.tNext = tl.fmp(mem.JDinfo.x, mem.JDinfo.y, mem.JDinfo.z)
        fUpdateTouch()
        return true
    elseif mEM.q and (nil ~= mem.tMothership) then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tMothership, tDiffs.up))
        return true
    elseif nil == mem.tNext then
        return false
    elseif mEM.i then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uSW))
        mem.sHistory = mem.sHistory .. 'uSW '
        return true
    elseif mEM.j then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uNW))
        mem.sHistory = mem.sHistory .. 'uNW '
        return true
    elseif mEM.k then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uSE))
        mem.sHistory = mem.sHistory .. 'uSE '
        return true
    elseif mEM.l then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.uNE))
        mem.sHistory = mem.sHistory .. 'uNE '
        return true
    elseif mEM.m then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dSW))
        mem.sHistory = mem.sHistory .. 'dSW '
        return true
    elseif mEM.n then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dNW))
        mem.sHistory = mem.sHistory .. 'dNW '
        return true
    elseif mEM.o then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dSE))
        mem.sHistory = mem.sHistory .. 'dSE '
        return true
    elseif mEM.p then
        tl.fjdr(iRadiusScout)
        tl.fjdj2(tl.fposadd(mem.tNext, tDiffs.dNE))
        mem.sHistory = mem.sHistory .. 'dNE '
        return true
    end
    return false
end -- fHandleTouchQuarry


local fHandleTouchScout = function()
    local mVal = nil
    if mEM.c then
        tl.fjdg()
        return true
    end
    if mEM.sx then
        mVal = tonumber(mEM.sx)
        if nil ~= mVal then mem.tScout.tVector.x = mVal end
    end
    if mEM.sy then
        mVal = tonumber(mEM.sy)
        if nil ~= mVal then mem.tScout.tVector.y = mVal end
    end
    if mEM.sz then
        mVal = tonumber(mEM.sz)
        if nil ~= mVal then mem.tScout.tVector.z = mVal end
    end
    if mEM.sr then
        mVal = tonumber(mEM.sr)
        if nil ~= mVal then mem.tScout.iRadius = mVal end
    end
    if mEM.sb then
        tl.fjdr(mem.tScout.iRadius)
        tl.fjdj2(tl.fposadd(mem.JDinfo, mem.tScout.tVector))
        return true
    elseif mEM.sc then
        mem.tScout.tVector.x = mem.tScout.tVector.x + 1 + (4 * mem.tScout.iRadius)
    elseif mEM.sd then
        mem.tScout.tVector.x = mem.tScout.tVector.x + 1 + (2 * mem.tScout.iRadius)
    elseif mEM.se then
        mem.tScout.tVector.y = mem.tScout.tVector.y + 1 + (4 * mem.tScout.iRadius)
    elseif mEM.sf then
        mem.tScout.tVector.y = mem.tScout.tVector.y + 1 + (2 * mem.tScout.iRadius)
    elseif mEM.sg then
        mem.tScout.tVector.z = mem.tScout.tVector.z + 1 + (4 * mem.tScout.iRadius)
    elseif mEM.sh then
        mem.tScout.tVector.z = mem.tScout.tVector.z + 1 + (2 * mem.tScout.iRadius)
    elseif mEM.si then
        mem.tScout.tVector.x = mem.tScout.tVector.x - 1 - (2 * mem.tScout.iRadius)
    elseif mEM.sj then
        mem.tScout.tVector.x = mem.tScout.tVector.x - 1 - (4 * mem.tScout.iRadius)
    elseif mEM.sk then
        mem.tScout.tVector.y = mem.tScout.tVector.y - 1 - (2 * mem.tScout.iRadius)
    elseif mEM.sl then
        mem.tScout.tVector.y = mem.tScout.tVector.y - 1 - (4 * mem.tScout.iRadius)
    elseif mEM.sm then
        mem.tScout.tVector.z = mem.tScout.tVector.z - 1 - (2 * mem.tScout.iRadius)
    elseif mEM.sn then
        mem.tScout.tVector.z = mem.tScout.tVector.z - 1 - (4 * mem.tScout.iRadius)
    elseif mEM.so then
        mem.tScout.iRadius = 1
    elseif mEM.ss then
        tl.fjdr(mem.tScout.iRadius)
        tl.fjdp(tl.fposadd(mem.JDinfo, mem.tScout.tVector))
        tl.fjds()
        return true
    elseif mEM.st then
        tl.fjdreset()
        tl.fjdg()
        return true
    end
    return false
end -- fHandleTouchScout


local fHandleJDinfo = function()

    mem.JDinfo.radius = mEM.radius
    mem.tScout.iRadius = mem.JDinfo.radius
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
    tl.fjdreset()
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
    if nil == mem.iMode then mem.iMode = tl.c.m.quarry end
    if nil == mem.sHistory then mem.sHistory = '' end
    if nil == mem.tScout then mem.tScout = { iRadius = mem.JDinfo.radius, tVector = tl.fmp(0, 3, 0) } end

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
        if tl.c.m.quarry == mem.iMode then
          if fHandleTouchQuarry() then return end
        elseif tl.c.m.scout == mem.iMode then
          if fHandleTouchScout() then return end
        end
        if mEM.x then
          for i, s in ipairs(tModes) do if s == mEM.x then mem.iMode = i -1 break end end
          fUpdateTouch()
        end
    end
end