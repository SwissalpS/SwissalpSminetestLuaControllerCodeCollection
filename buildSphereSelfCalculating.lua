-- buildSphereSelfCalculating.lua
-- version: 20230718.1912
-- author: SwissalpS
-- licence: MIT
-- description: Build a hollow sphere using digibuilder and a
--              lua-, mooncontroller or pipeworks lua sorting tube.
--              The points are checked one per second. Making this slower
--              than building from a table of precalculated points. However
--              this approach is less likely to time-out.
--
-- to restart a build, uncomment next line and hit 'Execute'. Then comment again.
--do mem = {} return end

-- the sphere's radius 1 to 15, though 1 doesn't make much sense as at least the
-- lua-/mooncontroller needs to be next to the digibuilder.
local iR = 7
-- the itemstring of the material to use
local sMat = 'default:goldblock'
-- the digiline channel of digibuilder
local sC = 'digibuilder'

-- CONFIG END --

local iRo = iR + 1
local iRi = iR
-- how frequently to check, unless your server is set to allow faster building,
-- leave this at 1 or more
local iBeat = 1

local sET = event.type
if 'interrupt' == sET then

  -- calculate distance of current point to centre
  local iD = math.sqrt(
    mem.x * mem.x + mem.y * mem.y + mem.z * mem.z)

  -- if distance is within sphere radius (to build solid sphere, change the
  -- check to: 'if iD <= iRo then')
  if iD <= iRo and iD >= iRi then
    -- attempt to place a node there
    digiline_send(sC, { command = 'setnode', name = sMat,
      pos = { x = mem.x, y = mem.y, z = mem.z } })
  end

  -- increment to next location
  mem.x = mem.x + 1
  if iR < mem.x then
    mem.x = -iR
    mem.y = mem.y + 1
    if iR < mem.y then
      mem.y = -iR
      mem.z = mem.z + 1
      if iR < mem.z then
        mem.z = -iR
        print('done')
        return
      end
    end
  end

  interrupt(iBeat)

elseif 'terminal' == sET then

  -- allows checking progess on mooncontroller. Simply hit Send button in the
  -- mooncontroller's Terminal view. Sometimes node timer fails e.g. server crash
  -- This helps to see that and if the numbers are not progressing, hit Execute.
  print(mem)

elseif 'digiline' == sET then

  if event.msg.success then return end

  -- print error message to mooncontroller's Terminal view
  print(event)

elseif 'program' == sET then

  if not mem.x then mem.x = -iR end
  if not mem.y then mem.y = -iR end
  if not mem.z then mem.z = -iR end

  interrupt(iBeat)

end



---
