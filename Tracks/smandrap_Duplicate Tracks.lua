-- @description Duplicate Tracks
-- @author smandrap
-- @version 1.0.3
-- @changelog
--    + Alt+click checkbox sets/unsets all checkboxes
--    # Move Receives checkbox alongside Sends checkbox
--    # Add SWS dependency check
-- @donation https://paypal.me/smandrap
-- @about
--   Pro Tools style Duplicate Tracks window

local reaper = reaper
local script_name = "Duplicate Tracks"

if not reaper.ImGui_GetVersion() then
  local ok = reaper.MB('Install now?\n\n(REAPER restart is required after install)', 'ReaImGui Missing', 1)
  if ok == 1 then reaper.ReaPack_BrowsePackages("ReaImGui API") end
  return
end

if not reaper.CF_GetSWSVersion then
  local ok = reaper.MB('Install now?\n\n(REAPER restart is required after install)', 'SWS Extensions Missing', 1)
  if ok == 1 then reaper.ReaPack_BrowsePackages("SWS Extensions") end
  return
end

-- APP

reaper.set_action_options(3)

local _ = nil
local dupenum = 1

local dupeElements = {}

dupeElements.activeLane = true
dupeElements.otherLanes = true
dupeElements.envelopes = true
dupeElements.fx = true
dupeElements.instruments = true
dupeElements.sends = true
dupeElements.receives = true
dupeElements.groupAssign = true

local duplicated_tracks = {}

local insertLastSel = false

local function DeleteActiveLanes()
  local track = reaper.GetTrack(0, 0)
  if not reaper.ValidatePtr(track, "MediaTrack*") then return end

  local numlanes = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES")

  for i = 0, numlanes - 1 do
    local laneplays = reaper.GetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. i)

    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. i, laneplays == 0 and 2 or 0)
  end

  reaper.Main_OnCommand(42691, 0) --Track lanes: Delete lanes (including media items) that are not playing

  numlanes = reaper.GetMediaTrackInfo_Value(track, "I_NUMFIXEDLANES")
  for i = 0, numlanes - 1 do
    reaper.SetMediaTrackInfo_Value(track, "C_LANEPLAYS:" .. i, 0)
  end
end

-- Sexan/ArkaData function
local function DeleteAllEnvelopes(track)
  for i = reaper.CountTrackEnvelopes(track), 1, -1 do
    local env = reaper.GetTrackEnvelope(track, i - 1)
    reaper.SetCursorContext(2, env)
    reaper.Main_OnCommand(40332, 0) -- select all points
    reaper.Main_OnCommand(40333, 0) -- delete all points
    reaper.Main_OnCommand(40065, 0) -- remove env
  end
end

