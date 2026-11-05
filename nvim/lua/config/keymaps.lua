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
vim.keymap.set("n", "<leader>bb", function()
  Snacks.picker.buffers()
end, { desc = "Find open buffers" })
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

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildoptions = "pum"
vim.opt.pumheight = 10

vim.keymap.set("n", "<leader>.", function()
    local path = vim.fn.input({
        prompt = "Find file: ",
        default = "~/",
        completion = "file",
    })

    if path == "" then
        return
    end

    path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")

    if vim.fn.isdirectory(path) == 1 then
        vim.api.nvim_set_current_dir(path)
    else
        vim.cmd.edit(vim.fn.fnameescape(path))
    end
end, { desc = "Find file" })

vim.keymap.set("n", "<leader>dd", "<cmd>Dashboard<CR>", {
    desc = "Go back to dashboard"
})
local M = {}
local last_command = nil

local function compile(command)
    if not command or command == "" then
        return
    end

    last_command = command

    vim.cmd("botright 12new")

    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = "compile"

    vim.api.nvim_buf_set_name(buf, "*compilation*")

    local function append(lines)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end

            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
            vim.bo[buf].modifiable = false
        end)
    end

    append({ "$ " .. command, "" })

    vim.fn.jobstart(command, {
        cwd = vim.fn.getcwd(),

        on_stdout = function(_, data)
            if data then
                append(data)
            end
        end,

        on_stderr = function(_, data)
            if data then
                append(data)
            end
        end,

        on_exit = function(_, code)
            append({
                "",
                "Process exited with code " .. code,
            })
        end,
    })
end
