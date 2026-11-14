local M = {}

local state = {
  buf = nil,
  win = nil,
  job = nil,
}

local function notify(message, level)
  vim.notify(message, level, { title = "pide.nvim" })
end

local function dimension(value, total, minimum)
  if value <= 1 then
    return math.max(minimum, math.floor(total * value))
  end
  return math.max(minimum, math.floor(value))
end

local function show_buffer(buf, ui)
  local commands = {
    right = "botright vsplit",
    left = "topleft vsplit",
    bottom = "botright split",
    top = "topleft split",
  }

  vim.cmd(commands[ui.position] or commands.right)
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, buf)

  if ui.position == "bottom" or ui.position == "top" then
    local height = dimension(ui.height, vim.o.lines, 5)
    vim.api.nvim_win_set_height(state.win, height)
    vim.wo[state.win].winfixheight = true
  else
    local width = dimension(ui.width, vim.o.columns, 20)
    vim.api.nvim_win_set_width(state.win, width)
    vim.wo[state.win].winfixwidth = true
  end
end

local function resolve_cwd(cwd)
  if type(cwd) == "function" then
    return cwd()
  end
  return cwd or vim.fn.getcwd()
end

function M.is_running()
  return state.job ~= nil and vim.fn.jobwait({ state.job }, 0)[1] == -1
end

function M.open(config)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_set_current_win(state.win)
    return true
  end

  local command = config.agent.command
  if type(command) == "string" then
    command = { command }
  end

  if type(command) ~= "table" or #command == 0 then
    notify("agent.command must be a command string or a non-empty list", vim.log.levels.ERROR)
    return false
  end

  if vim.fn.executable(command[1]) ~= 1 then
    notify(string.format("Agent executable not found: %s", command[1]), vim.log.levels.ERROR)
    return false
  end

  if state.buf and vim.api.nvim_buf_is_valid(state.buf) and M.is_running() then
    show_buffer(state.buf, config.ui)
    return true
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  show_buffer(state.buf, config.ui)

  local buf = state.buf
  state.job = vim.fn.termopen(command, {
    cwd = resolve_cwd(config.agent.cwd),
    on_exit = function()
      if state.buf == buf then
        state.job = nil
      end
    end,
  })

  if state.job <= 0 then
    notify("Failed to start the agent", vim.log.levels.ERROR)
    state.job = nil
    return false
  end

  vim.cmd.startinsert()
  return true
end

function M.toggle(config)
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)
    state.win = nil
    return
  end
  M.open(config)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, false)
  end
  if state.job then
    vim.fn.jobstop(state.job)
  end
  state.win = nil
  state.buf = nil
  state.job = nil
end

function M.send(config, text)
  if not M.open(config) then
    return false
  end

  if not M.is_running() then
    notify("The agent is not running", vim.log.levels.ERROR)
    return false
  end

  vim.fn.chansend(state.job, text .. "\r")
  return true
end

return M
