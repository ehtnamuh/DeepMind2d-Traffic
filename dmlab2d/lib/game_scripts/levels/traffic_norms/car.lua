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
    self._timeGap = 3
    self._max_velocity = 3
    self._maxAcceleration = 1
    self._acceleration = 0
    self._velocity = 1
    self._rayCastLength = 6
end

function Car:setPiece(piece)
    self._piece = piece
end

function Car:act(grid)
    if (self._isBot) then
        self._orientation, self._waypoint = wayPointFollower:wayPointFollow(grid, self._piece, self._orientation, self._waypoint)
        if (self._orientation ~= 'X') then
            grid:setOrientation(self._piece, self._orientation)
            self:safeGapCalculation(grid, self._piece, self._orientation, self._rayCastLength)
            self:updateSpeed()
            for i = 1, (self._velocity) do
                grid:moveRel(self._piece, 'N')
            end
        end
        local lane_orientation = wayPointFollower:LaneChange(grid, self._piece, self._orientation, self._rayCastLength)
        if (lane_orientation ~= 'X') then
            grid:moveAbs(self._piece, lane_orientation)
        end
    else
        --self._orientation, self._waypoint = wayPointFollower:wayPointFollow(grid, self._piece, self._orientation, self._waypoint)
        --if (self._orientation ~= 'X') then
        --    grid:setOrientation(self._piece, self._orientation)
        --    self:safeGapCalculation(grid, self._piece, self._orientation, self._rayCastLength)
        --    self:updateSpeed()
        --    for i = 1, (self._velocity) do
        --        grid:moveRel(self._piece, 'N')
        --    end
        --end
        --local lane_orientation = wayPointFollower:LaneChange(grid, self._piece, self._orientation, 6)
        --if (lane_orientation ~= 'X') then
        --    grid:moveAbs(self._piece, lane_orientation)
        --end
    end
    -- Legacy Mission system code
    -- if (self._avatar_ai:positionEquality(grid:position(self._piece), self._targets[self._missionIndex])) then
    --    self._missionIndex = math.fmod(self._missionIndex + 1,#self._targets+1)
    --    if (self._missionIndex == 0) then
    --        self._missionIndex = 1
    --    end
    -- end
end

function Car:accelerate()
    if (self._velocity >= self._max_velocity) then
        self._acceleration = 0
        return
    end
    if self._acceleration >= self._maxAcceleration then
        return
    end
    self._acceleration = self._acceleration + 1
end

function Car:brake()
    if (self._velocity <= 0) then
        self._acceleration = 0
        return
    end
    if self._acceleration <= -1 then
        return
    end

    self._acceleration = self._acceleration - 1
end

function Car:updateSpeed()
    if self._velocity >= self._max_velocity then
        self._velocity = self._max_velocity
        return
    end
    if self._velocity <= 0 then
        self._velocity = 0
    end
    self._velocity = self._velocity + self._acceleration
end

-- Move this function to wayPointFollower
function Car:safeGapCalculation(grid, piece, orientation, rayCastLength)
    if (rayCastLength == nil) then
        rayCastLength = 4
    end

    local me_position = grid:position(piece)
    local direction = aiHelper:orientation_to_position({ 0, 0 }, orientation, rayCastLength)
    -- get offset from piece in front, ignore hit bool, piece object.
    local _, other_piece, offset = grid:rayCastDirection(grid:layer(piece), me_position, direction)
    local other_car_vel = 0
    -- Getting the velocity of the car hit by the rayCast
    if(other_piece ~= nil) then
        if(grid:userState(other_piece)) then
           other_car_vel = grid:userState(other_piece)["carModel"]["_velocity"]
        end
    end
    local displacement = aiHelper:L2_distance({ 0, 0 }, offset)
    local relative_vel = self._velocity - other_car_vel
    if (relative_vel <= 0) then
        if (displacement <= 0) then
            return
        else
            self:accelerate()
            return
        end
    end
    local crash_time = displacement / relative_vel
    local stop_time = self._velocity / self._maxAcceleration
    --print("stp time:"..stop_time.." vel"..self._velocity.." crash time: "..crash_time)
    local time_gap = math.abs(crash_time - stop_time)
    if (time_gap > self._timeGap) then
        --print("Safe: "..time_gap.." vel: "..self._velocity)
        self:accelerate()
        return true
    elseif (time_gap <= (self._timeGap - 0.5)) then
        self:brake()
        print("Brake!! time_gap: " .. time_gap .. " vel: " .. self._velocity)
        --print("stp time:"..stop_time.." vel"..self._velocity.." crash time: "..crash_time)
        --print("UnSafe "..time_gap.." vel: "..self._velocity)
        return false
    end
    print("Cruise!! time_gap: " .. time_gap .. " vel: " .. self._velocity)
end

function Car:getVelocity()
    return self._velocity
end

return { Car = Car }