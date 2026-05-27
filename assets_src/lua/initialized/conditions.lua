local Wargroove = require "wargroove/wargroove"
local Events = require "initialized/events"

local Conditions = {}

function Conditions.init()
  Events.addToConditionsList(Conditions)
end

function Conditions.populate(dst)
    dst["on_load"] = Conditions.onLoad
end


local loaded = false
function Conditions.onLoad(context)
    if not loaded then
        loaded = true
        return true
    end
    return false
end

return Conditions
