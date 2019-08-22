local AOW = require "age_of_wargroove/age_of_wargroove"
local Events = require "initialized/events"
local Wargroove = require "wargroove/wargroove"
local Constants = require "constants"

local Actions = {}

-- This is called by the game when the map is loaded.
function Actions.init()
  Events.addToActionsList(Actions)
end

function Actions.populate(dst)
    dst["modify_gold_at_pos"] = Actions.modifyGoldAtPos
    dst["remove_generate_gold_per_turn_from_pos"] = Actions.removeGenerateGoldPerTurnFromPos
    dst["generate_gold_per_turn_from_pos"] = Actions.generateGoldPerTurnFromPosAction
    dst["set_tech_level"] = Actions.setTechLevel
    dst["spawn_global_state_unit"] = Actions.spawnGlobalStateUnit
    dst["draw_tech_level_effect"] = Actions.drawTechLevelEffect
    dst["set_init_pop_cap"] = Actions.setInitialPopulationCap
    dst["modify_population_cap"] = Actions.modifyCurrentPopulation
    dst["report_dead_village"] = Actions.reportDeadVillage
end

function Actions.reportDeadVillage(context)
    for i, u in ipairs(context.deadUnits) do
        if u.unitClassId == "city" or u.unitClassId == "water_city" then
            AOW.setPopulationCap(u.playerId, AOW.getPopulationCap(u.playerId) - Constants.populationPerVillage)
        elseif u.unitClassId == "hq" then
            AOW.setPopulationCap(u.playerId, AOW.getPopulationCap(u.playerId) - Constants.populationPerHQ)
        end
    end
end

function Actions.modifyCurrentPopulation(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    
    local popCap = AOW.getPopulationCap(playerId)
    local currentPop = AOW.getCurrentPopulation(playerId)
    
    for i, u in ipairs(allUnits) do
        
        if u.unitClassId == "hq" or u.unitClassId == "city" or u.unitClassId == "water_city" then
        
            if #u.loadedUnits > 0 then
                local popCapUnit = Wargroove.getUnitById(u.loadedUnits[1])
                local currentPopUnit = Wargroove.getUnitById(u.loadedUnits[2])
                popCapUnit:setHealth(popCap, -1)
                currentPopUnit:setHealth(currentPop, -1)
                Wargroove.updateUnit(popCapUnit)
                Wargroove.updateUnit(currentPopUnit)
            else
                Wargroove.spawnUnit(-1, { x = -91, y = -12 }, "villager", true, "")
                Wargroove.waitFrame()
                local popCapUnit = Wargroove.getUnitAt({ x = -91, y = -12 })
                popCapUnit.pos = { x = -99, y = -99 }
                popCapUnit:setHealth(popCap, -1)
                Wargroove.updateUnit(popCapUnit)
                table.insert(u.loadedUnits, popCapUnit.id)
                popCapUnit.inTransport = true
                popCapUnit.transportedBy = u.id
                
                Wargroove.spawnUnit(-1, { x = -91, y = -12 }, "villager", true, "")
                Wargroove.waitFrame()
                local currentPopUnit = Wargroove.getUnitAt({ x = -91, y = -12 })
                currentPopUnit.pos = { x = -99, y = -99 }
                currentPopUnit:setHealth(currentPop, -1)
                Wargroove.updateUnit(currentPopUnit)
                table.insert(u.loadedUnits, currentPopUnit.id)
                currentPopUnit.inTransport = true
                currentPopUnit.transportedBy = u.id
                Wargroove.updateUnit(u)
            end
                
        end
    end
end

function Actions.setInitialPopulationCap(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    
    local popCap = 0;
    
    for i, u in ipairs(allUnits) do
        if u.unitClassId == "hq" then
            popCap = popCap + Constants.populationPerHQ
        elseif u.unitClassId == "city" or u.unitClassId == "water_city" then
            popCap = popCap + Constants.populationPerVillage
        end
    end
    
    AOW.setPopulationCap(playerId, popCap)
    
end

function Actions.generateGoldPerTurnFromPosAction(context)
    local playerId = context:getPlayerId(0)
    
    local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
    for i, u in ipairs(allUnits) do
        if u.unitClassId == "gold_camp" then
            if #u.loadedUnits > 0 then
                local firstUnit = Wargroove.getUnitById(u.loadedUnits[1])
                if firstUnit.unitClassId == "gold" then
                    local numberOfMiners = #u.loadedUnits - 1
                    if numberOfMiners > 0 then
                        AOW.generateGoldPerTurnFromPos(u.pos, u.playerId, numberOfMiners * Constants.goldPerTurnPerMine)
                    end
                end
            end
        end
    end
end

function Actions.drawTechLevelEffect(context)
    local playerId = context:getPlayerId(0)
    
    local techlevel = AOW.getTechLevel(playerId)
    
    if techlevel > 1 then
        local effectToDraw = AOW.getTechLevelEffectName(techlevel)
        local allUnits = Wargroove.getAllUnitsForPlayer(playerId, true)
        for i, u in ipairs(allUnits) do
            if u.unitClassId == "hq" then
                local effectId = Wargroove.spawnUnitEffect(u.id, "units/structures/tech_level", effectToDraw, "", true)
            end
        end
    end
end

function Actions.spawnGlobalStateUnit(context)
    Wargroove.spawnUnit( -1, Constants.globalStateUnitPos, "soldier", true, "")
end

function Actions.setTechLevel(context)
    local playerId = context:getPlayerId(0)
    local techlevel = context:getInteger(1)
    
    AOW.setTechLevel(playerId, techlevel)
end

function Actions.removeGenerateGoldPerTurnFromPos(context)

    for i, unit in ipairs(context.deadUnits) do
        if unit.unitClassId == "gold_camp" then
            local pos = { x = unit.pos.x, y = unit.pos.y }
            
            local goldUnit = Wargroove.getUnitAt(pos)
            
            if goldUnit ~= nil then
                AOW.removeGoldGenerationFromPos(pos)
                
                local goldUnit = Wargroove.getUnitAt(pos)
                
                local goldHp = AOW.getGoldCount(pos) / Constants.goldPerTurnPerMine
                goldUnit:setHealth(goldHp, -1)
                goldUnit.playerId = -2
                Wargroove.updateUnit(goldUnit)
            end
        end
    end

end

function Actions.modifyGoldAtPos(context)
    local posX = context:getInteger(0)
    local posY = context:getInteger(1)
    local operation = context:getOperation(2)
    local gold = context:getInteger(3)
    local pos = { x = posX, y = posY }
    local remainingGold = operation(AOW.getGoldCount(pos), gold)
    AOW.setGoldCount(pos, remainingGold)
    
    local goldHp = remainingGold / Constants.goldPerTurnPerMine * 2
    
    local goldCamp = Wargroove.getUnitAt(pos)
    local goldUnit = Wargroove.getUnitById(goldCamp.loadedUnits[1])
    
    goldUnit:setHealth(goldHp, -1)
    Wargroove.updateUnit(goldUnit)
    
    if goldUnit.health == 0 then
        table.remove(goldCamp.loadedUnits, 1)
        Wargroove.updateUnit(goldCamp)
        AOW.removeGoldGenerationFromPos(pos)
    end
    
end

return Actions
