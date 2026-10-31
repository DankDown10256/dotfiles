return {
    dir = vim.fn.expand("~/Desktop/termrun.nvim"),
    name = "termrun.nvim",
    opts = {
        commands = {
            c = "make",
            python = "python3 %f",
            rust = "cargo run",
            ruby = "ruby %f",
            sh = ".%f"
        },
    },
}
