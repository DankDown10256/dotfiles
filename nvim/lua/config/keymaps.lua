vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", {
    desc = "Open/Close file explorer",
})
vim.keymap.set("i", "<C-@>", "<C-o> <C-x>", {
    desc = "emmet trigger",
})
vim.keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Move to right window" })
vim.keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<CR>", {
    desc = "Find files",
})
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", {
    desc = "Search text",
})

vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<CR>", {
    desc = "Find buffers",
})

vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", {
    desc = "Search help",
})
vim.api.nvim_create_user_command("Dashboard", function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].modified then
            vim.notify("Unsaved changes!", vim.log.levels.WARN)
            return
        end
    end

    vim.cmd("silent! %bdelete")
    vim.cmd.cd(vim.fn.expand("~"))
    vim.cmd("Alpha")
end, { desc = "Close workspace and open dashboard" })
vim.keymap.set("n", "<leader>.", function()
    require("nvim-tree.api").tree.open({
        path = vim.fn.expand("~"),
        current_window = false,
    })
end, { desc = "Browse directories from home" })
