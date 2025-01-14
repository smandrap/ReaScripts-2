-- @description Dynamic project limit
-- @author smandrap
-- @version 1.0
-- @about
--   Allows you to avoid zooming out of space by setting the project limit automagically.
--   Requires SWS. Does not take into account automation. Use at own risk.

local reaper = reaper

local minimum_len = 120
local extra_space = 30


local curpos = reaper.GetCursorPosition()

local proj_state_cnt = 0
local calls = 0
local pollrate = 33

local function isProjChange()
  local new_curpos = reaper.GetCursorPosition()
  if new_curpos ~= curpos then
    curpos = new_curpos
    return true
  end

  local new_state_cnt =  reaper.GetProjectStateChangeCount(0)
  if new_state_cnt ~= proj_state_cnt then
    proj_state_cnt = new_state_cnt
    return true
  end
  return false
end

local function main()
  if isProjChange() or calls > pollrate then
    local proj_len = reaper.GetProjectLength(-1)
    local play_pos = reaper.GetPlayPosition()
    
    local new_projlimit = (play_pos > proj_len and play_pos or proj_len) + extra_space
    if curpos > new_projlimit then new_projlimit = curpos + extra_space end
    
    if new_projlimit > minimum_len then
      reaper.SNM_SetDoubleConfigVar('projmaxlen', new_projlimit)
      reaper.UpdateTimeline()
    end
    
    calls = 0
  end
  
  calls = calls + 1
  reaper.defer(main)
end

main()
