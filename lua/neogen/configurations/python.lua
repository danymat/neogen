local ts_utils = require("nvim-treesitter.ts_utils")

return {
    -- Search for these nodes
    parent = { "function_definition", "class_definition" },

    -- Traverse down these nodes and extract the information as necessary
    data = {
        ["function_definition"] = {
            ["0"] = {
                extract = function (node)
                    local results = {
                        parameters = {},
                        return_statement = {}
                    }

                    local params = neogen.utilities.nodes:matching_child_nodes(node, "parameters")[1]

                    if #params == 0 then
                        results.parameters = nil
                    end

                    local found_nodes

                    -- Find regular parameters
                    local regular_params = neogen.utilities.extractors:extract_children_text("identifier")(params)
                    if #regular_params == 0 then
                        regular_params = nil
                    end

                    for _, _params in pairs(regular_params) do
                        table.insert(results.parameters, _params)
                    end

                    results.parameters = regular_params

                    -- Find regular optional parameters
                    found_nodes = neogen.utilities.nodes:matching_child_nodes(params, "default_parameter")
                    for _,_node in pairs(found_nodes) do
                        local _params = neogen.utilities.extractors:extract_children_text("identifier")(_node)[1]
                        table.insert(results.parameters, _params)
                    end

                    -- Find typed params
                    found_nodes = neogen.utilities.nodes:matching_child_nodes(params, "typed_parameter")
                    for _,_node in pairs(found_nodes) do
                        local _params = neogen.utilities.extractors:extract_children_text("identifier")(_node)[1]
                        table.insert(results.parameters, _params)
                    end

                    -- TODO Find optional typed params
                    found_nodes = neogen.utilities.nodes:matching_child_nodes(params, "typed_default_parameter")
                    for _,_node in pairs(found_nodes) do
                        local _params = neogen.utilities.extractors:extract_children_text("identifier")(_node)[1]
                        table.insert(results.parameters, _params)
                    end


                    local body = neogen.utilities.nodes:matching_child_nodes(node, "block")[1]
                    if body ~= nil then
                        local return_statement = neogen.utilities.nodes:matching_child_nodes(body, "return_statement")

                        if #return_statement == 0 then
                            return_statement = nil
                        end

                        results.return_statement = return_statement
                    end


                    return results
                end
            },
        },
        ["class_definition"] = {
            ["2"] = {
                match = "block",

                extract = function(node)
                    local results = {
                        attributes = {}
                    }

                    local init_function = neogen.utilities.nodes:matching_child_nodes(node, "function_definition")[1]

                    if init_function == nil then
                        return
                    end

                    local body = neogen.utilities.nodes:matching_child_nodes(init_function, "block")[1]

                    if body == nil then
                        return
                    end

                    local expressions = neogen.utilities.nodes:matching_child_nodes(body, "expression_statement")
                    for _,expression in pairs(expressions) do
                        local assignment = neogen.utilities.nodes:matching_child_nodes(expression, "assignment")[1]
                        if assignment ~= nil then
                            local left_side = assignment:field("left")[1]
                            local left_attribute = left_side:field("attribute")[1]
                            table.insert(results.attributes, ts_utils.get_node_text(left_attribute)[1])
                        end
                    end

                    return results
                end
            },
        },
    },

    -- Use default granulator and generator
    locator = nil,
    granulator = nil,
    generator = nil,

    template = {
        annotation_convention = "numpydoc", -- required: Which annotation convention to use (default_generator)
        append = { position = "after", child_name = "block" }, -- optional: where to append the text (default_generator)
        use_default_comment = false, -- If you want to prefix the template with the default comment for the language, e.g for python: # (default_generator)
        google_docstrings = {
            { nil, '"""' },
            { "parameters", "\t%s: ", { before_first_item = { "", "Args:" } } },
            { "attributes", "\t%s: ", { before_first_item = { "", "Attributes: " } } },
            { "return_statement", "", { before_first_item = { "", "Returns: " } } },
            { nil, "" },
            { nil, '"""' },
        },
        numpydoc = {
            { nil, '"""' },
            { "parameters", "%s: ", { before_first_item = { "", "Parameters", "----------"  } } },
            { "attributes", "%s: ", { before_first_item = { "", "Attributes", "----------"  } } },
            { "return_statement", "", { before_first_item = { "", "Returns", "-------"  } } },
            { nil, "" },
            { nil, '"""' }
        }
    },
}
