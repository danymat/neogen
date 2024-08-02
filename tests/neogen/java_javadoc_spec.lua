--- Test cases for emmylua
---
--- @module 'tests.neogen.lua_spec'

local specs = require('tests.utils.specs')

local function make_emmylua(source, type)
    return specs.make_docstring(source, 'java', { type = type, annotation_convention = { java = 'javadoc' } })
end

describe("java: javadoc", function()
    describe("class", function()
        it("works with an basic interface", function()
            local source = [[
        public interface Entity {
            @NonNull UUID getId();|cursor|
        }
        ]]

            local expected = [[
        /**
         * [TODO:description]
         *
         */
        public interface Entity {
            @NonNull UUID getId();
        }
    ]]

            local result = make_emmylua(source, "class")

            assert.equal(expected, result)
        end)
    end)
end)
