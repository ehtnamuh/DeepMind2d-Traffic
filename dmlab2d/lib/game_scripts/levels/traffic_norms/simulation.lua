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

local class = require 'common.class'
local tile = require 'system.tile'
local random = require 'system.random'
local images = require 'images'
local maps = require 'maps'

local Simulation = class.Class()

function Simulation.defaultSettings()
  return {
      mapName = 'default',
  }
end

function Simulation:__init__(kwargs)
  self._settings = kwargs.settings
end

function Simulation:addSprites(tileSet)
  tileSet:addColor('OutOfBounds', {0, 0, 0})
  tileSet:addColor('OutOfView', {80, 80, 80})
  tileSet:addShape('Wall', images.wall())
end

function Simulation:worldConfig()
  local settings = self._settings
  local config = {
      outOfBoundsSprite = 'OutOfBounds',
      outOfViewSprite = 'OutOfView',
      updateOrder = {'fruit'},
      renderOrder = {'logic', 'pieces'},
      customSprites = {},
      hits = {},
      states = {
          wall = {
              layer = 'pieces',
              sprite = 'Wall',
          },
          ['spawn.any'] = {groups = {'spawn.any'}},
      }
  }
  local waitNames = {}
  self._waitNames = waitNames

  if settings.showRespawnProbability then
    table.insert(config.renderOrder, 1, 'wait')
  end
  return config
end

function Simulation:textMap()
  local map = maps[self._settings.mapName]
  if not map then
    error('missing map: ' .. self._settings.mapName)
  end
  return map
end

function Simulation:addObservations(tileSet, world, observations)
  local worldLayerView = world:createView{layout = self:textMap().layout}

  local worldView = tile.Scene{shape = worldLayerView:gridSize(), set = tileSet}
  local spec = {
      name = 'WORLD.RGB',
      type = 'tensor.ByteTensor',
      shape = worldView:shape(),
      func = function(grid)
        return worldView:render(worldLayerView:observation{grid = grid})
      end
  }
  observations[#observations + 1] = spec
end

local function _getNumLiveNeighbors(grid, pos, radius)
  local num = 0
  for _ in pairs(grid:queryDiamond('logic', pos, radius)) do
    num = num + 1
  end
  return num
end

-- avatars require reward in user state.
function Simulation:stateCallbacks(avatars)
  local settings = self._settings
  local radius = settings.seedRadius
  local stateCallbacks = {}
  stateCallbacks.wall = {onHit = true}

  return stateCallbacks
end

function Simulation:start(grid)

end

function Simulation:update(grid) end

return {Simulation = Simulation}
