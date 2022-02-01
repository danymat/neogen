local i = require("neogen.types.template").item

return {
    { nil, "/// <summary>", { no_results = true } },
    { nil, "/// $1", { no_results = true } },
    { nil, "/// </summary>", { no_results = true } },

    { nil, "/// <summary>", {} },
    { nil, "/// $1", {} },
    { i.Parameter, '/// <param name="%s">$1</param>', { type = { "func", "type" } } },
    { i.Return, "/// <returns>$1</returns>", { type = { "func", "type" } } },
    { nil, "/// </summary>", {} },
}
