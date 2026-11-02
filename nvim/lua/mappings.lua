local map = vim.keymap.set
-- Native LSP expansion must not turn ordinary Tab into snippet navigation.
for _, mode in ipairs({ "i", "s" }) do
  for _, key in ipairs({ "<Tab>", "<S-Tab>" }) do
    pcall(vim.keymap.del, mode, key)
  end
end
map("n", ";", ":", { desc = "Enter command mode" })
map("i", "jk", "<Esc>", { desc = "Leave insert mode" })
map("i", "<C-b>", "<Esc>^i", { desc = "Beginning of line" })
map("i", "<C-e>", "<End>", { desc = "End of line" })
for key, direction in pairs({ h = "Left", l = "Right", j = "Down", k = "Up" }) do
  map("i", "<C-" .. key .. ">", "<" .. direction .. ">", { desc = "Move " .. direction:lower() })
  map("n", "<C-" .. key .. ">", "<C-w>" .. key, { desc = "Window " .. direction:lower() })
end
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
map("n", "<C-s>", "<cmd>write<CR>", { desc = "Save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "Copy whole file" })
map("n", "<leader>n", "<cmd>set number!<CR>", { desc = "Toggle line numbers" })
map("n", "<leader>rn", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
map("n", "<leader>b", "<cmd>enew<CR>", { desc = "New buffer" })
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "Diagnostic location list" })
map("n", "<leader>/", "gcc", { desc = "Toggle comment", remap = true })
map("x", "<leader>/", "gc", { desc = "Toggle comments", remap = true })
