local ts_utils = require("nvim-treesitter.ts_utils")
local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")
local locator = require("neogen.locators.default")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local parent = {
    func = { "function_definition" },
    -- struct = { "struct_definition" },
}


return {
    -- Search for these nodes
    parent = parent,

    -- Traverse down these nodes and extract the information as necessary
    data = {
        func = {
            ["function_definition"] = {
                ["0"] = {
                    extract = function(node)
                        local results = {}

                        local tree = {
                            {
                                retrieve = "all",
                                node_type = "parameter_list",
                                subtree = {
                                    { retrieve = "all", node_type = "identifier", extract = true },
                                    {
                                        retrieve = "all",
                                        node_type = "typed_parameter",
                                        subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                    },
                                    -- {
                                    --     retrieve = "all",
                                    --     node_type = "typed_parameter",
                                    --     extract = true,
                                    -- },
                                    -- {
                                    --     retrieve = "all",
                                    --     node_type = "typed_default_parameter",
                                    --     as = "typed_parameter",
                                    --     extract = true,
                                    --     subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                                    -- },
                                    -- {
                                    --     retrieve = "first",
                                    --     node_type = "list_splat_pattern",
                                    --     extract = true,
                                    --     as = i.ArbitraryArgs,
                                    -- },
                                    -- {
                                    --     retrieve = "first",
                                    --     node_type = "dictionary_splat_pattern",
                                    --     extract = true,
                                    --     as = i.ArbitraryArgs,
                                    -- },
                                },
                            },
                            {
                                retrieve = "first",
                                node_type = "block",
                                subtree = {
                                    {
                                        retrieve = "all",
                                        node_type = "return_statement",
                                        recursive = true,
                                        extract = true,
                                    },
                                },
                            },
                            -- {
                            --     retrieve = "all",
                            --     node_type = "type",
                            --     as = i.ReturnTypeHint,
                            --     extract = true,
                            -- },
                        }
                        local nodes = nodes_utils:matching_nodes_from(node, tree)
                        if nodes["typed_parameter"] then
                            results["typed_parameters"] = {}
                            for _, n in pairs(nodes["typed_parameter"]) do
                                local type_subtree = {
                                    { retrieve = "all", node_type = "identifier", extract = true, as = i.Parameter },
                                    -- { retrieve = "last", node_type = "type", extract = true, as = i.Type },
                                }
                                local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
                                typed_parameters = extractors:extract_from_matched(typed_parameters)
                                table.insert(results["typed_parameters"], typed_parameters)
                            end
                        end
                        local res = extractors:extract_from_matched(nodes)

                        -- Return type hints takes precedence over all other types for generating template
                        -- if res[i.ReturnTypeHint] then
                        --     res["return_statement"] = nil
                        --     if res[i.ReturnTypeHint][1] == "None" then
                        --         res[i.ReturnTypeHint] = nil
                        --     end
                        -- end

                        -- Check if the function is inside a class
                        -- If so, remove reference to the first parameter (that can be `self`, `cls`, or a custom name)
                        -- if res.identifier and locator({ current = node }, parent.class) then
                        --     local remove_identifier = true
                        --     -- Check if function is a static method. If so, will not remove the first parameter
                        --     -- if node:parent():type() == "decorated_definition" then
                        --     --     local decorator = nodes_utils:matching_child_nodes(node:parent(), "decorator")
                        --     --     decorator = ts_utils.get_node_text(decorator[1])[1]
                        --     --     if decorator == "@staticmethod" then
                        --     --         remove_identifier = false
                        --     --     end
                        --     -- end
                        --     if remove_identifier then
                        --         table.remove(res.identifier, 1)
                        --         if vim.tbl_isempty(res.identifier) then
                        --             res.identifier = nil
                        --         end
                        --     end
                        -- end

                        results[i.HasParameter] = (--[[ res.typed_parameter  or ]]res.identifier) and { true } or nil
                        -- results[i.Type] = res.type
                        results[i.Parameter] = res.identifier
                        results[i.Return] = res.return_statement
                        -- results[i.ReturnTypeHint] = res[i.ReturnTypeHint]
                        results[i.HasReturn] = (res.return_statement or res.anonymous_return --[[ or res[i.ReturnTypeHint] ]])
                                and { true }
                            or nil
                        results[i.ArbitraryArgs] = res[i.ArbitraryArgs]
                        results[i.Kwargs] = res[i.Kwargs]
                        return results
                    end,
                },
            },
        },
    },

    -- Use default granulator and generator
    locator = nil,
    granulator = nil,
    generator = nil,

    template = nil
--         :config({
--             append = { position = "after", child_name = "comment", fallback = "block", disabled = { "file" } },
--             position = function(node, type)
--                 if type == "file" then
--                     -- Checks if the file starts with #!, that means it's a shebang line
--                     -- We will then write file annotations just after it
--                     for child in node:iter_children() do
--                         if child:type() == "comment" then
--                             local start_row = child:start()
--                             if start_row == 0 then
--                                 if vim.startswith(ts_utils.get_node_text(node, 0)[1], "#!") then
--                                     return 1, 0
--                                 end
--                             end
--                         end
--                     end
--                     return 0, 0
--                 end
--             end,
--         })
--         :add_default_annotation("google_docstrings")
--         :add_annotation("numpydoc")
--         :add_annotation("reST"),
-- }
