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
          length = 5
      },
      view = {
          left = 5,
          right = 5,
          forward = 9,
          backward = 1,
          centered = false,
          otherPlayersLookSame = false,
          followPlayer = true,
          thisPlayerLooksBlue = true,
      },
  }
end

function Avatar:__init__(kwargs)
  self._settings = kwargs.settings
  self._index = kwargs.index
  self._isBot = kwargs.isBot
  self._mission = 1
  self._activeState = 'player.' .. kwargs.index
  self._waitState = 'player.' .. kwargs.index .. '.wait'
  self._simSetting = kwargs.simSettings
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
  tileSet:addShape('Player.' .. id, images.playerShape(_PLAYER_NAMES[id]))
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
    --grid:hitBeam(piece, "zapHit2", 3, 0)
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
        print("Hello There")
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
  grid:setUserState(piece, {
      reward = 0,
      canZapAfterFrames = 0,
      actions = actions,
      index = self._index,
      hitByVector = hitByVector,
      rewardForZapping = self._settings.rewardForZapping,
      rewardForBeingZapped = self._settings.rewardForBeingZapped,
      rewardForEatingLastAppleInRadius = rewardForLastApple,
    })
  self._piece = piece
  return piece
end

function Avatar:update(grid)
    grid:userState(self._piece).reward = 0
    targets = {{x = 3, y = 3}, {x = 48, y = 20}}
    local switch_target = self:bot_move_simple(grid, targets[self._mission])
    --local switch_target = self:bot_move_L1(grid, targets[self._mission])
    self:switch_mission(switch_target)
end

