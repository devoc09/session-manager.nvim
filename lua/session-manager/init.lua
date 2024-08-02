local Config = require('session-manager.config')

local M = {}
---@type string?
M.current = nil

local e = vim.fn.fnameescape

function M.get_current()
  local pattern = '/'
  if vim.fn.has('win32') == 1 then
    pattern = '[\\:]'
  end
  local name = vim.fn.getcwd():gsub(pattern, '%%')
  return Config.options.dir .. name .. '.vim'
end

function M.get_last()
  local sessions = M.list()
  table.sort(sessions, function(a, b)
    return vim.loop.fs_stat(a).mtime.sec > vim.loop.fs_stat(b).mtime.sec
  end)
  return sessions[1]
end

function M.setup(opts)
  Config.setup(opts)
  M.start()
end

local function filtered_buffers()
  return vim.tbl_filter(function(b)
    if vim.bo[b].buftype ~= '' then
      return false
    end
    if vim.bo[b].filetype == 'gitcommit' then
      return false
    end
    if vim.bo[b].filetype == 'gitrebase' then
      return false
    end
    return vim.api.nvim_buf_get_name(b) ~= ''
  end, vim.api.nvim_list_bufs())
end

--- @return boolean
local function is_no_args()
  return vim.fn.argc() == 0
end

function M.start()
  M.current = M.get_current()
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = vim.api.nvim_create_augroup('session-manager', { clear = true }),
    callback = function()
      if Config.options.pre_save then
        Config.options.pre_save()
      end

      if not Config.options.save_empty then
        local bufs = filtered_buffers()
        if #bufs == 0 then
          return
        end
      end

      M.save()

      if type(Config.options.post_save) == 'function' then
        Config.options.post_save()
      end
    end,
  })
  if Config.options.auto_load and is_no_args() then
    M.load()
  end
end

function M.stop()
  M.current = nil
  pcall(vim.api.nvim_del_augroup_by_name, 'session-manager')
end

function M.save()
  local tmp = vim.o.sessionoptions
  vim.o.sessionoptions = table.concat(Config.options.options, ',')
  vim.cmd('mks! ' .. e(M.current or M.get_current()))
  vim.o.sessionoptions = tmp
end

function M.load(opt)
  opt = opt or {}
  local session_file = opt.last and M.get_last() or M.get_current()
  if session_file and vim.fn.filereadable(session_file) ~= 0 then
    if vim.env.GIT_EXEC_PATH then
      return
    end

    if type(Config.options.pre_load) == 'function' then
      Config.options.pre_load()
    end

    vim.cmd('silent! source ' .. e(session_file))

    if type(Config.options.post_load) == 'function' then
      Config.options.post_load()
    end
  end
end

function M.list()
  return vim.fn.globa(Config.options.dir .. '*.vim', true, true)
end

return M
