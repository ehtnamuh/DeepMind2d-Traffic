---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by samin.
--- DateTime: 27/08/2022 05:32
---

local tables = require 'common.tables'

local AIHelper = {}
AIHelper.__index = AIHelper

--[[
shoots a ray in N,S,E,W direction and returns a a bool table indicating which directions had a hit
ex: omnidirectional_ray_cast(grid, {75, 63}, 1) => {N = false, S = false, E = true, W = false }
]]
function AIHelper:omnidirectional_ray_cast(grid, position, layer, ray_dist)
    local hit = {N = false, S = false, E = false, W = false }
    -- N
    local me_position = tables.shallowCopy(position)
    me_position[2] = me_position[2] - ray_dist
    hit.N, _,_ = grid:rayCast(layer, position,me_position)
    -- E
    me_position = tables.shallowCopy(position)
    me_position[1] = me_position[1] + ray_dist
    hit.E, _,_ = grid:rayCast(layer, position,me_position)
    -- S
    me_position = tables.shallowCopy(position)
    me_position[2] = me_position[2] + ray_dist
    hit.S, _,_ = grid:rayCast(layer, position,me_position)
    -- W
    me_position = tables.shallowCopy(position)
    me_position[1] = me_position[1] - ray_dist
    hit.W, _,_ = grid:rayCast(layer, position, me_position)
    return hit
end


function AIHelper:orientation_to_position(position, orientation, jumpMagnitude)
    local me_position = {}
    if(jumpMagnitude == nil) then
        jumpMagnitude = 1
    end
    local dist = jumpMagnitude
    -- N
    if(orientation == 'N') then
        me_position = tables.shallowCopy(position)
        me_position[2] = me_position[2] - dist
        return me_position
    end
    -- E
    if(orientation == 'E') then
        me_position = tables.shallowCopy(position)
        me_position[1] = me_position[1] + dist
    end
    -- S
    if(orientation == 'S') then
        me_position = tables.shallowCopy(position)
        me_position[2] = me_position[2] + dist
    end
    -- W
    if(orientation == 'W') then
        me_position = tables.shallowCopy(position)
        me_position[1] = me_position[1] - dist
    end
    return me_position
end

function AIHelper:walkable_nodes(grid, position, layer)
    local walkable_nodes = {}
    local hits = self:omnidirectional_ray_cast(grid, position, layer, 1)
    for key,v in pairs(hits) do
        if (not v) then
            walkable_nodes[key] = self:orientation_to_position(position, key)
        end
    end
    return walkable_nodes
end

function AIHelper:L1_distance(source_pos, target_pos)
    return math.abs(target_pos[1] - source_pos[1])+math.abs(target_pos[2] - source_pos[2])
end

function AIHelper:L2_distance(source_pos, target_pos)
    return math.sqrt((target_pos[2] - source_pos[2])^2 + (target_pos[1] - source_pos[1])^2)
end

-- returns string version of grid:position
-- this should not be here
-- make a grid wrapper class later
function AIHelper:pString(position)
    return position[1] .. "," .. position[2]
end


function AIHelper:pEquality(position, target)
    local x =  target[1] - position[1]
    local y =  target[2] - position[2]

    if (x == 0 and y == 0) then
        return true
    else
        return false
    end
end

function AIHelper:pEquality(position, target)
    local x =  target[1] - position[1]
    local y =  target[2] - position[2]

    if (x == 0 and y == 0) then
        return true
    else
        return false
    end
end

return AIHelper