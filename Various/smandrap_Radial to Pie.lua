local r = reaper

local DEFAULT_COLOR = 255
local DEFAULT_RADIUS = 150

local radial_path =
'/Users/Federico/Library/Application Support/REAPER/Scripts/ReaTeam Scripts/Various/Lokasenna_Radial Menu - user settings.txt'
local pie_path = '/Users/Federico/Library/Application Support/REAPER/Scripts/Sexan_Scripts/Pie3000/menu_file.txt'

local outfile = '/Users/Federico/Desktop/Reascript Env/smandrap repo/ReaScripts/Various/outfile.txt'
local f = io.open(radial_path, 'r')
if not f then return end
local buf = f:read('*all')
f:close()

local func, err = load(buf, 'schwa', 'bt')
if func == nil then return end
local radial_t = func()
if radial_t == nil then return end

local function StringToTable(str)
  local f, err = load("return " .. str)
  return f ~= nil and f() or nil
end

local function ReadFromFile(fn)
  local file = io.open(fn, "r")
  if not file then return end
  local content = file:read("a")
  if content == "" then return end
  return StringToTable(content)
end

local function serializeTable(val, name, skipnewlines, depth)
  skipnewlines = skipnewlines or false
  depth = depth or 0
  local tmp = string.rep(" ", depth)
  if name then
    if type(name) == "number" and math.floor(name) == name then
      name = "[" .. name .. "]"
    elseif not string.match(name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
      name = string.gsub(name, "'", "\\'")
      name = "['" .. name .. "']"
    end
    tmp = tmp .. name .. " = "
  end
  if type(val) == "table" then
    tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")
    for k, v in pairs(val) do
      if k ~= "selected" and k ~= "guid_list" and k ~= "img_obj" then
        tmp = tmp .. serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
      end
    end
    tmp = tmp .. string.rep(" ", depth) .. "}"
  elseif type(val) == "number" then
    tmp = tmp .. tostring(val)
  elseif type(val) == "string" then
    tmp = tmp .. string.format("%q", val)
  elseif type(val) == "boolean" then
    tmp = tmp .. (val and "true" or "false")
  else
    tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
  end
  return tmp
end

local function TableToString(table, new_line)
  local str = serializeTable(table, nil, new_line)
  return str
end

function SaveToFile(data, fn)
  local file
  file = io.open(fn, "w")
  if file then
      file:write(data)
      file:close()
  end
end

local pie_t = {
  name = 'Imported from Radial Menu',
  RADIUS = DEFAULT_RADIUS,
  col = DEFAULT_COLOR,
  menu = true,
  guid = r.genGuid('')
}



local function isRadialSubMenu(k, v)
  if k == 'lbl' and v:match('^menu') then return true end
  return false
end

local function GetCommandName(str)
  if tonumber(str:sub(1, 1)) then
    --r.ShowConsoleMsg(str..'\n')
  elseif str:match('^midi') then
    r.ShowConsoleMsg(str..'\n')
  end
end

local pie_menu = ReadFromFile(pie_path)


for i = 0, #radial_t do
  for j = 0, #radial_t[i] do
    local radial_slice = radial_t[i][j]
    local pie_slice = {
      col = DEFAULT_COLOR
    }
    for k, v in pairs(radial_slice) do
      if not isRadialSubMenu(k, v) then
        if k == 'lbl' then
          pie_slice.name = v
        end
        if k == 'act' then
          pie_slice.cmd = v
          pie_slice.cmd_name = GetCommandName(v)
        end
      end
    end

    table.insert(pie_t, pie_slice)
  end
end

SaveToFile(TableToString(pie_t, false), outfile)
