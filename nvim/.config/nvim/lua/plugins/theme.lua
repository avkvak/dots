-- Load theme configuration from omarchy theme directory
local theme_path = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
local theme_config = {}

if vim.fn.filereadable(theme_path) == 1 then
  local ok, config = pcall(dofile, theme_path)
  if ok and type(config) == "table" then
    theme_config = config
  end
end

-- Fallback to flexoki-light if theme file doesn't exist
if #theme_config == 0 then
  theme_config = {
    {
      "kepano/flexoki-neovim",
      priority = 1000,
    },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "flexoki-light",
      },
    },
  }
end

return theme_config
