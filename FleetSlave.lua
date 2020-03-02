--mem.sURLbase = 'https://example.com/nic.php?t=secret&id=fleetID-engineID-areaID' do return end
--do return end
-- FleetSlave.lua v20200301
-- Jump Drive code for NIC controlled fleets
-- by SwissalpS

--[[
Each engine has a luac with this code, a NIC, a protected button and optionally a display.
Set the channel of each to a unique channel eg j0, n0 and l0
Hit the button on each engine to tell server current location. Using any of many methods, set the next coordinates on server.
Again go to each engine and hit the button. Server will respond with 'ok<radius>|<x>|<y>|<z>' and engine jumps there using
given radius.
]]

-- engine ID as string for unique nic and jd channels to avoid cross-contamination when engines are arranged tightly.
local sEngineID = '0'
local sButtonPort = 'B'

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
tl.c.c.jump = 'j' .. sEngineID
tl.c.c.debug = 'l0' --'monitor'
tl.c.c.status = 'l' .. sEngineID
tl.c.c.nic = 'n' .. sEngineID

-- interrupt intervals
tl.c.i = {}
tl.c.i.nextJump = 4

-- bla blas
tl.c.b = {}
tl.c.b.sNA = 'n/a'

-- mode constants
tl.c.m = {}
tl.c.m.idle = 0
tl.c.m.waitingForJDinfo = 1
tl.c.m.waitingForNIC = 2
tl.c.m.waitingToJump = 3
tl.c.m.jumping = 4

tl.fdls = digiline_send

-- simple debugging wrapper
-- whatch out that you don't overload digiline
tl.fd = function(mMessage) if nil == tl.c.c.debug then return end tl.fdls(tl.c.c.debug, tl.fdump(mMessage)) end

-- dump values for debugging
-- recursive function can't be local
-- strangely when in a local table, it works without having to be global
tl.fdump = function(mValue) local sOut = '' local sT = type(mValue) if tl.c.string == sT then return mValue elseif tl.c.number == sT then return tostring(mValue) elseif nil == mValue then return tl.c.sNil elseif tl.c.table == sT then for sKey, mVal in pairs(mValue) do sOut = sOut .. sKey .. ': ' .. tl.fdump(mVal) .. '--' end return sOut elseif tl.c.bool == sT then if mValue then return 'OK' else return 'KO' end else  return '?' .. sT .. '?' end end

tl.fpossame = function(tPosA, tPosB)  if tPosA.x ~= tPosB.x then return false end  if tPosA.y ~= tPosB.y then return false end  if tPosA.z ~= tPosB.z then return false end  return true end

-- make a pos table from given values
tl.fmp = function(iX, iY, iZ) return { x = iX, y = iY, z = iZ } end

-- request info from jumpdrive
tl.fjdg = function() tl.fdls(tl.c.c.jump, { command = 'get' }) end

-- return a simplified one character error code of jump drive 'time' value
-- when 'success' is not true
-- pass event.msg.time as s
tl.fjdpe = function(s) local sFirst = s:sub(8, 8) or '!' local bSelf = 'j' ==  sFirst  local bObstructed = 'J' == sFirst or 'r' == sFirst  local bUncharted = ':' == sFirst  local bMapgen = 'm' == sFirst if bSelf then  return 'S' elseif bObstructed then  return 'O' elseif bUncharted then  return 'U' elseif bMapgen then  return 'M' else return 'P' end end

-- jump jumpdrive
tl.fjdj = function() tl.fdls(tl.c.c.jump, { command = 'jump' }) end

-- simulate jump (jumpdrive)
tl.fjds = function() tl.fdls(tl.c.c.jump, { command = 'show' }) end

-- reset jumpdrive
tl.fjdreset = function() tl.fdls(tl.c.c.jump, { command = 'reset' }) end

local sET = event.type
local mEM = event.msg
local sEC = event.channel

local function fP(s) tl.fdls(tl.c.c.status, s) end

