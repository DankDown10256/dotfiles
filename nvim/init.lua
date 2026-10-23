-- Options
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.g.mapleader = " "

vim.keymap.set("n", "<leader>w", "<cmd>write<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>quit<CR>")

vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    { import = "plugins" },
})
require("config.lsp")
require("config.keymaps")
vim.opt.laststatus = 3
vim.opt.statusline = "%!v:lua.require('config.statusline').render()"
vim.api.nvim_create_user_command("Cfskeleton", function()
    vim.cmd("0read ~/.config/nvim/skeletons/main.c")
end, {})
vim.api.nvim_create_user_command("Chskeleton", function()
    vim.cmd("0read ~/.config/nvim/skeletons/main.h")
end, {})

