local function_extractor = function(node, type)
    if not vim.tbl_contains({ "local", "function" }, type) then
        error("Incorrect call for function_extractor")
    end

    local tree = {
        {
            retrieve = "first",
            node_type = "parameters",
            subtree = {
                { retrieve = "all", node_type = "identifier", extract = true },
                { retrieve = "all", node_type = "spread", extract = true },
            },
        },
        { retrieve = "first", node_type = "return_statement", extract = true },
    }

    if type == "local" then
        tree = {
            {
                retrieve = "first",
                recursive = true,
                node_type = "function_definition",
                subtree = tree,
            },
        }
    end

    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
    local res = neogen.utilities.extractors:extract_from_matched(nodes)

    return {
        parameters = res.identifier,
        vararg = res.spread,
        return_statement = res.return_statement,
    }
end

local extract_from_var = function(node)
    local tree = {
        {
            retrieve = "first",
            node_type = "assignment_statement",
            subtree = {
                {
                    retrieve = "first",
                    node_type = "variable_list",
                    subtree = {
                        { retrieve = "all", node_type = "identifier", extract = true },
                    },
                },
            },
        },
        {
            position = 2,
            extract = true,
        },
    }
    local nodes = neogen.utilities.nodes:matching_nodes_from(node, tree)
    return nodes
end

return {
    -- Search for these nodes
    parent = {
        func = { "function", "local_function", "local_variable_declaration", "field", "variable_declaration" },
        class = { "local_variable_declaration", "variable_declaration" },
        type = { "local_variable_declaration", "variable_declaration" },
        file = { "chunk" },
    },

    data = {
        func = {
            -- When the function is inside one of those
            ["local_variable_declaration|field|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        return function_extractor(node, "local")
                    end,
                },
            },
            -- When the function is in the root tree
            ["function|local_function"] = {
                ["0"] = {
                    extract = function(node)
                        return function_extractor(node, "function")
                    end,
                },
            },
        },
        class = {
            ["local_variable_declaration|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local nodes = extract_from_var(node)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes)
                        return {
                            class_name = res.identifier,
                        }
                    end,
                },
            },
        },
        type = {
            ["local_variable_declaration|variable_declaration"] = {
                ["0"] = {
                    extract = function(node)
                        local result = {}
                        result.type = {}

                        local nodes = extract_from_var(node)
                        local res = neogen.utilities.extractors:extract_from_matched(nodes, { type = true })

                        -- We asked the extract_from_var function to find the type node at right assignment.
                        -- We check if it found it, or else will put `any` in the type
                        if res["_"] then
                            vim.list_extend(result.type, res["_"])
                        else
                            if res.identifier or res.field_expression then
                                vim.list_extend(result.type, { "any" })
                            end
                        end
                        return result
                    end,
                },
            },
        },
        file = {
            ["chunk"] = {
                ["0"] = {
                    extract = function()
                        return {}
                    end,
                },
            },
        },
    },

    -- Custom lua locator that escapes from comments
    locator = require("neogen.locators.lua"),

    -- Use default granulator and generator
    granulator = nil,
    generator = nil,

    template = {
        -- Which annotation convention to use
        annotation_convention = "emmylua",
        emmylua = {
            { nil, "- $1", { type = { "class", "func" } } }, -- add this string only on requested types
            { nil, "- $1", { no_results = true, type = { "class", "func" } } }, -- Shows only when there's no results from the granulator
            { nil, "- @module $1", { no_results = true, type = { "file" } } },
            { nil, "- @author $1", { no_results = true, type = { "file" } } },
            { nil, "- @license $1", { no_results = true, type = { "file" } } },
            { nil, "- @license $1", { no_results = true, type = { "file" } } },
            { nil, "", { no_results = true, type = { "file" } } },

            { "parameters", "- @param %s $1|any" },
            { "vararg", "- @vararg $1|any" },
            { "return_statement", "- @return $1|any" },
            { "class_name", "- @class $1|any" },
            { "type", "- @type $1" },
        },
        ldoc = {
            { nil, "- $1", { no_results = true, type = { "func", "class" } } },
            { nil, "- $1", { type = { "func", "class" } } },

            { "parameters", " @tparam $1|any %s " },
            { "return_statement", " @treturn $1|any" },
        },
    },
}
