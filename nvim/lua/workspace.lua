
local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local project_dir = "Desktop"
local projects_dir = vim.fn.expand("~/".. project_dir .. "")

function M.open()
    local projects = {}

    local handle = vim.uv.fs_scandir(projects_dir)

    if not handle then
        vim.notify("Projects directory not found", vim.log.levels.ERROR)
        return
    end

    while true do
        local name, type = vim.uv.fs_scandir_next(handle)
        if not name then
            break
        end

        if type == "directory" then
            table.insert(projects, name)
        end
    end

    table.sort(projects)

    pickers.new({}, {
        prompt_title = "Open Workspace",
        finder = finders.new_table({
            results = projects,
        }),
        sorter = conf.generic_sorter({}),

        attach_mappings = function(bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(bufnr)

                if not selection then
                    return
                end

                local path = projects_dir .. "/" .. selection.value

                -- Set workspace root
                vim.api.nvim_set_current_dir(path)

                -- Open nvim-tree at workspace root
                local tree = require("nvim-tree.api")
                tree.tree.close()
                tree.tree.open({ path = path, focus = true })
            end)

            return true
        end,
    }):find()
end
function M.create()
    local projects_dir = vim.fn.expand("~/".. project_dir .."")

    vim.ui.input({ prompt = "Project name: " }, function(name)
        if not name or name == "" then
            return
        end

        if name == "." or name == ".." or name:find("[/\\]") then
            vim.notify("Invalid project name", vim.log.levels.ERROR)
            return
        end

        local path = projects_dir .. "/" .. name

        if vim.fn.isdirectory(path) == 1 then
            vim.notify("Project already exists", vim.log.levels.WARN)
            return
        end

        vim.fn.mkdir(path, "p")
        vim.cmd("cd " .. vim.fn.fnameescape(path))

        Snacks.explorer({ cwd = path })
        vim.notify("Created project: " .. name)
    end)
end
return M