local function pos2string() return tostring(mem.JDinfo.radius) .. '|' .. tostring(mem.JDinfo.x) .. '|' .. tostring(mem.JDinfo.y) .. '|' .. tostring(mem.JDinfo.z) end

local function string2pos(s)
  local tPos = {}
  local iPosSep0 = 1
  local iPosSep1 = string.find(s, '|', iPosSep0, true)
  if nil == iPosSep1 then return nil end
  tPos.r = tonumber(s:sub(iPosSep0, iPosSep1 -1))
  iPosSep0 = iPosSep1 +1
  iPosSep1 = string.find(s, '|', iPosSep0, true)
  if nil == iPosSep1 then return nil end
  tPos.x = tonumber(s:sub(iPosSep0, iPosSep1 -1))
  iPosSep0 = iPosSep1 +1
  iPosSep1 = string.find(s, '|', iPosSep0, true)
  if nil == iPosSep1 then return nil end
  tPos.y = tonumber(s:sub(iPosSep0, iPosSep1 -1))
  tPos.z = tonumber(s:sub(iPosSep1 +1, -1))
  if nil == tPos.z then return nil end
  return tPos
end -- string2pos

local function handleReset()
  mem.iMode = tl.c.m.idle
  mem.bLastWasOK = true
  mem.JDinfo = {}
  mem.JDinfo.radius = 0
  mem.sJDinfo = ''
  mem.sError = ''
  fP('idle')
end -- handleReset

local function jumpTo(tPos)
  mem.iMode = tl.c.m.jumping
  tl.fdls(tl.c.c.jump, { command = 'set', r = tPos.r, x = tPos.x, y = tPos.y, z = tPos.z })
  tl.fjdj()
end

local function handleNIC()
  if not mEM.succeeded then
    fP('error ' .. tostring(mEM.code))
    mem.iMode = tl.c.m.idle
    return
  end
  local sOK = mEM.data:sub(1, 2)
  if 'ok' ~= sOK then
    fP('error ?')
    mem.iMode = tl.c.m.idle
    return
  end
  local tPos = string2pos(mEM.data:sub(3, -1))
  if nil == tPos then
    fP('ok - idle')
    mem.iMode = tl.c.m.idle
    return
  end
  fP('jumping')
  mem.iMode = tl.c.m.waitingToJump
  jumpTo(tPos)
end -- handleNIC

local function handleButton()
  if tl.c.m.idle ~= mem.iMode then fP('busy') return end
  mem.iMode = tl.c.m.waitingForJDinfo
  fP('getting pos from JD')
  tl.fjdreset()
  tl.fjdg()
end -- handleButton

local function sendPos()
  fP('sending pos')
  mem.iMode = tl.c.m.waitingForNIC
  local sGet = mem.sURLbase .. '&c=cp&p=' .. pos2string()
  tl.fdls(tl.c.c.nic, sGet)
end -- sendPos

local function handleJDinfo()
  fP('got info')
  mem.JDinfo.radius = mEM.radius
  mem.JDinfo.x = mEM.target.x
  mem.JDinfo.y = mEM.target.y
  mem.JDinfo.z = mEM.target.z
  sendPos()
end -- handleJDinfo

local function handleJD()

  -- is it response to 'get' command?
  if nil ~= mEM.radius then

    handleJDinfo(mEM)
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
      sOut = sOut .. ' ' .. tl.fjdpe(mEM.time)

    else
      -- did not have time value in event.msg

      mem.sJDinfo = ''
      sOut = sOut .. ' ?'

    end -- if got time value
  end -- switch success or fail

  mem.sError = sOut
  fP(sOut .. '\nidle')
  mem.iMode = tl.c.m.idle
end -- handleJD

if tl.c.e.program == sET then
  handleReset()
elseif tl.c.c.nic == sEC then
  handleNIC()
elseif (tl.c.e.off == sET) and (sButtonPort == event.pin.name) then
  handleButton()
elseif tl.c.c.jump == sEC then
  handleJD()
end

-- avoid any digiline messages to be relayed
return
