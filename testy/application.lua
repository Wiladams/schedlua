-- Application.lua
local Kernel = require("kernel"){exportglobal = true};

local Predicate = require("predicate")(Kernel, true)
local Alarm = require("alarm")(Kernel, true)
local asyncio = require("asyncio"){Kernel = Kernel, exportglobal = true}





