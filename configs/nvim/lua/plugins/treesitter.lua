return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        lazy = false,
        build = ":TSUpdate",

        opts = {
            ensure_installed = {
                "lua",
                "vim",
                "vimdoc",
                "rust",
                "ruby",
                "c",
                "cpp",
                "html",
                "css",
                "javascript",
                "typescript",
                "tsx",
                "json",
                "bash",
            },

            highlight = {
                enable = true,
            },

            indent = {
                enable = true,
            },
        },
    },
}
