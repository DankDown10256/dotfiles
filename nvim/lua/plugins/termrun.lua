return {
    dir = vim.fn.expand("~/Bureau/termrun.nvim"),
    name = "termrun.nvim",
    opts = {
        commands = {
            c = "make",
            python = "python3 %f",
            rust = "cargo run",
            ruby = "ruby %f",
        },
    },
}
