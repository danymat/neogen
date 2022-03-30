local i = require("neogen.types.template").item

return {
    {
        { i.Parameter, i.Type },
        "# %s : %s $1",
        { required = "typed_parameters", type = { "func" } },
    },
}
