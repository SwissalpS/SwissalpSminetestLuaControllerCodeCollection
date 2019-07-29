-- ALPHA CODE!!! THIS IS NOT GOOD FOR PRODUCTION
-- Version a0.11b
-- by SwissalpS and SwissaplS
-- Drop sand/gravel/snow in a circle to mark for building circular structures

-- main switch (software-lock to stop any calculations)
--if 1 == 1 then return end

-- radius of the circle. Use integer.
local iRadius = 40

-- centre around which to place the nodes
local tCentre = {
 x = 30000,
 y = 9014, -- height
 z = 30000
}
-- colloseum
--local tCentre = { x = 9000,  y = 9518,  z = 4000 }

-- amount of nodes to place at each location (only usefull for falling nodes like sand and gravel)
-- default to 1
local iDrops = 1

-- start at this angle 0 to n
local iFirstAngle = 1

-- stop at this angle e.g. 720
local iAngleLast = 8888

-- steps to take in angle (odd numbers are good)
-- for radius 150 use .11
-- for radius under 40 1 seems ok
local iAngleStep = 23.5

-- every second jump go somewhere else.
-- default is 180 but you may want smth like 90 or 20 depending on location
-- not used in version a0.11
local fAngleOddJumps = 45

-- ignore angles in range
-- set to negative to not ignore any
local fAngleIgnoreLow = 315
local fAngleIgnoreHigh = 361

--------------------------------------------------------------------------- know what you are doing here ----------------------

-- offset of deployer relative to jump-drive
local tOffset = {
 x = 1,
 y = 1,
 z = 1
}

-- port on which the button is on (upper case A,B,C,D)
local sButton = 'B'

-- port on which the deployer is connected (lower case a,b,c,d)
local sDeployer = 'd'

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
-- event.iid
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


local fFind = function(sHaystack, sNeedle)
 return string.find(sHaystack, sNeedle, 0, true) ~= nil
end


-- approximation division
local fDiv = function(nA, nB)
 return (nA - nA %  nB) / nB
end


-- wrapper functions fo Digiline to shorten typing...
local fDLs  = function(sChannel, mMessage) 
 digiline_send(sChannel, mMessage)
end


-- simple debugging wrapper
local fD = function(mMessage)
 if nil == c.c.debug then return end
 fDLs(c.c.debug, fDump(mMessage))
end

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


-- calculate coordinates for a certain angle 0 to 360
local fCirclePoint = function(iR, iAngleDegree)
 
 -- convert
 local fAngle = iAngleDegree * math.pi / 180
 -- calculate coordinate and multiply with radius
 local fX = iR * math.cos(fAngle)
 local fZ = iR * math.sin(fAngle)

 -- round the values splitting at 0.5
 local iX = fX + 0.5 - (fX - 0.5) % 1
 local iZ = fZ + 0.5 - (fZ - 0.5) % 1

 -- return indexed table
 return { x = iX, z = iZ }

end -- fCirclePoint


-- keep track of points we already dropped nodes at
-- rounding causes duplicates, we don't want to drop more than one
-- node at any given point
local fIsUsed = function(tPos)
 
 -- can't have duplicate on first try (or you really are looking for it ;)
 if 0 == #mem.tUsedPoints then return false end

 -- loop through all the stored points we've been at
 local tP
 for i = 1, #mem.tUsedPoints do
  tP = mem.tUsedPoints[i]
  -- got a match?
  if (tP.x == tPos.x) and (tP.z == tPos.z) then return true end
 end -- loop i

 -- no match found
 return false

end -- fIsUsed


local fDoNext = function()

 -- main switch toggelede on or not?
 if not mem.bMain then return end

-- if 2 * iAngleStep * 360 < mem.iCount then return end
-- if 4 * 360 < mem.iCount then return end
   if iAngleLast < mem.iCount then return end

 local iAngle = mem.iCount
 -- adjust odd jumps
 --if not mem.bEven then iAngle = iAngle + fAngleOddJumps end

 -- calculate next coordinates
 local tPos = fCirclePoint(iRadius, iAngle)

 -- check if we used this point already
 if not fIsUsed(tPos) then

  -- apply offset adjustments
  local nVal = tCentre.x + tOffset.x + tPos.x
  -- send to drive
  fDLs(c.c.jump, { command = 'set', key = 'x', value = nVal} )
  nVal = tCentre.z + tOffset.z + tPos.z
  fDLs(c.c.jump, { command = 'set', key = 'z', value = nVal} )

  -- only send y coordinate on first jump
  -- so jump horizontally to avoid a 'jump into itself' error
  if iFirstAngle == mem.iCount then
   fDLs(c.c.jump, { command = 'set', key = 'y', value = tCentre.y + tOffset.y } )
  end -- if first jump

  mem.errorCode = false

  -- actually jump!  (but only when rest of program has run)
  fDLs(c.c.jump, { command = 'jump'} )

  table.insert(mem.tUsedPoints, tPos)

 -- we don't need interrupt here as we can wait
 -- for jd signal
 -- interrupt(c.i.deployer, c.id.deployer)

 else
  fD('pos used')
  -- we need an interrupt now to keep going
  interrupt(c.i.deployer)
 end -- if not used pos

 -- get out of infinite loops