function Avatar:switch_mission(switch_target)
    if (switch_target) then
        print("target switched")
        self._mission = math.fmod(self._mission + 1,#targets+1)
        if (self._mission == 0) then
            self._mission = 1
        end
        print(self._mission)
    end
end

function Avatar:bot_beam()
    -- ZAPPING ACTIONS
    actionName = 'zap'
    local action = _PLAYER_ACTION_SPEC[actionName]
    psActions[actionName] = random:uniformInt(action.min, action.max)
    actionName = 'zap2'
    action = _PLAYER_ACTION_SPEC[actionName]
    psActions[actionName] = random:uniformInt(action.min, action.max)
end

function Avatar:L1_distance(source_pos, target_pos)
    return math.abs(target_pos[1] - source_pos[1])+math.abs(target_pos[2] - source_pos[2])
end

function Avatar:L2_distance(source_pos, target_pos)
    return math.sqrt((target_pos[2] - source_pos[2])^2 + (target_pos[1] - source_pos[1])^2)
end

function Avatar:bot_move_L1(grid, target)
    if self._isBot then
        --DRIVING AI
        local ray_dist = 1

        -- targets 3,3 and 48,20
        local target_pos = grid:position(self._piece)
        target_pos[1] = target.x - target_pos[1]
        target_pos[2] = target.y - target_pos[2]
        local dist = {}
        local orientations = {}

        -- N
        local me_position =  grid:position(self._piece)
        me_position[2] = me_position[2] - ray_dist
        local hit, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        if (#dist <= 0 or (not hit and dist[1] >= self:L1_distance(me_position, target_pos))) then
            if(#dist > 0 and dist[1] > self:L1_distance(me_position, target_pos)) then
                orientations = {}
            end
            dist[1] = self:L1_distance(me_position, target_pos)
            orientations[#orientations +1] = 'N'
        end
        -- E
        me_position =  grid:position(self._piece)
        me_position[1] = me_position[1] + ray_dist
        hit, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        if (#dist <= 0 or (not hit and dist[1] >= self:L1_distance(me_position, target_pos))) then
            if(#dist > 0 and dist[1] > self:L1_distance(me_position, target_pos)) then
                orientations = {}
            end
            dist[1] = self:L1_distance(me_position, target_pos)
            orientations[#orientations +1] = 'E'
        end
        -- S
        me_position =  grid:position(self._piece)
        me_position[2] = me_position[2] + ray_dist
        hit, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        if (#dist <= 0 or (not hit and dist[1] >= self:L1_distance(me_position, target_pos))) then
            if(#dist > 0 and dist[1] > self:L1_distance(me_position, target_pos)) then
                orientations = {}
            end
            dist[1] = self:L1_distance(me_position, target_pos)
            orientations[#orientations +1] = 'S'
        end
        -- W
        me_position =  grid:position(self._piece)
        me_position[1] = me_position[1] - ray_dist
        hit, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        if (#dist <= 0 or (not hit and dist[1] >= self:L1_distance(me_position, target_pos))) then
            if(#dist > 0 and dist[1] > self:L1_distance(me_position, target_pos)) then
                orientations = {}
            end
            dist[1] = self:L1_distance(me_position, target_pos)
            orientations[#orientations +1] = 'W'
        end
        grid:setOrientation(self._piece, orientations[random:uniformInt(1, #orientations)])
        grid:moveRel(self._piece, 'N')
        -- check if goal reached
        me_position =  grid:position(self._piece)
        if (self:L1_distance(me_position, target_pos) <= 3 ) then
            return true
        end
        return false
    end
end

function Avatar:bot_move_simple(grid, target)
    if self._isBot then
        --DRIVING AI
        ray_dist = 1
        -- N
        me_position =  grid:position(self._piece)
        me_position[2] = me_position[2] - ray_dist
        hitN, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        -- E
        me_position =  grid:position(self._piece)
        me_position[1] = me_position[1] + ray_dist
        hitE, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        -- S
        me_position =  grid:position(self._piece)
        me_position[2] = me_position[2] + ray_dist
        hitS, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        -- W
        me_position =  grid:position(self._piece)
        me_position[1] = me_position[1] - ray_dist
        hitW, _,_ = grid:rayCast(grid:layer(self._piece), grid:position(self._piece),me_position)
        -- targets 3,3 and 48,20
        me_position = grid:position(self._piece)
        x = target.x - me_position[1]
        y = target.y - me_position[2]

        orientation = {}
        if(y < 0 and not hitN) then
            orientation = {}
            orientation[#orientation+1] = 'N'
        else if(hitN and (not hitE or not hitW))  then
            if (not hitW) then
                orientation[#orientation+1] = 'W'
            end
            if (not hitE) then
                orientation[#orientation+1] = 'E'
            end
        end
        end
        if(y > 0 and not hitS) then
            orientation = {}
            orientation[#orientation+1] = 'S'
        else if(hitS and (not hitE or not hitW))  then
            if (not hitW) then
                orientation[#orientation+1] = 'W'
            end
            if (not hitE) then
                orientation[#orientation+1] = 'E'
            end
        end
        end
        if(x < 0 and not hitW) then
            orientation = {}
            orientation[#orientation+1] = 'W'
        else if(hitW and (not hitN or not hitS))  then
            if (not hitN) then
                orientation[#orientation+1] = 'N'
            end
            if (not hitS) then
                orientation[#orientation+1] = 'S'
            end
        end
        end

        if(x > 0 and not hitE) then
            orientation = {}
            orientation[#orientation+1] = 'E'
        else if( hitE and (not hitN or not hitS))  then
            if (not hitN) then
                orientation[#orientation+1] = 'N'
            end
            if (not hitS) then
                orientation[#orientation+1] = 'S'
            end
        end
        end

        -- if no move selected then select a random move
        if(#orientation <= 0) then
            orientation[#orientation+1] = _COMPASS[random:uniformInt(1, #_COMPASS)]
        end
        grid:setOrientation(self._piece, orientation[random:uniformInt(1, #orientation)])
        grid:moveRel(self._piece, 'N')

        -- check if goal reached
        if (x == 0 and y == 0) then
            return true
        end
        return false
    end
end


function Avatar:bot_move_A_star(grid, target)
    local me_position = grid:position(self._piece)
    local discovered = {}
    local visited = {}
    local cost = {}
    -- traversal method
    -- up down left right
    -- discover up down left right
    --
end

function Avatar:valid_tile(grid,position)

end

return {Avatar = Avatar}
