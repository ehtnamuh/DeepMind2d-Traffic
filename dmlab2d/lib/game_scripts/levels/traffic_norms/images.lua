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

local file_system = require 'system.file_system'
local image_helpers = require 'common.image_helpers'

local APPLE_TEXT = [[
.......1........
.......11.......
........1.......
....111.1.11....
...12**313322...
..12****333338..
..22*****33338..
..2******33338..
..2******33338..
..2******33888..
..2*****333888..
..28***3338888..
..228888889898..
...1898999998...
....188.888.....
................
]]

local APPLE_PALETTE = {
    ['1'] = {23, 168, 23, 255},
    ['2'] = {20, 167, 20, 255},
    ['3'] = {32, 190, 32, 255},
    ['*'] = {26, 203, 26, 255},
    ['8'] = {19, 213, 19, 255},
    ['9'] = {21, 209, 21, 255},
}


local WALL_PALETTE = {
    ['*'] = {255, 255, 255, 255},
    ['#'] = {100, 100, 100, 255},
    ['='] = {150, 150, 150, 255},
}

local WALL_TEXT = [[
####==##########
####==##########
####==##########
####==##########
================
================
##########==####
##########==####
##########==####
##########==####
================
================
####==##########
####==##########
####==##########
####==##########
]]


local PLAYER_PALETTE = {
    grey = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {68, 68, 68, 255},
        ['@'] = {119, 119, 119, 255},
        ['#'] = {255, 255, 255, 255},
    },

    brown = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {145, 106, 60, 255},
        ['@'] = {170, 110, 40, 255},
        ['#'] = {255, 255, 255, 255},
    },

    blue = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {1, 0, 188, 255},
        ['@'] = {69, 69, 255, 255},
        ['#'] = {255, 255, 255, 255},
    },

    pink = {
         ['-'] = {0, 0, 0, 255},
        ['*'] = {203, 132, 132, 255},
        ['@'] = {250, 190, 190, 255},
        ['#'] = {255, 255, 255, 255},
    },

    carrot = {
         ['-'] = {0, 0, 0, 255},
        ['*'] = {200, 129, 46, 255},
        ['@'] = {237, 145, 33, 255},
        ['#'] = {255, 255, 255, 255},
    },

    beige = {
         ['-'] = {0, 0, 0, 255},
        ['*'] = {213, 207, 146, 255},
        ['@'] = {255, 250, 200, 255},
        ['#'] = {255, 255, 255, 255},
    },

    lavender = {
         ['-'] = {0, 0, 0, 255},
        ['*'] = {168, 117, 201, 255},
        ['@'] = {230, 190, 255, 255},
        ['#'] = {255, 255, 255, 255},
    },

    red = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {195, 19, 19, 255},
        ['@'] = {255, 0, 0, 255},
        ['#'] = {255, 255, 255, 255},
    },

    cyan = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {55, 201, 203, 255},
        ['@'] = {70, 240, 240, 255},
        ['#'] = {255, 255, 255, 255},
    },

    magenta = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {179, 60, 172, 255},
        ['@'] = {240, 50, 230, 255},
        ['#'] = {255, 255, 255, 255},
    },

    gold = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {201, 178, 50, 255},
        ['@'] = {238, 201, 0, 255},
        ['#'] = {255, 255, 255, 255},
    },

    green = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {15, 188, 15, 255},
        ['@'] = {0, 255, 0, 255},
        ['#'] = {255, 255, 255, 255},
    },

    lime = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {170, 198, 57, 255},
        ['@'] = {210, 245, 60, 255},
        ['#'] = {255, 255, 255, 255},
    },

    mint = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {111, 210, 141, 255},
        ['@'] = {170, 255, 195, 255},
        ['#'] = {255, 255, 255, 255},
    },

    teal = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {31, 96, 97, 255},
        ['@'] = {0, 128, 128, 255},
        ['#'] = {255, 255, 255, 255},
    },

    olive = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {96, 97, 31, 255},
        ['@'] = {128, 128, 0, 255},
        ['#'] = {255, 255, 255, 255},
    },

    coral = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {205, 166, 132, 255},
        ['@'] = {255, 215, 180, 255},
        ['#'] = {255, 255, 255, 255},
    },

    navy = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {0, 0, 128, 255},
        ['@'] = {58, 58, 154, 255},
        ['#'] = {255, 255, 255, 255},
    },

    maroon = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {97, 27, 27, 255},
        ['@'] = {125, 1, 1, 255},
        ['#'] = {255, 255, 255, 255},
    },

    purple = {
        ['-'] = {0, 0, 0, 255},
        ['*'] = {89, 26, 107, 255},
        ['@'] = {145, 30, 180, 255},
        ['#'] = {255, 255, 255, 255},
    },

}

local  PLAYER_TEXT = [[
---****************---
---****************---
---****************---
---****************---
##******************##
##******------******##
##*****--------*****##
*******--------*******
===****************
==*****@@@@@@@******
==*****@@@@@@@******
===****************
===****************
##*****--------*****##
##******************##
##******************##
]]


--local PLAYER_TEXT = [[
--....@@@@@@@@....
--....@@@@@@@@....
--....@@@@@@@@....
--....@@@@@@@@....
--....********....
--....********....
--..@@**####**@@..
--..@@**####**@@..
--..************..
--..************..
--..************..
--..************..
--....**....**....
--....**....**....
--....**....**....
--....**....**....
--]]

return {
    apple = function()
      return {
          palette = APPLE_PALETTE,
          text = APPLE_TEXT,
          noRotate = true
      }
    end,
    wall = function()
      return {
          palette = WALL_PALETTE,
          text = WALL_TEXT,
      }
    end,
    playerShape = function(name)
      return {
          palette = PLAYER_PALETTE[name],
          text = PLAYER_TEXT,
      }
    end
}
