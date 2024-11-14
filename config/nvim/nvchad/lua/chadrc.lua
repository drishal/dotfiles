-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}
local bruh = {
  everforest = {Normal = {bg="#272E33"}},
}

M.base46 = {
	theme = "doomchad",

	hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},
}
M.base46.hl_override = bruh[M.base46.theme]

return M
