return {
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,

        opts = {
            compile = false,
            transparent = false,
            theme = "dragon",
        },

        config = function(_, opts)
            require("kanagawa").setup({
                opts,
                transparent = true,
            })
            vim.cmd.colorscheme("kanagawa-dragon")
        end,
    },
}
