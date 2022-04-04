local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '""" $1 """', { no_results = true, type = { "struct" } } },
    { nil, '"""' },
    -- { nil, 'Overview:' },
    -- { nil, "" },
    { nil, "$1" },
    -- {
    --   { "name", "param_list" },
    --   "\t%s(%s)",
    --   {required = "definition", type = { "func" }}
    -- },
    { nil, "" },
    { nil, "Where..." },
    { nil, "" },
    {
        i.Parameter,
        "\t%s is $1",
        { required = "parameters", type = { "struct" } },
    },
    {
        { i.Parameter, i.Type },
        "\t%s::%s is $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
        { i.Parameter, i.Type },
        "\t%s::%s is $1",
        { required = "typed_parameters", type = { "struct" } },
    },
    {
        i.Parameter,
        "\t%s is $1",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
