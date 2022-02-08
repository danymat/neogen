local i = require("neogen.types.template").item

return {
    { nil, "#######################################", { no_results = true, type = { "func" } } },
    { nil, "# $1", { no_results = true, type = { "func" } } },
    { nil, "#######################################", { no_results = true, type = { "func" } } },

    { nil, "#!/bin/bash$1", { no_results = true, type = { "file" } } },
    { nil, "#", { no_results = true, type = { "file" } } },
    { nil, "# $1", { no_results = true, type = { "file" } } },
    { nil, "", { no_results = true, type = { "file" } } },

    { nil, "#######################################" },
    { nil, "# $1" },
    { "variable_name", "#   %s", { before_first_item = { "# Globals:" } } },
    { i.Parameter, "#   $1", { before_first_item = { "# Arguments:" } } },
    { nil, "#######################################" },
}
