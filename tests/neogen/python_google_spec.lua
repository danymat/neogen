--- Make sure Python docstrings generate as expected.
---
--- @module 'tests.neogen.python_spec'

local specs = require('tests.utils.specs')

local function make_google_docstrings(source)
    return specs.make_docstring(source, 'python', { annotation_convention = { python = 'google_docstrings' } })
end

describe("python: google_docstrings", function()
    describe("func", function()
        it("works with an empty function", function()
            local source = [[
        def foo():|cursor|
            pass
        ]]

            local expected = [[
        def foo():
            """[TODO:description]"""
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with typed arguments", function()
            local source = [[
        def foo(bar: list[str], fizz: int, buzz: dict[str, int]):|cursor|
            pass
        ]]

            local expected = [[
        def foo(bar: list[str], fizz: int, buzz: dict[str, int]):
            """[TODO:description]

            Args:
                bar: [TODO:description]
                fizz: [TODO:description]
                buzz: [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)
    end)

    describe("func - arguments", function()
        it("works with class methods", function()
            local source = [[
        class Foo:
            @classmethod
            def no_arguments(cls):|cursor|
                return 7

            @classmethod
            def one_argument(cls, items):|cursor|
                return 8

            @classmethod
            def two_arguments(cls, items, another):|cursor|
                return 9
        ]]

            local expected = [[
        class Foo:
            @classmethod
            def no_arguments(cls):
                """[TODO:description]

                Returns:
                    [TODO:return]
                """
                return 7

            @classmethod
            def one_argument(cls, items):
                """[TODO:description]

                Args:
                    items ([TODO:parameter]): [TODO:description]

                Returns:
                    [TODO:return]
                """
                return 8

            @classmethod
            def two_arguments(cls, items, another):
                """[TODO:description]

                Args:
                    items ([TODO:parameter]): [TODO:description]
                    another ([TODO:parameter]): [TODO:description]

                Returns:
                    [TODO:return]
                """
                return 9
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with methods + nested function + return", function()
            local source = [[
        def foo():|cursor|
            def bar():|cursor|
                return "blah"

            yield "asdfsfd"
        ]]

            local expected = [[
        def foo():
            """[TODO:description]

            Yields:
                [TODO:description]
            """
            def bar():
                """[TODO:description]

                Returns:
                    [TODO:return]
                """
                return "blah"

            yield "asdfsfd"
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with methods + nested functions", function()
            local source = [[
        # Reference: https://github.com/danymat/neogen/pull/151
        class Thing(object):
            def foo(self, bar, fizz, buzz):|cursor|
                def another(inner, function):|cursor|
                    def inner_most(more, stuff):|cursor|
                        pass
        ]]

            local expected = [[
        # Reference: https://github.com/danymat/neogen/pull/151
        class Thing(object):
            def foo(self, bar, fizz, buzz):
                """[TODO:description]

                Args:
                    bar ([TODO:parameter]): [TODO:description]
                    fizz ([TODO:parameter]): [TODO:description]
                    buzz ([TODO:parameter]): [TODO:description]
                """
                def another(inner, function):
                    """[TODO:description]

                    Args:
                        inner ([TODO:parameter]): [TODO:description]
                        function ([TODO:parameter]): [TODO:description]
                    """
                    def inner_most(more, stuff):
                        """[TODO:description]

                        Args:
                            more ([TODO:parameter]): [TODO:description]
                            stuff ([TODO:parameter]): [TODO:description]
                        """
                        pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with static methods", function()
            local source = [[
        class Foo:
            @staticmethod
            def no_arguments():|cursor|
                return 7

            @staticmethod
            def one_argument(items):|cursor|
                return 8

            @staticmethod
            def two_arguments(items, another):|cursor|
                return 9
        ]]

            local expected = [[
        class Foo:
            @staticmethod
            def no_arguments():
                """[TODO:description]

                Returns:
                    [TODO:return]
                """
                return 7

            @staticmethod
            def one_argument(items):
                """[TODO:description]

                Args:
                    items ([TODO:parameter]): [TODO:description]

                Returns:
                    [TODO:return]
                """
                return 8

            @staticmethod
            def two_arguments(items, another):
                """[TODO:description]

                Args:
                    items ([TODO:parameter]): [TODO:description]
                    another ([TODO:parameter]): [TODO:description]

                Returns:
                    [TODO:return]
                """
                return 9
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)
    end)

    describe("func - argument permutations", function()
        it("works with named typed arguments", function()
            local source = [[
        def foo(fizz: str=None, buzz: list[str]=None):|cursor|
            pass
        ]]

            local expected = [[
        def foo(fizz: str=None, buzz: list[str]=None):
            """[TODO:description]

            Args:
                fizz: [TODO:description]
                buzz: [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with named untyped arguments", function()
            local source = [[
        def foo(fizz=None, buzz=8):|cursor|
            pass
        ]]

            local expected = [[
        def foo(fizz=None, buzz=8):
            """[TODO:description]

            Args:
                fizz ([TODO:parameter]): [TODO:description]
                buzz ([TODO:parameter]): [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with positional typed arguments", function()
            local source = [[
        def foo(fizz: str, buzz: list[str]):|cursor|
            pass
        ]]

            local expected = [[
        def foo(fizz: str, buzz: list[str]):
            """[TODO:description]

            Args:
                fizz: [TODO:description]
                buzz: [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with positional untyped arguments", function()
            local source = [[
        def foo(fizz, buzz):|cursor|
            pass
        ]]

            local expected = [[
        def foo(fizz, buzz):
            """[TODO:description]

            Args:
                fizz ([TODO:parameter]): [TODO:description]
                buzz ([TODO:parameter]): [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with required named typed arguments", function()
            local source = [[
        def foo(fizz, *, buzz: int):|cursor|
            pass
        ]]

            local expected = [[
        def foo(fizz, *, buzz: int):
            """[TODO:description]

            Args:
                fizz ([TODO:parameter]): [TODO:description]
                buzz: [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with required named untyped arguments", function()
            local source = [[
        def foo(fizz, *, buzz):|cursor|
            pass
        ]]

            local expected = [[
        def foo(fizz, *, buzz):
            """[TODO:description]

            Args:
                fizz ([TODO:parameter]): [TODO:description]
                buzz ([TODO:parameter]): [TODO:description]
            """
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        -- TODO: These tests currently fail but should pass. Fix the bugs!
        -- it("works with *args typed arguments", function()
        --     local source = [[
        --     def foo(*args: list[str]):|cursor|
        --         pass
        --     ]]
        --
        --     local expected = [[
        --     def foo(*args: list[str]):
        --         """[TODO:description]
        --
        --         Args:
        --             *args: [TODO:description]
        --         """
        --         pass
        --     ]]
        --
        --     local result = _make_python_docstring(source)
        --
        --     assert.equal(expected, result)
        -- end)
        --
        -- it("works with *args untyped arguments", function()
        --     local source = [[
        --     def foo(*args):|cursor|
        --         pass
        --     ]]
        --
        --     local expected = [[
        --     def foo(*args):
        --         """[TODO:description]
        --
        --         Args:
        --             *args: [TODO:description]
        --         """
        --         pass
        --     ]]
        --
        --     local result = _make_python_docstring(source)
        --
        --     assert.equal(expected, result)
        -- end)

        -- TODO: These tests currently fail but should pass. Fix the bugs!
        -- it("works with *kwargs typed arguments", function()
        --     local source = [[
        --     def foo(**kwargs: dict[str, str]):|cursor|
        --         pass
        --     ]]
        --
        --     local expected = [[
        --     def foo(**kwargs: dict[str, str]):
        --         """[TODO:description]
        --
        --         Args:
        --             **kwargs: [TODO:description]
        --         """
        --         pass
        --     ]]
        --
        --     local result = _make_python_docstring(source)
        --
        --     assert.equal(expected, result)
        -- end)
        --
        -- it("works with *args untyped arguments", function()
        --     local source = [[
        --     def foo(**kwargs):|cursor|
        --         pass
        --     ]]
        --
        --     local expected = [[
        --     def foo(**kwargs):
        --         """[TODO:description]
        --
        --         Args:
        --             **kwargs: [TODO:description]
        --         """
        --         pass
        --     ]]
        --
        --     local result = _make_python_docstring(source)
        --
        --     assert.equal(expected, result)
        -- end)
    end)

    describe("func - raises", function()
        it("does not show when implicitly re-raising an exception", function()
            local source = [[
        def foo():|cursor|
            try:
                blah()
            except:
                print("Oh no!")

                raise
        ]]

            local expected = [[
        def foo():
            """[TODO:description]"""
            try:
                blah()
            except:
                print("Oh no!")

                raise
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("lists only one entry per-raised type", function()
            local source = [[
            def foo(bar):|cursor|
                if bar:
                    raise TypeError("THING")

                if GLOBAL:
                    raise ValueError("asdffsd")

                raise TypeError("BLAH")
            ]]

            local expected = [[
            def foo(bar):
                """[TODO:description]

                Args:
                    bar ([TODO:parameter]): [TODO:description]

                Raises:
                    TypeError: [TODO:throw]
                    ValueError: [TODO:throw]
                """
                if bar:
                    raise TypeError("THING")

                if GLOBAL:
                    raise ValueError("asdffsd")

                raise TypeError("BLAH")
            ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with modules, even if they are nested", function()
            local source = [[
        def foo():|cursor|
            raise some_package.submodule.BlahError("asdffsd")
        ]]

            local expected = [[
        def foo():
            """[TODO:description]

            Raises:
                some_package.submodule.BlahError: [TODO:throw]
            """
            raise some_package.submodule.BlahError("asdffsd")
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with 1 raise", function()
            local source = [[
        def foo():|cursor|
            raise ValueError("asdffsd")
        ]]

            local expected = [[
        def foo():
            """[TODO:description]

            Raises:
                ValueError: [TODO:throw]
            """
            raise ValueError("asdffsd")
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with 2+ raises", function()
            local source = [[
            def foo(bar):|cursor|
                if bar:
                    raise TypeError("THING")

                if GLOBAL:
                    raise TypeError("asdffsd")

                raise TypeError("BLAH")
            ]]

            local expected = [[
            def foo(bar):
                """[TODO:description]

                Args:
                    bar ([TODO:parameter]): [TODO:description]

                Raises:
                    TypeError: [TODO:throw]
                """
                if bar:
                    raise TypeError("THING")

                if GLOBAL:
                    raise TypeError("asdffsd")

                raise TypeError("BLAH")
            ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)
    end)

    describe("func - returns", function()
        it("does not show if there are only implicit returns", function()
            local source = [[
        def foo(bar):|cursor|
            if bar:
                return

            return  # Unneeded but good for the unittest
        ]]

            local expected = [[
        def foo(bar):
            """[TODO:description]

            Args:
                bar ([TODO:parameter]): [TODO:description]
            """
            if bar:
                return

            return  # Unneeded but good for the unittest
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        -- TODO: This test is broken. Needs fixing
        -- it("works with an inline comment", function()
        --     local source = [[
        --     def flags(self, index):|cursor|  # pylint: disable=unused-argument
        --         return (
        --             QtCore.Qt.ItemIsEnabled
        --             | QtCore.Qt.ItemIsSelectable
        --             | QtCore.Qt.ItemIsUserCheckable
        --         )
        --     ]]
        --
        --     local expected = [[
        --     def flags(self, index):  # pylint: disable=unused-argument
        --         """[TODO:description]
        --
        --         Args:
        --             self ([TODO:parameter]): [TODO:description]
        --             index ([TODO:parameter]): [TODO:description]
        --
        --         Returns:
        --             [TODO:return]
        --         """
        --         return (
        --             QtCore.Qt.ItemIsEnabled
        --             | QtCore.Qt.ItemIsSelectable
        --             | QtCore.Qt.ItemIsUserCheckable
        --         )
        --     ]]
        --
        --     local result = _make_python_docstring(source)
        --
        --     assert.equal(expected, result)
        -- end)

        it("works with no arguments", function()
            local source = [[
        def foo():|cursor|
            return 10
        ]]

            local expected = [[
        def foo():
            """[TODO:description]

            Returns:
                [TODO:return]
            """
            return 10
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with no return", function()
            local source = [[
        def foo():|cursor|
            pass
        ]]

            local expected = [[
        def foo():
            """[TODO:description]"""
            pass
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with various returns in one function", function()
            local source = [[
        def foo(items):|cursor|
            for item in items:
                if item == "blah":
                    return "asdf"

            return "something else"
        ]]

            local expected = [[
        def foo(items):
            """[TODO:description]

            Args:
                items ([TODO:parameter]): [TODO:description]

            Returns:
                [TODO:return]
            """
            for item in items:
                if item == "blah":
                    return "asdf"

            return "something else"
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)
    end)

    describe("func - yields", function()
        it("works even with no explicit yield value", function()
            local source = [[
        @contextlib.contextmanager
        def foo(items):|cursor|
            try:
                yield
            except:
                print("bad thing happened")
        ]]

            local expected = [[
        @contextlib.contextmanager
        def foo(items):
            """[TODO:description]

            Args:
                items ([TODO:parameter]): [TODO:description]

            Yields:
                [TODO:description]
            """
            try:
                yield
            except:
                print("bad thing happened")
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with type-hints as expected", function()
            local source = [[
        def foo() -> typing.Generator[str]:|cursor|
            yield "asdfsfd"
        ]]

            local expected = [[
        def foo() -> typing.Generator[str]:
            """[TODO:description]

            Yields:
                [TODO:description]
            """
            yield "asdfsfd"
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works when doing yield + return at once", function()
            local source = [[
        def items(value):|cursor|
            if value:
                return
                yield
        ]]

            local expected = [[
        def items(value):
            """[TODO:description]

            Args:
                value ([TODO:parameter]): [TODO:description]

            Yields:
                [TODO:description]
            """
            if value:
                return
                yield
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)

        it("works with 2+ yields in one function", function()
            local source = [[
        def foo(thing):|cursor|
            if thing:
                yield 10
                yield 20
                yield 30
            else:
                yield 0

            for _ in range(10):
                yield
        ]]

            local expected = [[
        def foo(thing):
            """[TODO:description]

            Args:
                thing ([TODO:parameter]): [TODO:description]

            Yields:
                [TODO:description]
            """
            if thing:
                yield 10
                yield 20
                yield 30
            else:
                yield 0

            for _ in range(10):
                yield
        ]]

            local result = make_google_docstrings(source)

            assert.equal(expected, result)
        end)
    end)
end)
