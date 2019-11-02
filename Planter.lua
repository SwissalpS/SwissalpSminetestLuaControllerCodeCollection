--do return end
--------------------------------------------------------------------------------
-- auto farm (for plants that need only 1 node space)
-- by SwissalpS
-- Version 20191030
-- control 2 setups next to each other
-- The direction is important as the node detector sends signals E, W, N then S
-- So it's important that the mulching node breaker is signalled after harvesting node breaker
-- Example layout 4 x 5 origin bottom left (SW)
--   Layer y = 1
--      Row z = 1: air, button (manual plant), digiline button (g) (auto mulch toggle), air/poster/sign
--      Row z = 2: air, deployer facing up, digiline tube, tube
--      Row z = 3: air, I/O Expander (c), vertical digiline, timer (k)
--      Row z = 4: air, deployer facing up, tube, tube
--      Row z = 5: air, button (manual plant), air, air
--   Layer y = 2
--      Row z = 1: nothing
--      Row z = 2: air, soil, air, tube
--      Row z = 3: slab, water, vertical digiline, air
--      Row z = 4: air, soil, air, tube
--      Row z = 5: nothing
--   Layer y = 3
--      Row z = 1: button (manual mulch), slab, protected button (manual harvest), air
--      Row z = 2: node breaker (mulch), air/plant, node breaker (harvest), sorting tube
--      Row z = 3: I/O Expander (a), light 14 source, vertical digiline, air
--      Row z = 4: node breaker (mulch), air/plant, node breaker (harvest), sorting tube
--      Row z = 5: button (manual mulch), slab, protected button (manual harvest), air
--   Layer y = 4
--      Row z = 1: nothing
--      Row z = 2: self contained injector, node detector facing down (d), touchscreen (t), air
--      Row z = 3: air, lua controller with this code, vertical digiline, air 
--      Row z = 4: self contained injector, node detector facing down (b), air, air
--      Row z = 5: nothing
--   Layer y = 5 (optional)
--      Row z = 1: nothing
--      Row z = 2: teleporting tube (bonemeal.mulch), air, air, air
--      Row z = 3: nothing
--      Row z = 4: teleporting tube (bonemeal.mulch), air, air, air
--      Row z = 5: nothing
--
-- Set the self contained injectors to stackwise and to split incomming stacks
-- This setup does not handle over-/underflow of deployer, you must regulate that manually.
-- Set the digiline button channel to 'g' and no message, add protection.

-- settings
local c = { c = {}, i = {}, p = {}, t = {} }
c.owner = 'SwissalpS'
-- digiline channels
c.c.button = 'g'
c.c.mulch = 'a'
c.c.plant = 'c'
c.c.timer = 'k'
c.c.touch = 't'
c.c.detector = { 'b', 'd' }
-- interrupt
c.i.timer = 5
-- pin/port
c.p.mulch = { 'b', 'd' } -- on extender
c.p.plant = { 'b', 'd' } -- on extender
c.p.ripe = { 'B', 'D' } -- on lua controller

-- choices
if not mem.tChoicesMulch then
  mem.tChoicesMulch = { 'NO Mulch', 'YES Mulch', '1 Stack' }
  for i = 2, 17 do table.insert(mem.tChoicesMulch, tostring(i) .. ' Stacks') end
end
if not mem.tNames then
  mem.tNames = { 'OFF', 'Tomato', 'Cotton', 'Cocoa' }
end
if not mem.tValues then
  mem.tValues = { 'OFF', 'farming:tomato_8', 'farming:cotton_8', 'farming:cocoa_4' }
end


-- shorten typing...
local fDLs  = digiline_send

local function startTimer(sChannel, nTime)  fDLs(sChannel, 'loop_on') fDLs(sChannel, nTime) end
local function stopTimer(sChannel) fDLs(sChannel, 'loop_off') end
local function oneShotTimer(sChannel, nTime) stopTimer(sChannel) fDLs(sChannel, nTime) end

-- touch screen constants
c.ts = {}
c.ts.clear = 'clear'
c.ts.ab = 'addbutton' -- name, label, X, Y, W, H
c.ts.abe = 'addbutton_exit'  -- name, label, X, Y, W, H
c.ts.add = 'adddropdown'  -- name, label, X, Y, W, H, selected_id, choices
c.ts.af = 'addfield' -- name, label, X, Y, W, H, default
c.ts.al = 'addlabel' -- name, label, X, Y
c.ts.avl = 'addvertlabel' -- name, label, X, Y

-- touch screen 'print'
local function fDLt(tCommand) fDLs(c.c.touch, tCommand) end

local function updateTouch()

  fDLt(c.ts.clear)
  fDLt({ command = c.ts.abe, name = 'a', label = 'Apply', X = 5, Y = 7, W = 2, H = 1 })
  fDLt({ command = c.ts.al, name = 'b', label = c.p.ripe[1], X = 1, Y = 2 })
  fDLt({ command = c.ts.add, name = 'c', label = '', X = 2, Y = 2, W = 2, H = 1, selected_id = mem.tiSelectedCrop[1], choices = mem.tNames })
  fDLt({ command = c.ts.add, name = 'd', label = '', X = 4, Y = 2, W = 1, H = 1, selected_id = mem.tiSelectedMulch[1], choices = mem.tChoicesMulch })
  fDLt({ command = c.ts.al, name = 'e', label = c.p.ripe[2], X = 1, Y = 4 })
  --fDLt({ command = c.ts.al, name = 'h', label = mem.sDebug, X = 1, Y = 7 })
  fDLt({ command = c.ts.add, name = 'f', label = '', X = 2, Y = 4, W = 2, H = 1, selected_id = mem.tiSelectedCrop[2], choices = mem.tNames })
  fDLt({ command = c.ts.add, name = 'g', label = '', X = 4, Y = 4, W = 1, H = 1, selected_id = mem.tiSelectedMulch[2], choices = mem.tChoicesMulch })
 
end -- updateTouch


local function onTouch(mEM)
  -- only act if apply button pressed...
  if not mEM.a then return end
  -- ...and owner clicked
  if c.owner ~= mEM.clicker then return end
  local mVal
  if mEM.c then
    mVal = 1
    for i, s in ipairs(mem.tNames) do if s == mEM.c then mVal = i break end end
    if mVal ~= mem.tiSelectedCrop[1] then
      mem.tiSelectedCrop[1] = mVal
      fDLs(c.c.detector[1], mem.tValues[mVal])
    end
  end
  if mEM.d then
    mVal = 1
    for i, s in ipairs(mem.tChoicesMulch) do if s == mEM.d then mVal = i break end end
    if mVal ~= mem.tiSelectedMulch[1] then
      mem.tbMulch[1] = 1 < mVal
      mem.tiSelectedMulch[1] = mVal
      mem.tiMulch[1] = 99 * (mVal -2)
      if 2 == mVal then mem.tiMulch[1] = 99 * 33 end
    end
  end
  if mEM.f then
    mVal = 1
    for i, s in ipairs(mem.tNames) do if s == mEM.f then mVal = i break end end
    if mVal ~= mem.tiSelectedCrop[2] then
      mem.tiSelectedCrop[2] = mVal
      fDLs(c.c.detector[2], mem.tValues[mVal])
    end
  end
  if mEM.g then
    mVal = 1
    for i, s in ipairs(mem.tChoicesMulch) do if s == mEM.g then mVal = i break end end
    if mVal ~= mem.tiSelectedMulch[2] then
      mem.tbMulch[2] = 1 < mVal
      mem.tiSelectedMulch[2] = mVal
      mem.tiMulch[2] = 99 * (mVal -2)
      if 2 == mVal then mem.tiMulch[2] = 99 * 33 end
    end
  end
  updateTouch()
end -- onTouch


local function onExecute()

  -- init state tables
  mem.tMulch = mem.tMulch or { a = false, b = false, c = false, d = false }
  mem.tPlant = mem.tPlant or { a = false, b = false, c = false, d = false }
  -- if should mulch
  mem.tbMulch = { false, false }
  -- count mulch
  mem.tiMulch = { 0, 0 }
  -- mulching mode (1 = off)
  mem.tiSelectedMulch = { 1, 1 }
  -- flags to signal requires planting
  mem.tbPlant = { true, true }
  -- take turns, don't use both machines on each cycle
  mem.iTurn = 2
  -- keep track of last plant to give deployer time to do so
  mem.tiLastPlant = { os.time(), os.time() }
  -- which crop to check for (1 = off)
  if not mem.tiSelectedCrop then mem.tiSelectedCrop = { 1, 1 } end
  
  updateTouch()

  -- init timer
  startTimer(c.c.timer, c.i.timer)

end -- onExecute


local function onPlant(nIndex)

  if 1 == mem.tiSelectedCrop[nIndex] then return end

  mem.tiLastPlant[nIndex] = os.time()
  mem.tPlant[c.p.plant[nIndex]] = true
  mem.tbPlant[nIndex] = false
  fDLs(c.c.plant, mem.tPlant)

end -- onPlant


local function onTimer()

  -- do one setup at a time, taking turns every timer-step
  if 1 == mem.iTurn then mem.iTurn = 2 else mem.iTurn = 1 end
  local nIndex = mem.iTurn
  if mem.tPlant[c.p.plant[nIndex]] then

    if 4 < os.time() - mem.tiLastPlant[nIndex] then

      mem.tPlant[c.p.plant[nIndex]] = false
      fDLs(c.c.plant, mem.tPlant)

    end -- if long enough ago
  elseif mem.tbPlant[nIndex] then
    onPlant(nIndex)
    return
  end -- if planting or should plant

  -- clear highs even if currently set off
  local bIsHigh = mem.tMulch[c.p.mulch[nIndex]]
  if bIsHigh or (mem.tbMulch[nIndex] and 0 < mem.tiMulch[nIndex]) then

    -- only decrement when going high and not set to continuous mulching
    if (not bIsHigh) and (2 < mem.tiSelectedMulch[nIndex]) then mem.tiMulch[nIndex] = mem.tiMulch[nIndex] -1 end
    mem.tMulch[c.p.mulch[nIndex]] = not mem.tMulch[c.p.mulch[nIndex]]
    fDLs(c.c.mulch, mem.tMulch)

  end -- if mulch active

end -- onTimer


local function onButton()
  
  mem.tbMulch[1] = not mem.tbMulch[1]
  mem.tbMulch[2] = not mem.tbMulch[2]

  if mem.tbMulch[1] then mem.tbPlant[1] = true end
  if mem.tbMulch[2] then mem.tbPlant[2] = true end

  updateTouch()

end -- onButton


local sET = event.type
local sEC = event.channel

if 'program' == sET then
  onExecute()
  return
end -- 

if 'digiline' == sET and c.c.timer == sEC then
  onTimer()
  return
end --

if 'digiline' == sET and c.c.button == sEC then
  onButton()
  return
end --

if 'digiline' == sET and c.c.touch == sEC then
  onTouch(event.msg)
  return
end --

if 'off' == sET then
  local sPin = event.pin.name
  if sPin == c.p.ripe[1] then mem.tbPlant[1] = true
  elseif sPin == c.p.ripe[2] then mem.tbPlant[2] = true
  end
  return
end --

