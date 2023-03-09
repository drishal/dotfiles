vim.opt.clipboard = "unnamedplus"
local M={}
M.ui = {
  theme="onedark",
  changed_themes = {
    onedark = {
      base_16 = {base00 = "#282c34"}
    },
  },
  hl_override = {
    IndentBlanklineContextStart={bg="NONE"},
    CursorLine = {bg= "#21242b"},
  },
}
return M
