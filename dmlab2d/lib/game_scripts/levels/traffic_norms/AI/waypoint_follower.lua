---
--- Created by samin.
--- DateTime: 10/10/2022 06:59
---


local random = require 'system.random'
local aiHelper = require 'AI.avatar_ai_helper'
local tables = require 'common.tables'
local map_interpreter = require 'AI.map_interpreter'

local WPFollower = {}
WPFollower.__index = WPFollower

function WPFollower:filterMove(newOrientations, orientation, walkableNeighbour, last_waypoint)
    -- MOVE FILTRATION
    -- car already branched on a previous node and cannot branch consecutively
    --if (last_waypoint == 'B') then
    --    return { orientation }
    --end
    -- remove illegal nodes
    for key, newOrientation in pairs(newOrientations) do
        local isMoveValid = false
        for tempOrientation, neighbour in pairs(walkableNeighbour) do
            if (tempOrientation == newOrientation) then
                isMoveValid = true
            end
        end
        if (not isMoveValid) then
            tables.removeValue(newOrientations, newOrientation)
        end
    end
    -- remove 180 turn
    local oppositeOrientation = {
        ['E'] = 'W',
        ['W'] = 'E',
        ['N'] = 'S',
        ['S'] = 'N'
    }
    if (#newOrientations > 1) then
        tables.removeValue(newOrientations, oppositeOrientation[orientation])
    end
    return newOrientations
end

-- Waypoint Following logic
function WPFollower:wayPointFollow(grid, piece, orientation, last_waypoint)
    -- WAYPOINT INTERPRETATION
    local me_position = grid:position(piece)
    local waypoint = map_interpreter:ExtractWaypoint(me_position, 64)
    local newOrientations = map_interpreter:waypointInterpreter(waypoint, orientation)

    -- FILTER MOVE
    local walkableNeighbour = aiHelper:walkable_nodes(grid, me_position, grid:layer(piece))
    newOrientations = self:filterMove(newOrientations, orientation, walkableNeighbour, last_waypoint)

    -- Car cannot follow waypoint and must find another path
    if (#newOrientations <= 0) then
        newOrientations = { 'N', 'S', 'E', 'W' }
        newOrientations = self:filterMove(newOrientations, orientation, walkableNeighbour, last_waypoint)
    end

    -- Handles error when Car blocked from all sides
    -- Indicates that no action can be taken
    if (#newOrientations <= 0) then
        -- This never runs but is a failsafe
        return 'X','X'
    end

    -- SELECT RANDOM MOVE FROM REMAINING
    orientation = newOrientations[random:uniformInt(1, #newOrientations)]
    return orientation, waypoint
end

-- Lane Changing logic
function WPFollower:LaneChange(grid, piece, orientation, rayCastLength)
    if(rayCastLength == nil) then
        rayCastLength = 4
    end
    -- Length for which lane is checked
    local me_position = grid:position(piece)

    -- Check if car is in lane
    local trigger = map_interpreter:TriggerInterpreter(map_interpreter:ExtractTrigger(me_position, 64))
    if(trigger ~= "lane") then return 'X' end

    -- calculate direction of rayCast from orientation
    local direction = aiHelper:orientation_to_position({ 0, 0 }, orientation, rayCastLength)
    -- get offset from piece in front, ignore hit bool, piece object.
    local _, _, me_offset = grid:rayCastDirection(grid:layer(piece), me_position, direction)

    -- search walkableNeighbours for valid lanes to switch to
    local walkableNeighbour = aiHelper:walkable_nodes(grid, me_position, grid:layer(piece))
    local max_offset_dist = aiHelper:L2_distance({0,0}, me_offset)
    local selected_lane = 'X'

    for tempOrientation, position in pairs(walkableNeighbour) do
        local waypoint = map_interpreter:ExtractWaypoint(position, 64)
        local newOrientations = map_interpreter:waypointInterpreter(waypoint, orientation)
        if (#newOrientations > 2) then
            break
        end
        if (newOrientations[1] == orientation) then
            direction = aiHelper:orientation_to_position({ 0, 0 }, orientation, rayCastLength)
            local _, _, offset = grid:rayCastDirection(grid:layer(piece), position, direction)
            if (aiHelper:L2_distance({0,0}, offset) > max_offset_dist) then
                max_offset_dist = aiHelper:L2_distance({0,0}, offset)
                selected_lane = tempOrientation
            end
        end
    end
    return selected_lane
end

return WPFollower