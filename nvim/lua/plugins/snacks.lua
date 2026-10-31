return {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,

    opts = {
        terminal = {
            enabled = true,
            interactive = true,
            win = {
                position = "bottom",
                height = 0.30,
                border = "top",
            },
        },
    },

    keys = {
        {
            "<leader>c",
            function()
                Snacks.terminal.toggle()
            end,
            mode = { "n", "t" },
            desc = "Toggle Terminal",
        },
    },
}
