local i = require("neogen.types.template").item

return {
    { nil,            '""" $1 """',  { no_results = true, type = { "func" } } },
    { nil,            '""" $1 """',  { no_results = true, type = { "class" } } },
    { nil,            '"""' },
    { "signature",    "    %s" },
    -- { nil, "" },
    { nil,            "" },
    { nil,            "$1" },
    { nil,            "" },
    { i.HasParameter, "# Arguments", { type = { "func" } } },
    { i.HasParameter, "# Fields",    { type = { "class" } } },
    {
        i.Parameter,
        "- `%s`: $1",
        { required = "parameters", type = { "class" } },
    },
    {
        { i.Parameter,                   i.Type },
        "- `%s::%s`: $1",
        { required = "typed_parameters", type = { "func" } },
    },
    {
        { i.Parameter,                   i.Type },
        "- `%s::%s`: $1",
        { required = "typed_parameters", type = { "class" } },
    },
    {
        i.Parameter,
        "- `%s`: $1",
        { required = "parameters", type = { "func" } },
    },

    { nil, '"""' },
}
