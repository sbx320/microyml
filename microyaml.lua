-- microyaml.lua
--
-- Now with some more YAML features, still not 1.1 compliant

--[[
MIT License

Copyright (c) 2025 Sam or wellbutteredtoast

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

local microyaml = {}

-- utils
local function trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- strip a trailing comment: '#' only starts a comment when it is outside
-- quotes and at the start of the line or preceded by whitespace
local function strip_comment(s)
  local quote = nil
  local i = 1
  while i <= #s do
    local c = s:sub(i, i)
    if quote then
      if c == "\\" then
        i = i + 1 -- skip escaped char
      elseif c == quote then
        if quote == "'" and s:sub(i + 1, i + 1) == "'" then
          i = i + 1 -- '' is an escaped quote inside single quotes
        else
          quote = nil
        end
      end
    elseif (c == '"' or c == "'") and (i == 1 or s:sub(i - 1, i - 1):match("[%s:%-]")) then
      quote = c
    elseif c == "#" and (i == 1 or s:sub(i - 1, i - 1):match("%s")) then
      return s:sub(1, i - 1)
    end
    i = i + 1
  end
  return s
end

local function parse_value(v)
  v = trim(v)

  -- null
  if v == "~" or v == "null" then return nil end

  -- quoted strings
  if v:match('^".*"$') or v:match("^'.*'$") then
    local quote = v:sub(1,1)
    -- strip quotes
    v = v:sub(2, -2)
    if quote == '"' then
      -- handle escape sequences
      v = v:gsub('\\n', '\n')
      v = v:gsub('\\t', '\t')
      v = v:gsub('\\r', '\r')
      v = v:gsub('\\\\', '\\')
      v = v:gsub('\\"', '"')
    else
      v = v:gsub("\\'", "'")
    end
    return v
  end

  -- booleans
  if v == "true" then return true end
  if v == "false" then return false end

  -- numbers
  local num = tonumber(v)
  if num then return num end

  -- fallback: string
  return v
end

local function detect_indent(lines, start_idx, base_indent)
  for i = start_idx, #lines do
    local line = strip_comment(lines[i])
    if not line:match("^%s*$") then
      local ind = #line:match("^(%s*)")
      if ind > base_indent then
        return ind - base_indent
      end
    end
  end
  return 2 -- fallback indent
end

local function peek_next_nonempty(lines, start_idx)
  for i = start_idx, #lines do
    local line = strip_comment(lines[i])
    if not line:match("^%s*$") then
      return line, i
    end
  end
  return nil, #lines + 1
end

local function parse_yaml(lines, i, indent, anchors)
  local obj = {}
  local is_list = false
  indent = indent or 0
  i = i or 1
  anchors = anchors or {}

  while i <= #lines do
    local line = lines[i]
    local orig_line = line
    -- strip comments
    line = strip_comment(line)

    if line:match("^%s*$") then
      i = i + 1
      goto continue
    end

    local current_indent = #line:match("^(%s*)")
    
    -- Check for tabs
    if line:match("^\t") then
      error("Tab characters not allowed (line " .. i .. "): use spaces for indentation")
    end
    
    if current_indent < indent then
      return obj, i
    end
    
    if current_indent > indent then
      -- We've gone too deep without a parent key, error
      error("Invalid indentation at line " .. i .. ": unexpected indent")
    end

    line = trim(line)

    -- Check for list item
    if line:match("^%- ") then
      is_list = true
      local value = trim(line:sub(3))
      
      -- Check for inline map in list
      if value:match("^(.-):%s*(.*)$") then
        local key, val = value:match("^(.-):%s*(.*)$")
        local inline_obj = {}
        if val == "" then
          local next_line, next_idx = peek_next_nonempty(lines, i + 1)
          if next_line then
            local next_indent = #next_line:match("^(%s*)")
            if next_indent > current_indent then
              local step = detect_indent(lines, i + 1, current_indent)
              local sub, ni = parse_yaml(lines, i + 1, current_indent + step, anchors)
              inline_obj[key] = sub
              table.insert(obj, inline_obj)
              i = ni
              goto continue
            end
          end
        end
        inline_obj[key] = parse_value(val)
        table.insert(obj, inline_obj)
      elseif value == "" then
        -- List item with nested content
        local next_line, next_idx = peek_next_nonempty(lines, i + 1)
        if next_line then
          local next_indent = #next_line:match("^(%s*)")
          if next_indent > current_indent then
            local step = detect_indent(lines, i + 1, current_indent)
            local sub, ni = parse_yaml(lines, i + 1, current_indent + step, anchors)
            table.insert(obj, sub)
            i = ni
            goto continue
          end
        end
        table.insert(obj, nil)
      else
        table.insert(obj, parse_value(value))
      end
    else
      -- key: value
      local key, value = line:match("^(.-):%s*(.*)$")
      if not key then
        error("Invalid syntax at line " .. i .. ": expected 'key: value' or '- item', got: " .. line)
      end
      
      if is_list then
        error("Mixed list and map at line " .. i .. ": cannot have both '- items' and 'key: value' at same level")
      end
      
      if value == "" then
        -- Check if next line is indented (nested content)
        local next_line, next_idx = peek_next_nonempty(lines, i + 1)
        if next_line then
          local next_indent = #next_line:match("^(%s*)")
          if next_indent > current_indent then
            local step = detect_indent(lines, i + 1, current_indent)
            local sub, ni = parse_yaml(lines, i + 1, current_indent + step, anchors)
            obj[key] = sub
            i = ni
            goto continue
          end
        end
        -- Empty value, treat as nil
        obj[key] = nil
      else
        obj[key] = parse_value(value)
      end
    end

    i = i + 1
    ::continue::
  end

  return obj, i
end

--- Public API ---

function microyaml.parse_string(str)
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  local result = parse_yaml(lines, 1, 0)
  return result
end

function microyaml.parse_file(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local content = f:read("*a")
  f:close()
  return microyaml.parse_string(content)
end

return microyaml
