--[[ ALPHA CODE!!! THIS IS NOT GOOD FOR PRODUCTION
    Version a0.0
    by SwissalpS
    This is a template I use for most of my lua controller scripts
--]]

-- main switch (software-lock to stop any calculations just remove the --)
--if 1 == 1 then return end

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
c.i.short = 1.5
c.i.medium = 4

-- event.iid (currently not available on pandorabox.io)
c.id = {}
c.id.short = '_1'
c.id.medium = '_2'

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


-- read event
local sET = event.type
local sEC = event.channel or c.sNil
local mEM = event.msg or c.b.sNA
--local sEID = event.iid or c.sNil

-- debugging the event details
fD(sET .. " " .. sEC .. " " .. sEID .. " " .. fDump(mEM))

-- 'First run' (when 'Execute' is clicked on code-edit-form)
-- this is the 'init' portion --------------------------------------------------------init---------------------------------------------
if c.e.program == sET then

    -- reset values kept in mem
    mem.bMain = false

    -- END first run ----------------------------------------------------------------END init ------------------------------------------
-- digiline events ------------------------------------------------------------digilines-------------------------------------
elseif c.e.digiline ==  sET then
----------------------------------------------------------------------------jumpdrive-------------------------
    if c.c.jump == sEC then
        --fD('got jumpdrive resp')
        -----------end -- jumpdrive ---------------------
    ------------------------------------------------------------buttons-----------------------
    elseif c.c.butts == sEC then

        mem.bMain = not mem.bMain

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

    -- END pin low ------------------------------------------------------END pin low----------------------
-- interrupt events -------------------------------------------------------------interrupt events -----------------------------------
elseif c.e.interrupt == sET then
    --fD('irr')
-- END interrupt ---------------------------------------------------------------END interrrupts-----------------------------------------
-- uncaught events
else
    fD('uncaught event')
    return
end -- switch event-type
