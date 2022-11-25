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

-- Critical problem, absolute path to text maps has to be loaded each time location of project changes
-- Have to find a way to fix this
local path = "/home/samin/Desktop/Projects/DeepMindLab/lab2d/dmlab2d/lib/game_scripts/levels/traffic_norms/text_maps/"

local temp_path = path.."playerSpawns.txt"
io.input(temp_path)
local default = io.read("*all")
io.close()

temp_path = path.."roadLogic.txt"
io.input(temp_path)
local logic = io.read("*all")
io.close()

temp_path = path.."roadTriggers.txt"
io.input(temp_path)
local trigger = io.read("*all")
io.close()

local maps = {}


maps.default = default

maps.logic = logic

maps.trigger = trigger

local _DEFAULT_STATE_MAP = {
    ['*'] = 'wall',
    ['P'] = 'spawn.any',
}

local layouts = {}
for name, map in pairs(maps) do
  layouts[name] = {
      layout = map,
      stateMap = _DEFAULT_STATE_MAP
  }
end

return layouts
