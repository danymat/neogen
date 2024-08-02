--- Test cases for julia
---
--- @module 'tests.neogen.julia_spec'

local specs = require("tests.utils.specs")

local function make_julia(source)
    return specs.make_docstring(source, "julia", { annotation_convention = { julia = "julia" } })
end

describe("julia: julia", function()
    describe("func", function()
        it("works with an empty function", function()
            local source = [[
function foo() |cursor|end
        ]]

            local expected = [[
"""
    foo()

[TODO:description]

"""
function foo() end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with arguments", function()
            local source = [[
function foo(a, b)
|cursor|
end
        ]]

            local expected = [[
"""
    foo(a, b)

[TODO:description]

# Arguments
- `a`: [TODO:parameter]
- `b`: [TODO:parameter]
"""
function foo(a, b)

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with arguments in a new line", function()
            local source = [[
function foo(
    a, b
    )
|cursor|
end
        ]]

            local expected = [[
"""
    foo(a, b)

[TODO:description]

# Arguments
- `a`: [TODO:parameter]
- `b`: [TODO:parameter]
"""
function foo(
    a, b
    )

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with typed arguments", function()
            local source = [[
function foo(a::Int, b::Float64)
|cursor|
end
        ]]

            local expected = [[
"""
    foo(a::Int, b::Float64)

[TODO:description]

# Arguments
- `a::Int`: [TODO:description]
- `b::Float64`: [TODO:description]
"""
function foo(a::Int, b::Float64)

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with typed and untyped arguments", function()
            local source = [[
function foo(a::Int, b)
|cursor|
end
        ]]

            local expected = [[
"""
    foo(a::Int, b)

[TODO:description]

# Arguments
- `a::Int`: [TODO:description]
- `b`: [TODO:parameter]
"""
function foo(a::Int, b)

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with splat arguments", function()
            local source = [[
function foo(x..., b)
|cursor|
end
        ]]

            local expected = [[
"""
    foo(x..., b)

[TODO:description]

# Arguments
- `b`: [TODO:parameter]
- `x`: [TODO:parameter]
"""
function foo(x..., b)

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with optional arguments", function()
            local source = [[
function foo(a, b=1)
|cursor|
end
        ]]

            local expected = [[
"""
    foo(a, b=1)

[TODO:description]

# Arguments
- `a`: [TODO:parameter]
- `b`: [TODO:parameter]
"""
function foo(a, b=1)

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works when extinding a methods (e.g. from Base)", function()
            local source = [[
function Base.foo(a, b)
|cursor|
end
        ]]

            local expected = [[
"""
    Base.foo(a, b)

[TODO:description]

# Arguments
- `a`: [TODO:parameter]
- `b`: [TODO:parameter]
"""
function Base.foo(a, b)

end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)
    end)

    describe("class", function()
        it("works with an empty struct", function()
            local source = [[
struct Foo |cursor|end
        ]]

            local expected = [[
"""
    Foo

[TODO:description]

"""
struct Foo end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with a struct with typed fields", function()
            local source = [[
struct Foo
    a::Int|cursor|
    b::Float64
end
        ]]

            local expected = [[
"""
    Foo

[TODO:description]

# Fields
- `a::Int`: [TODO:description]
- `b::Float64`: [TODO:description]
"""
struct Foo
    a::Int
    b::Float64
end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)

        it("works with a parametric struct with typed fields", function()
            local source = [[
struct Foo{T}
    a::Vector{T}|cursor|
    b::Float64
end
        ]]

            local expected = [[
"""
    Foo{T}

[TODO:description]

# Fields
- `a::Vector{T}`: [TODO:description]
- `b::Float64`: [TODO:description]
"""
struct Foo{T}
    a::Vector{T}
    b::Float64
end
        ]]

            local result = make_julia(source)

            assert.equal(expected, result)
        end)
    end)
end)

-- vim: set shiftwidth=4:
