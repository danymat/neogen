local ts_utils = require("nvim-treesitter.ts_utils")
local nodes_utils = require("neogen.utilities.nodes")
local extractors = require("neogen.utilities.extractors")
local locator = require("neogen.locators.default")
local template = require("neogen.template")
local i = require("neogen.types.template").item

local parent = {
  func = { "function_definition" },
  struct = {"struct_definition"}
}

return {
  -- Search for these nodes
  parent = parent,

  -- Traverse down these nodes and extract the information as necessary
  data = {
    struct = {

      ["struct_definition"] = {
        ["0"] = {
          extract = function(node)
            local results = {}

            local tree = {
              -- TODO: Figure this one out, for now what we have is sufficient, but we can make it more convenient
              -- goal is to get the function name and parameters in the docstring, e.g. at the top f(x,y,z), in the overview section
              {
                retrieve = "all",
                node_type = "type_parameter_list",
                subtree = {
                  {
                    retrieve = "all",
                    node_type = "identifier",
                    extract = true,
                  },
                },
              },
              {
                retrieve = "all",
                node_type = "typed_expression",
                extract = true,
              },
            }
            local nodes = nodes_utils:matching_nodes_from(node, tree)
            if nodes["typed_expression"] then
              results["typed_parameters"] = {}
              for _, n in pairs(nodes["typed_expression"]) do
                local type_subtree = {
                  { position = 1, extract = true, as = i.Parameter },
                  { position = 2, extract = true, as = i.Type },
                }
                local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
                typed_parameters = extractors:extract_from_matched(typed_parameters)
                table.insert(results["typed_parameters"], typed_parameters)
              end
            end
            local res = extractors:extract_from_matched(nodes)

            results[i.HasParameter] = (res.typed_parameter or res.identifier) and { true } or nil
            results["definition"] = {name = res.name, param_list = res.param_list}
            results[i.Type] = res.type
            results[i.Parameter] = res.identifier
            -- TODO: Remove this
            results[i.Return] = res.return_statement
            results[i.ReturnTypeHint] = res[i.ReturnTypeHint]
            results[i.HasReturn] = (res.return_statement or res.anonymous_return or res[i.ReturnTypeHint])
            and { true }
            or nil

            return results
          end,
        },
      },

    },
    func = {

      ["function_definition"] = {
        ["0"] = {
          extract = function(node)
            local results = {}

            local tree = {
              -- TODO: Figure this one out, for now what we have is sufficient, but we can make it more convenient
              -- goal is to get the function name and parameters in the docstring, e.g. at the top f(x,y,z), in the overview section
              {
                position = 1,
                node_type = "identifier",
                extract = true,
                as = "name",
              },
              {
                retrieve = "all",
                node_type = "parameter_list",
                extract = true,
                as = "param_list",
              },
              {
                retrieve = "all",
                node_type = "parameter_list",
                subtree = {
                  {
                    retrieve = "all",
                    node_type = "identifier",
                    extract = true,
                  },
                  {
                    retrieve = "all",
                    node_type = "typed_parameter",
                    extract = true,
                  },
                  {
                    retrieve = "all",
                    node_type = "optional_parameter",
                    subtree = {
                      { retrieve = "all", node_type = "typed_parameter", extract = true },
                    },
                  },

                  {
                    retrieve = "all",
                    node_type = "optional_parameter",
                    subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                  },
                  {
                    retrieve = "all",
                    node_type = "spread_parameter",
                    extract = true,
                    subtree = { { retrieve = "all", node_type = "identifier", extract = true } },
                    as = "identifier",
                  },
                  {
                    retrieve = "all",
                    node_type = "keyword_parameters",
                    subtree = {
                      {
                        retrieve = "all",
                        node_type = "identifier",
                        extract = true,
                      },
                      {
                        retrieve = "all",
                        node_type = "typed_parameter",
                        extract = true,
                      },
                      {
                        retrieve = "all",
                        node_type = "optional_parameter",
                        subtree = {
                          {
                            retrieve = "all",
                            node_type = "typed_parameter",
                            extract = true,
                          },
                        },
                      },

                      {
                        retrieve = "all",
                        node_type = "optional_parameter",
                        subtree = {
                          { retrieve = "all", node_type = "identifier", extract = true },
                        },
                      },
                      {
                        retrieve = "all",
                        node_type = "spread_parameter",
                        extract = true,
                        subtree = {
                          { retrieve = "all", node_type = "identifier", extract = true },
                        },
                        as = "identifier",
                      },
                    },
                  },
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
            }
            local nodes = nodes_utils:matching_nodes_from(node, tree)
            if nodes["typed_parameter"] then
              results["typed_parameters"] = {}
              for _, n in pairs(nodes["typed_parameter"]) do
                local type_subtree = {
                  { position = 1, extract = true, as = i.Parameter },
                  { position = 2, extract = true, as = i.Type },
                }
                local typed_parameters = nodes_utils:matching_nodes_from(n, type_subtree)
                typed_parameters = extractors:extract_from_matched(typed_parameters)
                table.insert(results["typed_parameters"], typed_parameters)
              end
            end
            local res = extractors:extract_from_matched(nodes)

            results[i.HasParameter] = (res.typed_parameter or res.identifier) and { true } or nil
            results["definition"] = {name = res.name, param_list = res.param_list}
            results[i.Type] = res.type
            results[i.Parameter] = res.identifier
            results[i.Return] = res.return_statement
            results[i.ReturnTypeHint] = res[i.ReturnTypeHint]
            results[i.HasReturn] = (res.return_statement or res.anonymous_return or res[i.ReturnTypeHint])
            and { true }
            or nil

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

  template = template:add_default_annotation("julia"),
}
