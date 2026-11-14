local pide = require("pide")

assert(vim.fn.exists(":Pide") == 2, ":Pide was not registered")
assert(vim.fn.exists(":PideAsk") == 2, ":PideAsk was not registered")
assert(vim.fn.exists(":PideSendSelection") == 2, ":PideSendSelection was not registered")
assert(vim.fn.exists(":PideClose") == 2, ":PideClose was not registered")

pide.setup({
  agent = { command = { "sh" } },
  ui = { width = 30 },
})
pide.open()
assert(pide.is_running(), "The agent process did not start")

pide.toggle()
pide.toggle()
assert(pide.is_running(), "The agent process should survive toggling its window")

pide.close()
assert(not pide.is_running(), "The agent process did not stop")

print("pide.nvim smoke tests passed")
vim.cmd.qall()
