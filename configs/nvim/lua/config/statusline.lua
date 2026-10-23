local M = {}

function M.git_branch()
    local branch = vim.fn.system("git branch --show-current 2>/dev/null")
    if vim.v.shell_error ~= 0 then
        return ""
    end

    branch = vim.trim(branch)

    if branch == "" then
        return ""
    end

    return "  " .. branch .. "  "
end

function M.render()
    return table.concat({
        " %t",
        " %m",
        "%{v:lua.require('config.statusline').git_branch()}",
        "%=",
        " %y",
        " %l:%c ",
    })
end

return M
