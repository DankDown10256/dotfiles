return {
    "dkdwn/termrun.nvim",
    main = "termrun",
    lazy = false,
    opts = {
        commands = {
            c = "make",
            python = "python3 %f",
            rust = "cargo run",
            ruby = "ruby %f",
        },
    },
}
