--- Test cases for emmylua
---
--- @module 'tests.neogen.lua_spec'

local specs = require('tests.utils.specs')

local function make_emmylua(source)
    return specs.make_docstring(source, 'lua', { annotation_convention = { lua = 'emmylua' } })
end

describe("lua: emmylua", function()
    describe("func", function()
        it("works with an empty function", function()
            local source = [[
    function foo()|cursor|end
    ]]

            local expected = [[
    --- [TODO:description]
    function foo()end
    ]]

            local result = make_emmylua(source)

            assert.equal(expected, result)
        end)
    end)
end)
