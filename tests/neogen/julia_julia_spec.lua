--- Test cases for julia
---
--- @module 'tests.neogen.julia_spec'

local specs = require('tests.utils.specs')

local function make_julia(source)
    return specs.make_docstring(source, 'julia', { annotation_convention = { julia = 'julia' } })
end

describe("julia: julia", function()
    describe("func", function()
        it("works with an empty function", function()
            local source = [[
    function foo()|cursor|end
    ]]

            local expected = [[
    """
        foo()

    

    """"
    "
    function foo()end
    ]]

            local result = make_emmylua(source)

            assert.equal(expected, result)
        end)
    end)
end)
