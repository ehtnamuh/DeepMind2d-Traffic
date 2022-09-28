---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by samin.
--- DateTime: 01/08/2022 15:51
---

local class = require 'common.class'
local random = require 'system.random'
local aiHelper = require 'AI.avatar_ai_helper'
local maps = require 'maps'

local AvatarAI = class.Class()
local _COMPASS = { 'N', 'E', 'S', 'W' }

--[[
Logic for when a beam should be fired
]]

function AvatarAI:__init__(kwargs)
    self._path = {}
    self._pathIndex = 0
end

function AvatarAI:bot_beam(grid)
    --TODO:
end

function AvatarAI:wayPointFollow(grid, piece,orientation)
    local map = maps["logic"].layout
    local me_position = grid:position(piece)
    local x = (me_position[2] * (64 + 1)) + me_position[1] + 1
    local c = map:sub(x, x)

    if (c == 'e' and (orientation == 'N' or orientation == 'S')) then
        local C = { 'E', 'W' }
        orientation = C[random:uniformInt(1, #C)]
    end
    if (c == 'n' and (orientation == 'E' or orientation == 'W')) then
        local C = { 'N', 'S' }
        orientation = C[random:uniformInt(1, #C)]
    end
    if (c == 'b') then
        if (orientation == 'E') then
            local C = { 'N', 'S', 'E' }
            orientation = C[random:uniformInt(1, #C)]
        elseif (orientation == 'W') then
            local C = { 'N', 'S', 'W' }
            orientation = C[random:uniformInt(1, #C)]
        elseif (orientation == 'S') then
            local C = { 'E', 'S', 'W' }
            orientation = C[random:uniformInt(1, #C)]
        elseif (orientation == 'N') then
            local C = { 'N', 'E', 'W' }
            orientation = C[random:uniformInt(1, #C)]
        end
    end

    local isMoveValid = false
    local walkableNeighbour = aiHelper:walkable_nodes(grid, me_position, grid:layer(piece))
    for tempOrientation, neighbour in pairs(walkableNeighbour) do
        if (tempOrientation == orientation) then
            isMoveValid = true
        end
    end
    if(not isMoveValid) then
        if(orientation == 'N') then
            orientation = 'S'
        elseif(orientation == 'S') then
            orientation = 'N'
        elseif(orientation == 'E') then
            orientation = 'W'
        elseif(orientation == 'W') then
            orientation = 'E'
        end
    end
    return orientation
end

-- Simple bot moving AI function, return a direction to move in
function AvatarAI:computeSimpleMove(grid, piece, target)
    --DRIVING AI
    local ray_dist = 1
    local me_position = grid:position(piece)

    local hits = aiHelper:omnidirectional_ray_cast(grid, me_position, grid:layer(piece), ray_dist)
    local hitN = hits.N
    local hitE = hits.E
    local hitS = hits.S
    local hitW = hits.W

    ---- raw distance to target
    me_position = grid:position(piece)
    local x = target[1] - me_position[1]
    local y = target[2] - me_position[2]

    -- next Node choosing logic
    local orientation = {}
    if (y < 0 and not hits.N) then
        orientation = {}
        orientation[#orientation + 1] = 'N'
    else
        if (hits.N and (not hitE or not hitW)) then
            if (not hitW) then
                orientation[#orientation + 1] = 'W'
            end
            if (not hitE) then
                orientation[#orientation + 1] = 'E'
            end
        end
    end
    if (y > 0 and not hitS) then
        orientation = {}
        orientation[#orientation + 1] = 'S'
    else
        if (hitS and (not hitE or not hitW)) then
            if (not hitW) then
                orientation[#orientation + 1] = 'W'
            end
            if (not hitE) then
                orientation[#orientation + 1] = 'E'
            end
        end
    end
    if (x < 0 and not hitW) then
        orientation = {}
        orientation[#orientation + 1] = 'W'
    else
        if (hitW and (not hitN or not hitS)) then
            if (not hitN) then
                orientation[#orientation + 1] = 'N'
            end
            if (not hitS) then
                orientation[#orientation + 1] = 'S'
            end
        end
    end
    if (x > 0 and not hitE) then
        orientation = {}
        orientation[#orientation + 1] = 'E'
    else
        if (hitE and (not hitN or not hitS)) then
            if (not hitN) then
                orientation[#orientation + 1] = 'N'
            end
            if (not hitS) then
                orientation[#orientation + 1] = 'S'
            end
        end
    end

    -- if no move selected then select a random move
    if (#orientation <= 0) then
        orientation[#orientation + 1] = _COMPASS[random:uniformInt(1, #_COMPASS)]
    end
    return orientation[random:uniformInt(1, #orientation)]
end

function AvatarAI:computeAStarPath(grid, piece, target)
    self:clearPath()
    local start_position = grid:position(piece)
    local discovered = {}
    local visited = {}
    local parent = {}
    local gCost, fCost = {}, {}

    discovered[#discovered + 1] = start_position
    gCost[aiHelper:pString(start_position)] = 0
    fCost[aiHelper:pString(start_position)] = gCost[aiHelper:pString(start_position)] +
            aiHelper:L2_distance(start_position, target)

    while #discovered > 0 do
        local current = self:lowestCostNode(discovered, fCost)
        --[[
        check to see if current_node is the target node
        return path if goal is reached
        to unwind a path, take last visited node and keep getting their parents to get path
    ]]
        if aiHelper:pEquality(current, target) then
            -- unwind and return path
            self._path = self:unwindPath(parent, current)
            self._pathIndex = #self._path
            return self._path
        end
        --[[
            otherwise
            remove current node from discovered node
            discover walkable nodes around new current_node
            update cost of the walkable nodes if their new f_cost is lower
        ]]
        self:remove_node(discovered, current)
        table.insert(visited, current)
        local walkableNeighbour = aiHelper:walkable_nodes(grid, current, grid:layer(piece))
        for orientation, neighbour in pairs(walkableNeighbour) do
            if self:not_in(visited, neighbour) then
                local tempGCost = gCost[aiHelper:pString(current)] + aiHelper:L2_distance(current, neighbour)

                if self:not_in(discovered, neighbour) or tempGCost < gCost[aiHelper:pString(neighbour)] then
                    parent[aiHelper:pString(neighbour)] = current
                    gCost[aiHelper:pString(neighbour)] = tempGCost
                    fCost[aiHelper:pString(neighbour)] = tempGCost + aiHelper:L2_distance(neighbour, target)
                    if self:not_in(discovered, neighbour) then
                        neighbour['orientation'] = "" .. orientation
                        table.insert(discovered, neighbour)
                    end
                end
            end
        end
    end
    -- No path found
    print("NO PATH FOUND")
    return nil
end

-- A* UTILITIES
function AvatarAI:progressPath(grid, piece, target)
    print(self._pathIndex)
    if (self._pathIndex <= 0 and not aiHelper:pEquality(grid:position(piece), target)) then
        print("A* Called")
        self:computeAStarPath(grid, piece, target)
    end
    local move = self:getMove()
    self._pathIndex = self._pathIndex - 1
    return move
end

function AvatarAI:getMove()
    if (self._pathIndex <= 0) then
        return nil
    end
    return self._path[self._pathIndex]['orientation']
end

function AvatarAI:clearPath()
    self._path = {}
    self._pathIndex = #self._path
end

function AvatarAI:not_in (set, keyNode)
    for _, node in ipairs(set) do
        if aiHelper:pEquality(node, keyNode) then
            return false
        end
    end
    return true
end

function AvatarAI:remove_node (set, removeNode)
    for i, node in ipairs(set) do
        if aiHelper:pEquality(node, removeNode) then
            set[i] = set[#set]
            set[#set] = nil
            break
        end
    end
end

function AvatarAI:lowestCostNode(discovered, cost_table)
    local lowest, bestNode = cost_table[self:positionString(discovered[1])], nil
    for _, node in ipairs(discovered) do
        local cost = cost_table[self:positionString(node)]
        if cost <= lowest then
            lowest, bestNode = cost, node
        end
    end
    return bestNode
end

function AvatarAI:unwindPath(parentTable, goal)
    local path = {}
    table.insert(path, goal)
    local tempParent = parentTable[aiHelper:pString(goal)]
    while tempParent ~= nil do
        table.insert(path, tempParent)
        tempParent = parentTable[aiHelper:pString(tempParent)]
    end
    table.remove(path, #path)
    return path
end

-- UTILITIES
function AvatarAI:positionEquality(position, target)
    return aiHelper:pEquality(position, target)
end

function AvatarAI:positionString(position)
    return aiHelper:pString(position)
end

return { AvatarAI = AvatarAI }