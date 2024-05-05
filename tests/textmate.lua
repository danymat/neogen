--- A file to make dealing with text in Lua a little easier.
---
--- @module 'tests.textmate'

local _CURSOR_MARKER = "|cursor|"

local M = {}

---@class Cursor
---    A fake position in-space where a user's cursor is meant to be.
---@field [1] number
---    A 1-or-more value indicating the buffer line value.
---@field [2] number
---    A 1-or-more value indicating the buffer column value.

--- Find all lines marked with `"|cursor|"` and return their row / column positions.
---
---@param source string Pseudo-Python source-code to call. It contains `"|cursor|"` which is the expected user position.
---@return Cursor[] # The row and column cursor position in `source`.
---@return string # The same source code but with `"|cursor|"` stripped out.
function M.extract_cursors(source)
  local index = 1
  local count = #source
  local cursors = {}
  local cursor_marker_offset = #_CURSOR_MARKER - 1
  local code = ""

  local current_row = 1
  local current_column = 1

  while index <= count do
    local character = source:sub(index, index)

    if character == "\n" then
      current_row = current_row + 1
      current_column = 1
    else
      current_column = current_column + 1
    end

    if character == "|" then
      if source:sub(index, index + cursor_marker_offset) == _CURSOR_MARKER then
        index = index + cursor_marker_offset
        table.insert(cursors, { current_row, current_column })
      else
        code = code .. character
      end
    else
      code = code .. character
    end

    index = index + 1
  end

  if index <= count then
    -- If this happens, is because the while loop called `break` early
    -- This is very likely so we add the last character(s) to the output
    local remainder = source:sub(index, #source)
    code = code .. remainder
  end

  return { cursors, code }
end

return M
