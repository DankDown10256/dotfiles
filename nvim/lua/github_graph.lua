
local M = {}

local username = "DankDown10256"
local weeks = 26

local colors = {
    "#30363d",
    "#0e4429",
    "#006d32",
    "#26a641",
    "#39d353",
}

for level, color in ipairs(colors) do
    vim.api.nvim_set_hl(0, "GitHubLevel" .. (level - 1), {
        fg = color,
    })
end

local function get_contributions()
    local url = "https://github-contributions-api.jogruber.de/v4/"
        .. username .. "?y=last"

    local result = vim.fn.system({
        "curl",
        "-fsSL",
        "--max-time", "3",
        url,
    })

    if vim.v.shell_error ~= 0 then
        return nil
    end

    local ok, data = pcall(vim.json.decode, result)

    if not ok or type(data) ~= "table"
        or type(data.contributions) ~= "table" then
        return nil
    end

    local contributions = {}

    for _, day in ipairs(data.contributions) do
        contributions[day.date] = tonumber(day.level) or 0
    end

    return contributions
end

function M.get()
    local contributions = get_contributions()

    if not contributions then
        return { " GitHub contributions unavailable" }, "Comment"
    end

    local lines = {}
    local highlights = {}

    local weekdays = {
        "Sun", "Mon", "Tue", "Wed",
        "Thu", "Fri", "Sat",
    }

    local today = os.date("*t")
    today.hour = 12
    today.min = 0
    today.sec = 0

    local now = os.time(today)
    local weekday = tonumber(os.date("%w", now))

    local start = now
        - ((weeks - 1) * 7 + weekday) * 86400

    -- Header
    table.insert(lines, " GitHub Contributions")
    table.insert(highlights, {
        { "Title", 0, -1 },
    })

    -- Month labels
    local month_labels = {}
    local previous_month = nil

    for w = 0, weeks - 1 do
        local timestamp = start + w * 7 * 86400
        local month = os.date("%b", timestamp)

        if month ~= previous_month then
            month_labels[w + 1] = month
            previous_month = month
        end
    end

    local month_line = string.rep(" ", 4 + weeks * 2)

    for w, month in pairs(month_labels) do
        local pos = 5 + (w - 1) * 2
        month_line = month_line:sub(1, pos - 1)
            .. month
            .. month_line:sub(pos + #month)
    end

    table.insert(lines, month_line)
    table.insert(highlights, {
        { "Comment", 0, -1 },
    })

    -- Contribution grid
    for d = 0, 6 do
        local line = weekdays[d + 1] .. " "
        local hl = {}

        for w = 0, weeks - 1 do
            local timestamp = start
                + (w * 7 + d) * 86400

            local date = os.date("%Y-%m-%d", timestamp)

            local level = 0

            if timestamp <= now then
                level = contributions[date] or 0
            end

            level = math.max(0, math.min(4, level))

            local col = #line

            line = line .. "■ "

            table.insert(hl, {
                "GitHubLevel" .. level,
                col,
                col + #"■",
            })
        end

        table.insert(lines, line)
        table.insert(highlights, hl)
    end

    -- Legend
    table.insert(lines, "")
    table.insert(highlights, {
        { "Normal", 0, 0 },
    })

    local legend = " Less "
    local legend_hl = {}

    for level = 0, 4 do
        local col = #legend
        legend = legend .. "■ "

        table.insert(legend_hl, {
            "GitHubLevel" .. level,
            col,
            col + #"■",
        })
    end

    legend = legend .. "More"

    table.insert(lines, legend)
    table.insert(highlights, legend_hl)

    return lines, highlights
end

return M

