--[[ Copyright (C) 2019 The DMLab2D Authors.

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

local tile = require 'system.tile'
local class = require 'common.class'
local tensor = require 'system.tensor'
local read_settings = require 'common.read_settings'
local random = require 'system.random'
local images = require 'images'
local carModel = require 'car'
--local avatarAi = require 'AI.avatar_ai'
--local wayPointFollower = require 'AI.waypoint_follower'

local _COMPASS = {'N', 'E', 'S', 'W'}
local _PLAYER_NAMES = {
    'blue',
    'mint',
    'carrot',
    'pink',
    'maroon',
    'beige',
    'brown',
    'coral',
    'cyan',
    'gold',
    'green',
    'grey',
    'lavender',
    'lime',
    'magenta',
    'navy',
    'olive',
    'purple',
    'red',
    'teal',
}
local _PLAYER_ACTION_ORDER = {
    'move',
    'turn',
    'zap',
    'zap2',
}
local _PLAYER_ACTION_SPEC = {
    move = {default = 0, min = 0, max = #_COMPASS},
    turn = {default = 0, min = -1, max = 1},
    zap = {default = 0, min = 0, max = 1},
    zap2 = {default=0, min=0, max=1}
}

local Avatar = class.Class()

-- Class function returning default settings.
function Avatar.defaultSettings()
    return {
        minFramesBetweenZaps = 2,
        playerResetsAfterZap = false,
        rewardForZapping = -1,
        rewardForBeingZapped = -50,
        rewardForEatingLastAppleInRadius = 0,
        zap = {
            radius = 1,
            length = 4
        },
        view = {
            left = 5,
            right = 5,
            forward = 9,
            backward = 1,
            centered = false,
            otherPlayersLookSame = true,
            followPlayer = true,
            thisPlayerLooksBlue = true,
        },
    }
end

function Avatar:__init__(kwargs)
    self._settings = kwargs.settings
    self._index = kwargs.index
    self._isBot = kwargs.isBot
    self._activeState = 'player.' .. kwargs.index
    self._waitState = 'player.' .. kwargs.index .. '.wait'
    self._simSetting = kwargs.simSettings
    -- mission switching
    self._missionIndex = 1
    self._targets = {{1,1}, {23,23}, {13, 13}}
end

function Avatar:addConfigs(worldConfig)
    local id = self._index
    worldConfig.states[self._activeState] = {
        groups = {'players'},
        layer = 'pieces',
        sprite = 'Player.' .. id,
        contact = 'avatar',
    }
    worldConfig.states[self._waitState] = {
        groups = {'players', 'players.wait'},
    }
end

function Avatar:addSprites(tileSet)
    local id = self._index
    tileSet:addShape('Player.' .. id, images.playerShape(_PLAYER_NAMES[math.fmod(id,20)+1]))
end

function Avatar:addReward(grid, amount)
    local ps = grid:userState(self._piece)
    ps.reward = ps.reward + amount
end

function Avatar:getReward(grid)
    return grid:userState(self._piece).reward
end

function Avatar:discreteActionSpec(actSpec)
    self._actionSpecStartOffset = #actSpec
    local id = tostring(self._index)
    for a, actionName in ipairs(_PLAYER_ACTION_ORDER) do
        local action = _PLAYER_ACTION_SPEC[actionName]
        table.insert(actSpec, {
            name = id .. '.' .. actionName,
            min = action.min,
            max = action.max,
        })
    end
end


function Avatar:addPlayerCallbacks(callbacks)
    local id = self._index
    local playerSetting = self._settings
    local activeState = {}
    activeState.onUpdate = {}
    function activeState.onUpdate.move(grid, piece)
        local state = grid:userState(piece)
        local actions = state.actions
        if actions.turn ~= 0 then
            grid:turn(piece, actions.turn)
        end
        if actions.move ~= 0 then
            grid:moveRel(piece, _COMPASS[actions.move])
        end
        grid:hitBeam(piece, "direction", 1, 0)
    end

    function activeState.onUpdate.zap(grid, piece, framesOld)
        local state = grid:userState(piece)
        local actions = state.actions

        if playerSetting.minFramesBetweenZaps >= 0 then
            if actions.zap == 1 and framesOld >= state.canZapAfterFrames then
                state.canZapAfterFrames = framesOld + playerSetting.minFramesBetweenZaps
                grid:hitBeam(
                        piece, "zapHit", playerSetting.zap.length, playerSetting.zap.radius)
            end
            if actions.zap2 == 1 and framesOld >= state.canZapAfterFrames then
                state.canZapAfterFrames = framesOld + playerSetting.minFramesBetweenZaps
                grid:hitBeam(
                        piece, "zapHit2", playerSetting.zap.length, playerSetting.zap.radius)
            end
        end
    end
    activeState.onHit = {}
    local playerResetsAfterZap = self._settings.playerResetsAfterZap
    function activeState.onHit.zapHit(grid, player, zapper)
        local zapperState = grid:userState(zapper)
        local playerState = grid:userState(player)
        zapperState.reward = zapperState.reward + zapperState.rewardForZapping
        playerState.reward = playerState.reward + playerState.rewardForBeingZapped
        playerState.hitByVector(zapperState.index):add(1)
        if playerResetsAfterZap then
            grid:setState(player, self._waitState)
        end
        -- Beams do not pass through zapped players.
        return true
    end

    function activeState.onHit.zapHit2(grid, player, zapper)
        local zapperState = grid:userState(zapper)
        local playerState = grid:userState(player)
        zapperState.reward = zapperState.reward + zapperState.rewardForZapping
        playerState.reward = playerState.reward + playerState.rewardForBeingZapped
        playerState.hitByVector(zapperState.index):add(1)
        if playerResetsAfterZap then
            grid:setState(player, self._waitState)
        end
        -- Beams pass through zapped players.
        return false
    end
    function activeState.onHit.direction(grid, player, zapper)
        local zapperState = grid:userState(zapper)
        --local playerState = grid:userState(player)
        grid:hitBeam(
                zapper, "zapHit", playerSetting.zap.length, playerSetting.zap.radius)
    end

    local waitState = {}
    waitState.respawnUpdate = function(grid, player, frames)
        grid:teleportToGroup(player, 'spawn.any', self._activeState)
    end

    callbacks[self._activeState] = activeState
    callbacks[self._waitState] = waitState
end

function Avatar:discreteActions(grid, actions)
    local psActions = grid:userState(self._piece).actions
    for a, actionName in ipairs(_PLAYER_ACTION_ORDER) do
        psActions[actionName] = actions[a + self._actionSpecStartOffset]
    end
end

function Avatar:addObservations(tileSet, world, observations, avatarCount)
    local settings = self._settings
    local id = self._index
    local stringId = tostring(id)
    local playerViewConfig = {
        left = settings.view.left,
        right = settings.view.right,
        forward = settings.view.forward,
        backward = settings.view.backward,
        centered = settings.view.centered,
        set = tileSet,
        spriteMap = {}
    }

    if settings.view.otherPlayersLookSame then
        for otherId = 1, avatarCount do
            if id == otherId then
                playerViewConfig.spriteMap['Player.' .. stringId] = 'Player.1'
            else
                playerViewConfig.spriteMap['Player.' .. otherId] = 'Player.2'
            end
        end
    elseif settings.view.thisPlayerLooksBlue then
        for otherId = 1, avatarCount do
            if id == otherId then
                playerViewConfig.spriteMap['Player.' .. stringId] = 'Player.1'
            elseif otherId == 1 then
                playerViewConfig.spriteMap['Player.' .. otherId] = 'Player.' .. id
            end
        end
    end

    observations[#observations + 1] = {
        name = stringId .. '.REWARD',
        type = 'Doubles',
        shape = {},
        func = function(grid)
            return grid:userState(self._piece).reward
        end
    }

    observations[#observations + 1] = {
        name = stringId .. '.POSITION',
        type = 'Doubles',
        shape = {2},
        func = function(grid)
            return tensor.DoubleTensor(grid:position(self._piece))
        end
    }

    local playerLayerView = world:createView(playerViewConfig)
    local playerLayerViewSpec =
    playerLayerView:observationSpec(stringId .. '.LAYER')
    playerLayerViewSpec.func = function(grid)
        return playerLayerView:observation{
            grid = grid,
            piece = settings.view.followPlayer and self._piece or nil,
        }
    end
    observations[#observations + 1] = playerLayerViewSpec

    local playerView = tile.Scene{
        shape = playerLayerView:gridSize(),
        set = tileSet
    }

    local spec = {
        name = stringId .. '.RGB',
        type = 'tensor.ByteTensor',
        shape = playerView:shape(),
        func = function(grid)
            local layerObservation = playerLayerView:observation{
                grid = grid,
                piece = settings.view.followPlayer and self._piece or nil,
            }
            return playerView:render(layerObservation)
        end
    }
    observations[#observations + 1] = spec
end

function Avatar:start(grid, locator, hitByVector)
    local actions = {}
    for a, actionName in ipairs(_PLAYER_ACTION_ORDER) do
        local action = _PLAYER_ACTION_SPEC[actionName]
        actions[actionName] = action.default
    end
    local targetTransform = grid:transform(locator)
    targetTransform.orientation = _COMPASS[random:uniformInt(1, #_COMPASS)]
    local piece = grid:createPiece(self._activeState, targetTransform)
    local rewardForLastApple = self._settings.rewardForEatingLastAppleInRadius

    self._piece = piece
    self._carModel = carModel.Car{piece=piece, orientation=self._orientation, isBot=self._isBot}
    grid:setUserState(piece, {
        reward = 0,
        canZapAfterFrames = 0,
        actions = actions,
        carModel = self._carModel,
        index = self._index,
        hitByVector = hitByVector,
        rewardForZapping = self._settings.rewardForZapping,
        rewardForBeingZapped = self._settings.rewardForBeingZapped,
        rewardForEatingLastAppleInRadius = rewardForLastApple,
    })
    --self._carModel:setPiece(self._piece)
    self._orientation = 'N'
    self._waypoint = ''
    return piece
end


function Avatar:update(grid)
    grid:userState(self._piece).reward = 0
    self._carModel:act(grid)
    return "works"
end


return {Avatar = Avatar}
