return {
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            view = {
                width = 30,
                side = "left",
            },
            renderer = {
                indent_markers = {
                    enable = true,
                },
            },
        },
    },
}
