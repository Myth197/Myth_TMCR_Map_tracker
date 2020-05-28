--  Load configuration options up front
ScriptHost:LoadScript("scripts/settings.lua")

Tracker:AddItems("items/common.json")
Tracker:AddItems("items/dungeon_items.json")
Tracker:AddItems("items/elements.json")
Tracker:AddItems("items/fusions.json")
Tracker:AddItems("items/keys.json")
Tracker:AddItems("items/labels.json")
Tracker:AddItems("items/options.json")


if not (string.find(Tracker.ActiveVariantUID, "items_only")) then
    ScriptHost:LoadScript("scripts/logic_common.lua")
    Tracker:AddMaps("maps/maps.json")
end

Tracker:AddLayouts("layouts/tracker.json")

-- Select a broadcast view layout based on whether the current variant is keysanity or not
if not (string.find(Tracker.ActiveVariantUID, "keys")) then
    Tracker:AddLayouts("layouts/standard_broadcast.json")
    Tracker:AddLocations("locations/dungeons.json")
    Tracker:AddLocations("locations/overworld.json")
    Tracker:AddLocations("locations/fusions.json")
else
    Tracker:AddLayouts("layouts/keysanity_broadcast.json")
    Tracker:AddLocations("locations/keysanity_dungeons.json")
    Tracker:AddLocations("locations/keysanity_overworld.json")
end

if _VERSION == "Lua 5.3" then
  ScriptHost:LoadScript("scripts/autotracking.lua")
else
  print("Your tracker version does not support autotracking")
end
