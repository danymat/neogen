local plugins = {
    ["https://github.com/nvim-treesitter/nvim-treesitter"] = os.getenv("NVIM_TREESITTER_DIRECTORY")
        or "/tmp/nvim_treesitter",
    ["https://github.com/nvim-lua/plenary.nvim"] = os.getenv("PLENARY_DIRECTORY") or "/tmp/plenary.nvim",
}

local tests_directory = vim.fn.fnamemodify(vim.fn.expand("<sfile>"), ":h")
local plugin_root = vim.fn.fnamemodify(tests_directory, ":h")
vim.opt.runtimepath:append(plugin_root)

for url, directory in pairs(plugins) do
    if vim.fn.isdirectory(directory) == 0 then
        vim.fn.system({ "git", "clone", url, directory })
    end

    vim.opt.runtimepath:append(directory)
end

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")

vim.cmd("runtime plugin/nvim-treesitter.lua")

require("neogen").setup({ snippet_engine = "nvim" })
