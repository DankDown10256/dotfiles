local M = {}

local last_command = nil
local compile_buf = nil
local compile_job = nil

local function compile(command)
    if not command or command == "" then
        return
    end

    last_command = command

    if compile_job then
        vim.fn.jobstop(compile_job)
        compile_job = nil
    end

    if compile_buf and vim.api.nvim_buf_is_valid(compile_buf) then
        vim.api.nvim_buf_delete(compile_buf, { force = true })
    end

    vim.cmd("botright 12new")

    local buf = vim.api.nvim_get_current_buf()
    compile_buf = buf

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

            local output = vim.deepcopy(lines)

            if output[#output] == "" then
                table.remove(output)
            end

            if #output == 0 then
                return
            end

            vim.bo[buf].modifiable = true
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, output)
            vim.bo[buf].modifiable = false

            for _, win in ipairs(vim.fn.win_findbuf(buf)) do
                vim.api.nvim_win_set_cursor(win, {
                    vim.api.nvim_buf_line_count(buf),
                    0,
                })
            end
        end)
    end

    append({ "$ " .. command, "" })

    compile_job = vim.fn.jobstart(command, {
        cwd = vim.fn.getcwd(),
        stdout_buffered = false,
        stderr_buffered = false,

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

        on_exit = function(job, code)
            if compile_job == job then
                compile_job = nil
            end

            append({
                "",
                "Compilation finished with exit code " .. code,
            })
        end,
    })

    if compile_job <= 0 then
        append({ "Failed to start compilation" })
        compile_job = nil
    end
end

vim.api.nvim_create_user_command("Compile", function()
    local command = vim.fn.input({
        prompt = "Compile command: ",
        default = last_command or "make",
        completion = "shellcmd",
    })

    compile(command)
end, {})

vim.api.nvim_create_user_command("Recompile", function()
    if not last_command then
        vim.notify("No previous compilation", vim.log.levels.WARN)
        return
    end

    compile(last_command)
end, {})

vim.keymap.set("n", "<leader>cc", "<cmd>Compile<CR>", {
    desc = "Compile",
})

vim.keymap.set("n", "<leader>cr", "<cmd>Recompile<CR>", {
    desc = "Recompile",
})

return M
