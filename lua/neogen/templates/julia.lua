local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '""" $1 """', { no_results = true, type = { "type" } } },
    { nil, '"""' },
    { nil, 'Overview:' },
    { nil, '' },
    { nil, '\t$1' },
    {nil, ''},
    { nil, 'Where...' },
    {
         i.Parameter,
        "\t%s is $1",
        { required = "parameters", type = { "type" } },
    },
    {
        { i.Parameter, i.Type },
        "\t%s::%s is $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
        { i.Parameter, i.Type },
        "\t%s::%s is $1",
        { required = "typed_parameters", type = { "type" } },
    },
    {
         i.Parameter,
        "\t%s is $1",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
