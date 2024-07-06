local M = {}

---@class SessionMangerOptions
---@field pre_save? fun()
---@field post_save? fun()
---@field pre_load? fun()
---@field post_load? fun()
local defaults = {
  dir = vim.fn.stdpath('state') .. '/sessions/', -- directory where session files are saved
  options = { 'buffers', 'curdir', 'tabpages', 'winsize', 'skiprtp' }, -- sessionoptions used for saving
  save_empty = false, -- don't save if there are no open file buffer
}

---@type SessionMangerOptions
M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', {}, defaults, opts or {})
  vim.fn.mkdir(M.options.dir, 'p')
end

return M
