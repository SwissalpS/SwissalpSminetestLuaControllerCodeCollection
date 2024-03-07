-- Title: Game Controller Scout
-- Author: SwissalpS
-- Version: 20240307_1526
-- Original Author: Florian Finke aka FeXoR
-- Description:
--[[
Usage:
- mount the game controller (right-click it)
- set direction of travel by looking that way
- increase jump distance (hold the jump key slightly
   moving your mouse or pushing the forward key
   at the same time)
- jump (release the jump button)
Setup:
LUAc with this code attached to:
- Jumpdrive (jumpdrive:engine), digiline channel 'j'
- Digiline Game Controller (digistuff:controller),
    digiline channel 'c'
Optional (for feedback):
- Digiline Noteblock (digistuff:noteblock),
    digiline channel 's'

(See the settings to e.g. change the channels)

Jump on ;)
--]]

local mem, type, interrupt = mem, type, interrupt
local min, floor =  math.min, math.floor
local a = { b = {}, c = {}, f = {}, i = {}, s = {} }

-- settings
-- channels
-- jumpdrive
a.c.jd = 'j'
-- (game) controller
a.c.gc = 'c'
-- noteblock
a.c.nb = 's'

-- numbers
a.i.beat = heat
a.i.maxDist = 48

-- strings
a.s.users = { 'FeXoR', '6r1d', 'SX', 'SwissalpS',
  'Huhhila', 'BuckarooBanzai', 'admin', 'coil',
  'singleplayer' }
a.s.sounds = { 'c', 'd', 'e', 'f', 'g', 'a', 'b', 'c2' }

-- functions
local d = digiline_send

function a.f.allow(sName)

	for _, s in ipairs(a.s.users) do
		if s == sName then return true end
	end
	return false

end -- allow

-- debugging
function a.f.d(m) d('DEBUG', m) end
-- send to game controller
function a.f.gc(m) d(a.c.gc, m) end
-- send to jumpdrive
function a.f.jd(m) d(a.c.jd, m) end
function a.f.jdGet() a.f.jd({ command = 'get' }) end
function a.f.jdj() a.f.jd({ command = 'jump' }) end
-- send to noteblock
function a.f.play(m) d(a.c.nb, m) end

function a.f.handleGameController(mEM)

  if 'player_left' == mEM and nil == mem.jdTarget then

    -- released after jump
    mem.jdForce = 0
    a.f.play('unified_inventory_refill')

  elseif 'table' == type(mEM) then

    if mEM.name and a.f.allow(mEM.name) then

      if mEM.down then

        mem.jdForce = min(mem.jdForce - 1, #a.s.sounds)
        a.f.play(a.s.sounds[mem.jdForce])

      elseif mEM.jump or mEM.up then

        mem.jdForce = min(mem.jdForce + 1, #a.s.sounds)
        a.f.play(a.s.sounds[mem.jdForce])

      else

        if 0 >= mem.jdForce then return end

        if 'table' == type(mEM.look_vector)
          and 'table' == type(mem.jdPos)
          and 'number' == type(mem.jdMinDist)
        then

          local tLV = mEM.look_vector
          local iDist = mem.jdMinDist +
            (a.i.maxDist - mem.jdMinDist) /
            #a.s.sounds * mem.jdForce
          mem.jdTarget = {
            x = floor(.5 + mem.jdPos.x + iDist * tLV.x),
            y = floor(.5 + mem.jdPos.y + iDist * tLV.y),
            z = floor(.5 + mem.jdPos.z + iDist * tLV.z)
          }
          a.f.gc('release')
          interrupt(a.i.beat)

        else

          a.f.d('Insufficient information to set target!')

        end -- if got look_vector

      end -- if input

    else

      -- usage denied
      a.f.play('sine')
      a.f.gc('release')

    end -- if authorized or not

  end -- if released or not

end -- handleGameController

function a.f.handleJD(mEM)

  if 'table' ~= type(mEM) then return end

  if 'table' == type(mEM.position) then

    mem.jdPos = mEM.position

  end
  if 'number' == type(mEM.radius) then

    -- set jump distance slightly larger than diagonal
    -- extent of jumped area even for radius 1
    mem.jdMinDist = min(4 * mEM.radius + 2, a.i.maxDist)

  end
  if true == mEM.success then

    a.f.play('technic_laser_mk1')

  elseif false == mEM.success then

    a.f.play('technic_laser_mk2')

  end

end -- handleJD

-- do stuff
local sET = event.type
if 'interrupt' == sET then

  if not mem.jdPos then
    interrupt(a.i.beat)
    return a.f.jdGet()
  end

  if not mem.jdTarget then return end

  interrupt(a.i.beat)
  a.f.jd({
    command = 'set',
    x = mem.jdTarget.x,
    y = mem.jdTarget.y,
    z = mem.jdTarget.z
  })
  mem.jdTarget = nil
  mem.jdForce = 0
  mem.jdPos = nil
  a.f.jdj()

elseif 'digiline' == sET then

  local sEC = event.channel
  local mEM = event.msg

  if a.c.jd == sEC then
    return a.f.handleJD(mEM)
  end

  if a.c.gc == sEC then
    return a.f.handleGameController(mEM)
  end

elseif 'program' == sET then

  if not mem.jdForce then mem.jdForce = 0 end
  a.f.jdGet()
  a.f.play('digistuff_piezo_short')
  --a.f.play('get_sounds') -- debugging

end -- switch event




--[[
MIT License
Copyright (c) 2024 SwissalpS
Copyright (c) 2021 Florian Finke

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

