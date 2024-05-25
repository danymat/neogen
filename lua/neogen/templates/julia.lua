local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '""" $1 """', { no_results = true, type = { "struct" } } },
    { nil, '"""' },
    -- { nil, 'Overview:' },
    -- { nil, "" },
    { nil, "\t$1" },
    {nil, ""},
    {nil, "$1"},
    -- {
    --   { "name", "param_list" },
    --   "\t%s(%s)",
    --   {required = "definition", type = { "func" }}
    -- },
    { nil, "" },
    { nil, "# Arguments", type = {"func"} },
    { nil, "" , type = {"func"}},
    {
        i.Parameter,
        "- `%s`: $1",
        { required = "parameters", type = { "struct" } },
    },
    {
        { i.Parameter, i.Type },
        "- `%s::%s`: $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
        { i.Parameter, i.Type },
        "- `%s::%s`: $1",
        { required = "typed_parameters", type = { "struct" } },
    },
    {
        i.Parameter,
        "`%s`: $1",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
