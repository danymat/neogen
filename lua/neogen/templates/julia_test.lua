local i = require("neogen.types.template").item

return {
    { nil, '""" $1 """', { no_results = true, type = { "func" } } },
    { nil, '"""$1' },
    {
        { i.Parameter, i.Type },
        "%s::%s - $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
         i.Parameter,
        "%s - $1",
        { required = "identifier", type = { "func" } },
    },

    { nil, '"""' },
}