-- port[sDeployer] = not pin[sDeployer]
 if mem.iCountLast == mem.iCount then
  mem.iCountRetries = mem.iCountRetries +1
  -- tried 4 times? that's enough
   if 4 == mem.iCountRetries then
     mem.iCount = mem.iCount + iAngleStep
     mem.iCountRetries = 0
  end
 else
  mem.iCountRetries = 0
 end
 mem.iCountLast = mem.iCount
 mem.iCount = mem.iCount + iAngleStep
 if not (0 > fAngleIgnoreLow) then
--fD('i')
  while (mem.iCount%360 > fAngleIgnoreLow) and (mem.iCount%360 < fAngleIgnoreHigh) do
   mem.iCount = mem.iCount + iAngleStep
  end -- loop out of ignore range
 end -- if using ignore
 mem.bEven = not mem.bEven
 
 -- output some info
 local sEvenOdd = 'Even'
 if not mem.bEven then sEvenOdd = 'Odd' end
 fD(tostring(mem.iCountRetries) .. '-' .. sEvenOdd .. '-' .. tostring(iAngle))

end -- fDoNext


-- read event
local sET = event.type
local sEC = event.channel or c.sNil
local mEM = event.msg or c.b.sNA
local sEID = event.iid or c.sNil

-- debugging the event details
--fD(sET .. " " .. sEC .. " " .. sEID .. " " .. fDump(mEM))

-- 'First run' (when 'Execute' is clicked on code-edit-form)
-- this is the 'init' portion --------------------------------------------------------init---------------------------------------------
if c.e.program == sET then

 -- reset values kept in mem
 mem.iCount = iFirstAngle
 mem.fCountDrops = 0
 mem.tUsedPoints = {}
 mem.bEven = true
 mem.sJerror = ''
 mem.errorCode = 0
 mem.iCountRetries = 0
 mem.iCountLast = iFirstAngle
 mem.bDropping = false
 mem.bMain = false

  -- END first run ----------------------------------------------------------------END init ------------------------------------------
-- digiline events ------------------------------------------------------------digilines-------------------------------------
elseif c.e.digiline ==  sET then

----------------------------------------------------------------------------jumpdrive-------------------------
 if c.c.jump == sEC then
  --fD('got jumpdrive resp')
  local sOut
  mem.errorCode = not event.msg['success']
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
    local bMapgen = 'm' == sFirst

    if bSelf or bObstructed then -- Jump target is obstructed

     -- wait and try next
     if bSelf then sOut = sOut .. ' S' else sOut = sOut .. ' O' end
     
    else

     -- wait and try again
      mem.iCount = mem.iCount - iAngleStep
      mem.bEven = not mem.bEven
      table.remove(mem.tUsedPoints)
      if bMapgen then sOut = sOut ..  ' M' else sOut = sOut .. ' P' end

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

  fD(sOut .. ' ' .. tostring(mem.iCount))

--[[
  --fD('<'..mem.sJerror..'>')
local sOut = ''
  for mkey, mval in pairs(event.msg) do
   sOut = sOut .. '--' .. mkey
  end
--fD(sOut)

--fD(fDump(mEM))
--]]
 -----------end -- jumpdrive ---------------------
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
 if sButton == sPin then
  --fD('butt nxt')

  --fDoNext()
  mem.iCount = mem.iCount + iAngleStep

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

  port[sDeployer] = not pin[sDeployer]

  mem.fCountDrops = mem.fCountDrops + .5
  if  mem.fCountDrops < iDrops then
   -- repeat 
   interrupt(c.i.deployer)
  else
   -- reset counter
   mem.fCountDrops = 0
   mem.bDropping = false
--   fD('Done Dropping')
   if bAutoPilot then
    interrupt(c.i.nextJump)
   end -- auto pilot
  end -- if repeat

  return

 --end -- deployer
 
-- END interrupt ---------------------------------------------------------------END interrrupts-----------------------------------------
-- uncaught events
else
 fD('uncaught event')
 return
end -- switch event-type
