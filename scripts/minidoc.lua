local minidoc = require("mini.doc")

if _G.MiniDoc == nil then
    minidoc.setup()
end

minidoc.generate({ "lua/neogen/init.lua", "lua/neogen/snippet.lua", "lua/neogen/template.lua" }, nil, nil)
