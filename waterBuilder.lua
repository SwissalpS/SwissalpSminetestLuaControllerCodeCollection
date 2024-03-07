--do mem.p.x = -1 mem.p.y = 1 mem.p.z = -1 return end
--do mem = {} return end

-- Title: River Water Builder
-- Author: SwissalpS
-- Version: 20231224_2015
-- Description: Place river water (or other water for that
--              matter) using digibuilder starting from
--              below (can easily be changed)
-- Known issues: placing after cut nodes or beacon beams
--               can fail. Either rerun, place manually
--               or try a rf11.f11.f11un with a.b.zFirst set to true
--               and then one with it set to false (or vv).

local mem = mem
local a = { b = {}, c = {}, f = {}, i = {}, s = {} }

-- booleans
-- increment along Z-axis first or X-axis
a.b.zFirst = false
-- is this code running in a mooncontroller?
a.b.isMoon = clearterm and true or false

-- digiline channels
a.c.builder = 'B'
a.c.butt = 'b'
a.c.injector = 'o'
a.c.lcd = 'm'

-- numbers (integers but also fractions)
a.i.wake = 1
a.i.beat = a.b.isMoon and 1 or .25
-- max. 15 radius for digibuilder on pandorabox
a.i.radius = 15

-- strings
a.s.bucket = 'bucket:bucket_empty'
a.s.portBreaker = 'b'
a.s.water = 'bucket:bucket_river_water'

-- localized shortcuts
local d = digiline_send
local i = interrupt
local print = a.b.isMoon and print or function(m)
  if not a.c.lcd then return end
  d(a.c.lcd, m)-- tostring(m))
end

-- functions
function a.f.reset()

  print('r')

  local iR = a.i.radius
  local iRn = -1 * iR

  mem.iStep = 0

  mem.p1 = {
    x = iRn,
    y = iRn,
    z = iRn
  }

  mem.p2 = {
    x = iR,
    y = -15,
    z = iR
  }

  mem.p = { x = mem.p1.x, y = mem.p1.y, z = mem.p1.z }

  d('x', tostring(mem.p.x))
  d('y', tostring(mem.p.y))
  d('z', tostring(mem.p.z))

end -- a.f.reset


function a.f.isReplaceable(s)

  local t = {
    'air',
    'default:river_water_flowing',
    'default:water_flowing',
    'default:water_source',
    'bucket:bucket_river_water'
  }

  local j = #t
  repeat
    if s == t[j] then return true end
    j = j - 1
  until 0 == j
  return nil

end -- a.f.isReplaceable


function a.f.setMain(b)

  mem.bMain = b
  if b then i(a.i.wake + heat) end
  d(a.c.butt, 'light_o' .. (b and 'n' or 'ff'))

end -- a.f.setMain


function a.f.done()

  a.f.setMain(nil)
  print('done')
  d('y', 'done')

end -- a.f.done


function a.f.scan()

  d(a.c.builder, { command = 'getnode', pos = mem.p })

end -- a.f.scan


function a.f.place()

  d(a.c.builder, {
    command = 'setnode',
    pos = mem.p,
    name = a.s.water
  })

end -- a.f.place


function a.f.increment()

  if a.b.zFirst then

    mem.p.z = mem.p.z + 1
    if mem.p.z > mem.p2.z then
      mem.p.z = mem.p1.z
      d('z', mem.p.z)
      mem.p.x = mem.p.x + 1
      if mem.p.x > mem.p2.x then
        mem.p.x = mem.p1.x
        d('x', mem.p.x)
        mem.p.y = mem.p.y + 1
        if mem.p.y > mem.p2.y then
          d('x', '-')d('y', '-')d('z', '-')
          mem.iStep = nil
          a.f.done()
          return nil
        else
          d('y', tostring(mem.p.y))
        end
      else
        d('x', mem.p.x)
      end
    else
      d('z', mem.p.z)
    end

  else

    mem.p.x = mem.p.x + 1
    if mem.p.x > mem.p2.x then
      mem.p.x = mem.p1.x
      d('x', mem.p.x)
      mem.p.z = mem.p.z + 1
      if mem.p.z > mem.p2.z then
        mem.p.z = mem.p1.z
        d('z', mem.p.z)
        mem.p.y = mem.p.y + 1
        if mem.p.y > mem.p2.y then
          d('x', '-')d('y', '-')d('z', '-')
          mem.iStep = nil
          a.f.done()
          return nil
        else
          d('y', tostring(mem.p.y))
        end
      else
        d('z', mem.p.z)
      end
    else
      d('x', mem.p.x)
    end

  end -- if z or x direction first

  return true

end -- a.f.increment


local sET = event.type
if 'interrupt' == sET then

  if not mem.bMain then return end

  mem.iStep = mem.iStep -1
  if 0 >= mem.iStep then mem.iStep = 3 end

  local iS = mem.iStep
  if 3 == iS then
    -- eject empty bucket(s)
    d(a.c.injector, { name = a.s.bucket })

  --elseif 4 == iS then
    -- fill a bucket
    port[a.s.portBreaker] = true

  elseif 2 == iS then
    -- reset breaker
    port[a.s.portBreaker] = nil

  --elseif 2 == iS then
    -- scan next position
    return a.f.scan()

  elseif 1 == iS then
    -- place at current position
    return a.f.place()

  end

  i(a.i.beat)

elseif 'digiline' == sET then

  local sEC = event.channel

  if a.c.butt == sEC then
    return a.f.setMain(not mem.bMain)
  end

  local mEM = event.msg
  if mEM.error then
    --print(mEM)
    if 'Item not in' == mEM.message:sub(1, 11) then
      print('no bucket')
      -- somehow breaker didn't keep up
      mem.iStep = 0
    else
      print(mEM)
      a.f.increment()
    end
    i(a.i.beat)
    return --a.f.setMain(nil)
  end

  if mEM.param2 then
    -- place response
    if not mEM.success then
      print(mEM)
    end
    a.f.increment()
    i(a.i.beat)
  end


  if mEM.name then
    -- scan response
    if not a.f.isReplaceable(mEM.name) then
      print(mEM.name)
      mem.iStep = mem.iStep + 1
      a.f.increment()
    end
    i(a.i.beat)
  end

elseif 'terminal' == sET then

  if '' ~= event.text then
    a.f.setMain(not mem.bMain)
  end

  print(mem.p)
  print(mem.bMain)
  print(mem.iStep)

elseif 'program' == sET then

  if not mem.iStep then a.f.reset() end

  a.f.setMain(mem.bMain)

end



--

