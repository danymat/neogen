local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
assert(ok, "neogen requires nvim-treesitter to operate :(")

neogen = { }

-- TODO: Move code here
neogen.generate = function(searcher, generator) end

neogen.auto_generate = function(custom_template)
    vim.treesitter.get_parser(0):for_each_tree(function(tree, language_tree)
        local searcher = neogen.configuration.languages[language_tree:lang()]

        if searcher then
            searcher.locator = searcher.locator or neogen.default_locator
            searcher.granulator = searcher.granulator or neogen.default_granulator
            searcher.generator = searcher.generator or neogen.default_generator

            local located_parent_node = searcher.locator({
                root = tree:root(),
                current = ts_utils.get_node_at_cursor(0),
            }, searcher.parent)

            if not located_parent_node then
                return
            end

            local data = searcher.granulator(located_parent_node, searcher.data)

            if data and not vim.tbl_isempty(data) then
                local to_place, content = searcher.generator(
                    located_parent_node,
                    data,
                    custom_template or searcher.template
                )

                vim.fn.append(to_place, content)
            end
        end
    end)
end

function neogen.generate_command()
    vim.api.nvim_command('command! -range -bar Neogen lua require("neogen").auto_generate()')
end

neogen.setup = function(opts)
    neogen.configuration = vim.tbl_deep_extend("keep", opts or {}, {
        -- DEFAULT CONFIGURATION
        languages = {
            lua = require('neogen.configurations.lua'),
        },
    })

    neogen.generate_command()
end

require('neogen.utility')
require('neogen.locators.default')
require('neogen.granulators.default')
require('neogen.generators.default')

return neogen