local function DoDuplicateStuff()
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(-1)
  for i = 1, dupenum do
    reaper.Main_OnCommand(40062, 0) --Dupe

    local sel_tracks = {}
    for j = 0, reaper.CountSelectedTracks(0) - 1 do
      sel_tracks[#sel_tracks + 1] = reaper.GetSelectedTrack(0, j)
    end

    -- TODO: ACTIVE LANES (bug in API)
    --[[ if not activeLane then
      DeleteActiveLanes()
    end ]]

    -- NON-ACTIVE LANES
    --Track lanes: Delete lanes (including media items) that are not playing
    if not dupeElements.otherLanes then reaper.Main_OnCommand(42691, 0) end

    -- ENVELOPES
    if not dupeElements.envelopes then
      reaper.Main_OnCommand(41148, 0) -- Show All Envelopes on track
      for j = 1, #sel_tracks do
        DeleteAllEnvelopes(sel_tracks[j])
      end
    end

    if not dupeElements.fx then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_CLRFXCHAIN3"), 0) end
    if not dupeElements.sends then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SENDS6"), 0) end
    if not dupeElements.receives then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_SENDS5"), 0) end
    if not dupeElements.groupAssign then reaper.Main_OnCommand(reaper.NamedCommandLookup("_S&M_REMOVE_TR_GRP"), 0) end

    for j = 1, #sel_tracks do
      duplicated_tracks[#duplicated_tracks + 1] = sel_tracks[j]
    end
  end

  -- Select all duplicated tracks
  for i = 1, #duplicated_tracks do
    reaper.SetTrackSelected(duplicated_tracks[i], true)
  end

  reaper.PreventUIRefresh(1)
  reaper.Undo_EndBlock("Duplicate Tracks " .. dupenum .. " times", 0)
end

-- GUI

local ctx = reaper.ImGui_CreateContext(script_name)
local visible, open
local window_flags = reaper.ImGui_WindowFlags_NoCollapse() |
    reaper.ImGui_WindowFlags_NoResize()   |
    reaper.ImGui_WindowFlags_AlwaysAutoResize()
local btn_w = 80
local first_frame = true
local font = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_Attach(ctx, font)

local function Checkbox(label, val)
  local _, rv = reaper.ImGui_Checkbox(ctx, label, val)

  if reaper.ImGui_IsKeyDown(ctx, reaper.ImGui_Key_LeftAlt()) and reaper.ImGui_IsItemEdited(ctx) then
    for k, v in pairs(dupeElements) do
      dupeElements[k] = rv
    end
  end

  return rv
end

local function DrawCheckboxes()
  --dupeElements.activeLane = Checkbox('Active Lane', dupeElements.activeLane)
  dupeElements.otherLanes = Checkbox('Non-Active Lanes', dupeElements.otherLanes)
  dupeElements.envelopes = Checkbox('Envelopes', dupeElements.envelopes)
  dupeElements.fx = Checkbox('FX', dupeElements.fx)
  --dupeElements.instruments = Checkbox('Instruments', dupeElements.instruments)
  dupeElements.sends = Checkbox('Sends', dupeElements.sends)
  reaper.ImGui_SameLine(ctx)
  dupeElements.receives = Checkbox('Receives', dupeElements.receives)
  dupeElements.groupAssign = Checkbox('Group Assignments', dupeElements.groupAssign)
end

local function DrawOkCancelButtons()
  reaper.ImGui_Dummy(ctx, 0, 10)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Dummy(ctx, 0, 2)

  reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetWindowWidth(ctx) - btn_w * 2 - 15)

  reaper.ImGui_PushStyleColor(ctx, reaper.ImGui_Col_Button(), 0x5D5D5DAA)
  if reaper.ImGui_Button(ctx, "Cancel", btn_w) then open = false end
  reaper.ImGui_PopStyleColor(ctx)
  reaper.ImGui_SameLine(ctx)

  reaper.ImGui_SetCursorPosX(ctx, reaper.ImGui_GetWindowWidth(ctx) - btn_w - 10)
  if reaper.ImGui_Button(ctx, "OK", btn_w) then
    DoDuplicateStuff()
    open = false
  end
end

local function DrawWindow()
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_FrameRounding(), 5)

  reaper.ImGui_AlignTextToFramePadding(ctx)
  reaper.ImGui_Text(ctx, "Number of duplicates:")

  reaper.ImGui_SameLine(ctx)
  reaper.ImGui_PushItemWidth(ctx, 100)
  if first_frame then reaper.ImGui_SetKeyboardFocusHere(ctx) end
  _, dupenum = reaper.ImGui_InputInt(ctx, '##dupenum', dupenum, 0)
  dupenum = dupenum < 1 and 1 or dupenum

  reaper.ImGui_Dummy(ctx, 0, 10)
  reaper.ImGui_Separator(ctx)
  reaper.ImGui_Dummy(ctx, 0, 10)

  reaper.ImGui_Text(ctx, "Data to duplicate:")
  reaper.ImGui_Dummy(ctx, 0, 2)

  reaper.ImGui_Indent(ctx)
  DrawCheckboxes()
  reaper.ImGui_Unindent(ctx)

  DrawOkCancelButtons()

  reaper.ImGui_PopStyleVar(ctx) -- Frame rounding
end

local function guiloop()
  reaper.ImGui_SetNextWindowSize(ctx, 240, 330, reaper.ImGui_Cond_FirstUseEver())
  reaper.ImGui_PushStyleVar(ctx, reaper.ImGui_StyleVar_WindowRounding(), 5)
  reaper.ImGui_PushFont(ctx, font)

  visible, open = reaper.ImGui_Begin(ctx, script_name, true, window_flags)
  reaper.ImGui_PopStyleVar(ctx)

  if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Escape()) then open = false end
  if reaper.ImGui_IsKeyPressed(ctx, reaper.ImGui_Key_Enter()) then
    DoDuplicateStuff()
    open = false
  end
  if visible then
    DrawWindow()
    reaper.ImGui_End(ctx)
  end
  reaper.ImGui_PopFont(ctx)
  first_frame = false
  if open then
    reaper.defer(guiloop)
  end
end

reaper.defer(guiloop)
