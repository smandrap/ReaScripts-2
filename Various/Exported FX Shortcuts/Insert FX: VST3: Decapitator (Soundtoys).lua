  FX_NAME = "VST3: Decapitator (Soundtoys)"
  ALWAYS_INSTANTIATE = true
  SHOW = false
  FLOAT_WND = false

  for i = 0, reaper.CountSelectedTracks(0) - 1 do
    local t = reaper.GetSelectedTrack(0, 0)
    local fxidx = reaper.TrackFX_AddByName(t, FX_NAME, false, ALWAYS_INSTANTIATE and -1 or 1)
    if SHOW then reaper.TrackFX_Show(t, fxidx, FLOAT_WND and 3 or 1) end
  end
  