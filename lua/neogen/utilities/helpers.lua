local config = require("neogen.config")

local has_ts_utils, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
local get_node_text
if vim.treesitter.query and vim.treesitter.query.get_node_text then
  get_node_text = vim.treesitter.query.get_node_text
elseif has_ts_utils then
  get_node_text = function(node, buf)
    return ts_utils.get_node_text(node, buf)[1]
  end
end

return {
    notify = function(msg, log_level)
        vim.notify(msg, log_level, { title = "Neogen" })
    end,

    --- Generates a list of possible types in the current language
    ---@private
    match_commands = function()
        if vim.bo.filetype == "" then
            return {}
        end

        local language = config.get().languages[vim.bo.filetype]

        if not language or not language.parent then
            return {}
        end

        return vim.tbl_keys(language.parent)
    end,
    split = function(s, sep, plain)
        return vim.fn.has("nvim-0.6") == 1 and vim.split(s, sep, { plain = plain }) or vim.split(s, sep, plain)
    end,

    get_node_text = get_node_text,
}
