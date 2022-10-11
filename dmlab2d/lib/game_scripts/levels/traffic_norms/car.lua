---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by samin.
--- DateTime: 8/28/22 2:13 PM
---
---
local class = require 'common.class'
local random = require 'system.random'
local aiHelper = require 'AI.avatar_ai_helper'
local wayPointFollower = require 'AI.waypoint_follower'
local tables = require 'common.tables'

local Car = class.Class()

function Car:__init__(kwargs)
    --self._settings = kwargs.settings
    --self._index = kwargs.index
    self._isBot = kwargs.isBot
    self._orientation = kwargs.orientation
    self._piece = kwargs.piece
    self._waypoint = ''
    self._timeGap = 0.5
    self._max_speed = 3
    self._maxAcceleration = 1
    self._acceleration = 0
    self._velocity = 1
end

function Car:act(grid)
    if (self._isBot) then
        self._orientation, self._waypoint =
        wayPointFollower:wayPointFollow(grid, self._piece, self._orientation, self._waypoint)
        if(self._orientation ~= 'X') then
            grid:setOrientation(self._piece, self._orientation)
            for i = 1,(self._velocity) do
                grid:moveRel(self._piece, 'N')
            end
        end
    else
        local me_position = grid:position(self._piece)
        local temp = aiHelper:orientation_to_position(me_position, self._orientation)
        local hit, piece, me_offset = grid:rayCastDirection(grid:layer(self._piece), me_position, {0,1})
        print(tables.tostring(me_offset, " ", 10))
        print(tables.tostring(piece, " ", 10))
    end

    -- Mission system code
    -- if (self._avatar_ai:positionEquality(grid:position(self._piece), self._targets[self._missionIndex])) then
    --    self._missionIndex = math.fmod(self._missionIndex + 1,#self._targets+1)
    --    if (self._missionIndex == 0) then
    --        self._missionIndex = 1
    --    end
    -- end
end


function Car:accelerate()
    if self._acceleration >= self._maxAcceleration then
        return
    end
    self._acceleration = self._acceleration + 1
end

function Car:decelerate()
    if self._acceleration <= -1 then
        return
    end
    self._acceleration = self._acceleration - 1
end

function Car:updateSpeed()
    if self._velocity >= self._max_speed then
        return
    end
    self._velocity = self._velocity + self._acceleration
end

function Car:safeGapCalculation(myPosition, otherPosition, myVel, otherVel, myOtherDir)
    -- Also take velocity of both cars as arguments
    -- difference between the two velocities is added to the distance
    -- must also take direction of movement as input
    -- if two cars are moving in opposite directions then multiply one with -1

    local displacement = aiHelper:L2_distance(myPosition, otherPosition)
    local crash_time = displacement/self._velocity
    local stop_time = self._velocity/self._acceleration
    local time_gap = stop_time - crash_time
    if(time_gap > self._timeGap) then
        print("Safe")
        return true
    end
    print("UnSafe")
    return false
end

return {Car = Car }