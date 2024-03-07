-- buildSphereFromTable.lua
-- version: 20230718.1912
-- author: SwissalpS
-- licence: MIT
-- description: Build a hollow sphere using digibuilder and a
--              lua-, mooncontroller or pipeworks lua sorting tube.
--              The points are taken from a table of precalculated points.
--              However this approach is prone to time-out.
--              It was possible to build a sphere with radius 15 in singleplayer
--              but there were many time-outs. Also some editors may have
--              difficulty with the long one-line table of points.

-- some switches that may be helpful to get a stalled build to continue
--do mem.i = nil mem.bMain = true return end
--do mem.bMain = true return end

-- table of points, idea was to have each index hold the corresponding points
-- for a radius of the index. Turns out, luacontrollers serialize function
-- often times-out even with just the points for an r15 sphere.
local p = {}
-- the radius to use. (only used to get the correct index from array p)
local iR = 1
-- populate just the radius you want to build. The points can be taken from
-- output of helpers/findShperePoints.luas
-- e.g. p[15]={{...}, ....} for radius 15
-- replace this with something that makes sense, a radius 1 sphere can't really
-- be built around a digibuilder as at least one node is occupied by a controller.
p[1]={{x=-1,y=0,z=0},{x=0,y=-1,z=0},{x=0,y=0,z=-1},{x=0,y=0,z=0},{x=0,y=0,z=1},{x=0,y=1,z=0},{x=1,y=0,z=0}}

-- digiline channel of digibuilder
local sC = 'digibuilder'

-- itemstring of node to use to build
local sMat = 'moreores:mithril_block'

-- CONFIG END --

-- how frequently to check, unless your server is set to allow faster building,
-- leave this at 1 or more
local iBeat = 1

local sET = event.type
if 'interrupt' == sET then

  if not mem.bMain then return end

  -- move to next point's index
  mem.i = mem.i - 1
  if 0 == mem.i then print('done') return end

  -- attempt to place the next node
  digiline_send(sC, { command = 'setnode',
    name = sMat,
    pos = p[iR][mem.i] })

  -- run again in a second
  interrupt(iBeat)

elseif 'digiline' == sET then

  if event.msg.success then return end

  print(event.msg)
  -- stop if there was an error (this can safely be commented out)
  mem.bMain = nil

elseif 'terminal' == sET then

  -- show the current index if anything is sent via mooncontroller's Terminal view
  print(mem.i)

elseif 'program' == sET then

  if not mem.i then mem.i = #p[iR] end
  print(mem.i)
  interrupt(iBeat)

end

--
