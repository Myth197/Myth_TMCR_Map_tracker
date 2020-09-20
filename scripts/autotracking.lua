-- Configuration ----------------------
TMC_AUTOTRACKER_DEBUG = true
BOW_VALUE = 0
WildsFused = 0
CloudsFused = 0
---------------------------------------

print("")
print("Active Auto-Tracker Configuration")
print("")
print("Enable Item Tracking:       ", AUTOTRACKER_ENABLE_ITEM_TRACKING)
print("Enable Location Tracking:   ", AUTOTRACKER_ENABLE_LOCATION_TRACKING)
if TMC_AUTOTRACKER_DEBUG then
  print("Enable Debug Logging:       ", TMC_AUTOTRACKER_DEBUG)
end
print("")

function autotracker_started()
  print("Started Tracking")

  KEY_STOLEN = false

  DWS_KEY_COUNT = 0
  DWS_KEY_PREV_VALUE = 0
  COF_KEY_COUNT = 0
  COF_KEY_PREV_VALUE = 0
  FOW_KEY_COUNT = 0
  FOW_KEY_PREV_VALUE = 0
  TOD_KEY_COUNT = 0
  TOD_KEY_PREV_VALUE = 0
  POW_KEY_COUNT = 0
  POW_KEY_PREV_VALUE = 0
  DHC_KEY_COUNT = 0
  DHC_KEY_PREV_VALUE = 0
  DHCKS_KEY_COUNT = 0
  DHCKS_KEY_PREV_VALUE = 0
  RC_KEY_COUNT = 0
  RC_KEY_PREV_VALUE = 0
end

U8_READ_CACHE = 0
U8_READ_CACHE_ADDRESS = 0

function InvalidateReadCaches()
    U8_READ_CACHE_ADDRESS = 0
end

function ReadU8(segment, address)
    if U8_READ_CACHE_ADDRESS ~= address then
        U8_READ_CACHE = segment:ReadUInt8(address)
        U8_READ_CACHE_ADDRESS = address
    end
    return U8_READ_CACHE
end

function isInGame()
  return AutoTracker:ReadU8(0x2002b32) > 0x00
end

function testFlag(segment, address, flag)
  local value = ReadU8(segment, address)
  local flagTest = value & flag
  if flagTest ~= 0 then
    return true
  else
    return false
  end
end

function updateToggleItemFromByteAndFlag(segment, code, address, flag)
    local item = Tracker:FindObjectForCode(code)
    if item then
        local value = ReadU8(segment, address)
        if TMC_AUTOTRACKER_DEBUG then
            print(item.Name, code, flag)
        end

        local flagTest = value & flag

        if flagTest ~= 0 then
            item.Active = true
        else
            item.Active = false
        end
    end
end

function updateSectionChestCountFromByteAndFlag(segment, locationRef, address, flag)
    local location = Tracker:FindObjectForCode(locationRef)
    if location then
        --Don't undo what user has done
        if location.Owner.ModifiedByUser then
            return
        end

        local value = ReadU8(segment, address)

        if TMC_AUTOTRACKER_DEBUGG then
            print(locationRef, value)
        end

        if (value & flag) ~= 0 then
            location.AvailableChestCount = 0
        else
            location.AvailableChestCount = 1
        end
    elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING then
        print("Couldn't find location", locationRef)
    end
end

function decreaseChestCount(segment, locationRef, chestData)
  local location = Tracker:FindObjectForCode(locationRef)
  if location then
    if location.Owner.ModifiedByUser then
      return
    end

    local cleared = 0

    for i=1, #chestData, 1 do
      local address = chestData[i][1]
      local flag = chestData[i][2]
      local value = ReadU8(segment, address)

      local flagTest = value & flag

      if flagTest ~= 0 then
        cleared = cleared + 1
      end
    end

    location.AvailableChestCount = (#chestData - cleared)

  elseif TMC_AUTOTRACKER_DEBUG then
    print("Location not found", locationRef)
  end
end

function clearRupees(segment, locationRef, chestData)
  local location = Tracker:FindObjectForCode(locationRef)
  if location then
    if location.Owner.ModifiedByUser then
      return
    end

    local cleared = 0

    for i=1, #chestData, 1 do
      local address = chestData[i][1]
      local flag = chestData[i][2]
      local value = ReadU8(segment, address)

      local flagTest = value & flag

      if flagTest ~= 0 then
        cleared = 1
      end
    end
        if (cleared) ~= 0 then
            location.AvailableChestCount = 0
        else
            location.AvailableChestCount = #chestData
        end
  elseif TMC_AUTOTRACKER_DEBUG then
    print("Location not found", locationRef)
  end
end

function updateDogFood(segment, code, address, flag)
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    if TMC_AUTOTRACKER_DEBUG then
      print(item.Name, code, flag)
    end

    local flagTest = value or flag

    if testFlag(segment, address, 0x10) or testFlag(segment, address, 0x20) then
      item.Active = true
    else
      item.Active = false
    end
  end
end

function updateLLRKey(segment, code, address, flag)
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    if TMC_AUTOTRACKER_DEBUG then
      print(item.Name, code, flag)
    end

    local flagTest = value or flag

    if flagTest >= 0x40 then
      item.Active = true
    else
      item.Active = false
    end
  end
end

function updateMush(segment, code, address, flag)
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    if TMC_AUTOTRACKER_DEBUG then
      print(item.Name, code, flag)
    end

    if testFlag(segment, address, 0x01) or testFlag(segment, address, 0x02) then
      item.Active = true
    else
      item.Active = false
    end
  end
end

function graveKey(segment)
  if not isInGame() then
    return false
  end
  InvalidateReadCaches()

  if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    graveKeyStolen(segment, "gravekey", 0x2002ac0, 0x01)
  end
end

function graveKeyStolen(segment, code, address, flag)
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    if TMC_AUTOTRACKER_DEBUG then
      print(item.Name, code, flag)
    end

    local flagTest = value or flag

    if testFlag(segment, address, 0x01) then
      KEY_STOLEN = true
    end
  end
end

function updateGraveKey(segment, code, address, flag)
  local item = Tracker:FindObjectForCode(code)
  if item then
    local value = ReadU8(segment, address)
    if TMC_AUTOTRACKER_DEBUG then
      print(item.Name, code, flag)
    end

    local flagTest = value or flag

    if testFlag(segment, address, 0x01) and KEY_STOLEN == true or
       testFlag(segment, address, 0x02) and KEY_STOLEN == true then
      item.Active = true
    end
  end
end

function updateBooks(segment, code, address)
  local item = Tracker:FindObjectForCode(code)
  local booksObtained = 0
  local booksUsed = 0

  local bookFlags = {0x04, 0x10, 0x40}
  local usedBooks = {0x08, 0x20, 0x80}

  for j=1,3,1 do
    if testFlag(segment, address, bookFlags[j]) == true then
      booksObtained = booksObtained + 1
    end
    if testFlag(segment, address, usedBooks[j]) == true then
      booksUsed = booksUsed + 1
    end
  end

  if item then
    item.CurrentStage = booksObtained + booksUsed
  end
end

function updateSwords(segment)
  local item = Tracker:FindObjectForCode("sword")
  if ReadU8(segment, 0x2002b33) == 0x01 or ReadU8(segment, 0x2002b33) == 0x41 or ReadU8(segment, 0x2002b33) == 0x81 then
    item.CurrentStage = 4
  elseif ReadU8(segment, 0x2002b33) == 0x11 or ReadU8(segment, 0x2002b33) == 0x51 or ReadU8(segment, 0x2002b33) == 0x91 then
    item.CurrentStage = 5
  elseif ReadU8(segment, 0x2002b32) == 0x05 then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b32) == 0x15 then
    item.CurrentStage = 2
  elseif ReadU8 (segment, 0x2002b32) == 0x55 then
    item.CurrentStage = 3
  else
    item.CurrentStage = 0
  end
end

function updateBow(segment)
  local item = Tracker:FindObjectForCode("bow")
  if testFlag(segment, 0x2002b34, 0x04) then
    item.CurrentStage = 1
    BOW_VALUE = 1
  end
  if testFlag(segment, 0x2002b34, 0x10) then
    item.CurrentStage = 2
  end
  if not testFlag(segment, 0x2002b34, 0x04) and not testFlag(segment, 0x2002b34, 0x10) then
    item.CurrentStage = 0
    BOW_VALUE = 0
  end
end

function updateMitts(segment)
  local item = Tracker:FindObjectForCode("mitts")
  if testFlag(segment, 0x2002b36, 0x40) then
    item.CurrentStage = 1
  end
  if not testFlag(segment, 0x2002b36, 0x40) then
    item.CurrentStage = 0
  end
end

function updateFlippers(segment)
  local item = Tracker:FindObjectForCode("flippers")
  if testFlag(segment, 0x2002b43, 0x10) then
    item.CurrentStage = 1
  end
  if not testFlag(segment, 0x2002b43, 0x10) then
    item.CurrentStage = 0
  end
end

function updateBoomerang(segment)
  local item = Tracker:FindObjectForCode("boomerang")
  if testFlag(segment, 0x2002b34, 0x40) then
    item.CurrentStage = 1
  end
  if testFlag(segment, 0x2002b35, 0x01) then
    item.CurrentStage = 2
  end
  if not testFlag(segment, 0x2002b34, 0x40) and not testFlag (segment, 0x2002b35, 0x01) then
    item.CurrentStage = 0
  end
end

function updateShield(segment)
  local item = Tracker:FindObjectForCode("shield")
  if testFlag(segment, 0x2002b35, 0x04) then
    item.CurrentStage = 1
  end
  if testFlag(segment, 0x2002b35, 0x10) then
    item.CurrentStage = 2
  end
  if not testFlag(segment, 0x2002b35, 0x10) and not testFlag(segment, 0x2002b35, 0x04) then
    item.CurrentStage = 0
  end
end

function updateLamp(segment)
  local item = Tracker:FindObjectForCode("lamp")
  if testFlag(segment, 0x2002b35, 0x40) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateBottles(segment)
  local item = Tracker:FindObjectForCode("bottle")
  local value = ReadU8(segment, 0x2002b39)
  if value == 0x01 then
    item.CurrentStage = 1
  elseif value == 0x05 then
    item.CurrentStage = 2
  elseif value == 0x15 then
    item.CurrentStage = 3
  elseif value == 0x55 then
    item.CurrentStage = 4
  else
    item.CurrentStage = 0
  end
end

function updateBombs(segment)
  local item = Tracker:FindObjectForCode("bombs")
  if item then
    item.CurrentStage = ReadU8(segment, 0x2002aee)
  end
  if ReadU8(segment, 0x2002aee) == 0x00 then
    item.CurrentStage = 0
  end
end

function updateWallet(segment)
  local item = Tracker:FindObjectForCode("wallet")
  if item then
    item.CurrentStage = ReadU8(segment, 0x2002ae8)
  end
  if ReadU8(segment, 0x2002ae8) == 0x00 then
    item.CurrentStage = 0
  end
end

function updateGoldFallsUsed(segment, address, flag)
  local item = Tracker:FindObjectForCode("falls")
  if testFlag(segment, address, flag) then
    item.CurrentStage = 1
  end
end

function updateGoldFalls(segment)
  local item = Tracker:FindObjectForCode("falls")
  if ReadU8(segment, 0x2002b58) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b59) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b5a) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b5b) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b5c) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b5d) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b5e) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b5f) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b60) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b61) == 0x6d then
    item.CurrentStage = 1
  elseif ReadU8(segment, 0x2002b62) == 0x6d then
    item.CurrentStage = 1
  end
end

function updateWildsUsedFixed(segment, locationData)
  local item = Tracker:FindObjectForCode("wilds")
  if item then
    WildsFused = 0
    for i=1, 3, 1 do
      local address = locationData[i][1]
      local flag = locationData[i][2]
      local value = ReadU8(segment,address)

      local flagTest = value & flag

      if flagTest ~= 0 then
        WildsFused = WildsFused + 1
      end
    end
    print("Wilds Used", WildsFused)
  end
end

function updateWilds(segment, code, flag, numUsed)
  local item = Tracker:FindObjectForCode(code)
  local inBag = 0

  if ReadU8(segment, 0x2002b58) == flag then
    inBag = ReadU8(segment, 0x2002b6b)
    print("Wilds in Bag", ReadU8(segment, 0x2002b6b))

  elseif ReadU8(segment, 0x2002b59) == flag then
    inBag = ReadU8(segment, 0x2002b6c)
    print("Wilds in Bag", ReadU8(segment, 0x2002b6c))

  elseif ReadU8(segment, 0x2002b5a) == flag then
    inBag = ReadU8(segment, 0x2002b6d)
    print("Wilds in Bag", ReadU8(segment, 0x2002b6d))

  elseif ReadU8(segment, 0x2002b5b) == flag then
    inBag = ReadU8(segment, 0x2002b6e)
    print("Wilds in Bag", ReadU8(segment, 0x2002b6e))

  elseif ReadU8(segment, 0x2002b5c) == flag then
    inBag = ReadU8(segment, 0x2002b6f)
    print("Wilds in Bag", ReadU8(segment, 0x2002b6f))

  elseif ReadU8(segment, 0x2002b5d) == flag then
    inBag = ReadU8(segment, 0x2002b70)
    print("Wilds in Bag", ReadU8(segment, 0x2002b70))

  elseif ReadU8(segment, 0x2002b5e) == flag then
    inBag = ReadU8(segment, 0x2002b71)
    print("Wilds in Bag", ReadU8(segment, 0x2002b71))

  elseif ReadU8(segment, 0x2002b5f) == flag then
    inBag = ReadU8(segment, 0x2002b72)
    print("Wilds in Bag", ReadU8(segment, 0x2002b72))

  elseif ReadU8(segment, 0x2002b60) == flag then
    inBag = ReadU8(segment, 0x2002b73)
    print("Wilds in Bag", ReadU8(segment, 0x2002b73))

  elseif ReadU8(segment, 0x2002b61) == flag then
    inBag = ReadU8(segment, 0x2002b74)
    print("Wilds in Bag", ReadU8(segment, 0x2002b74))

  elseif ReadU8(segment, 0x2002b62) == flag then
    inBag = ReadU8(segment, 0x2002b75)
    print("Wilds in Bag", ReadU8(segment, 0x2002b75))
  end

  item.AcquiredCount = numUsed + inBag
  print("Wilds Obtained", inBag)
end

function updateCloudsUsedFixed(segment, locationData)
  local item = Tracker:FindObjectForCode("clouds")
  if item then
    CloudsFused = 0
    for i=1, 5, 1 do
      local address = locationData[i][1]
      local flag = locationData[i][2]
      local value = ReadU8(segment,address)

      local flagTest = value & flag

      if flagTest ~= 0 then
        CloudsFused = CloudsFused + 1
      end
    end
    print("Clouds Fused", CloudsFused)
  end
end

function updateClouds(segment, code, flag)
  local item = Tracker:FindObjectForCode(code)
  local inBag = 0

  if ReadU8(segment, 0x2002b58) == flag then
    inBag = ReadU8(segment, 0x2002b6b)
    print("Clouds in Bag", ReadU8(segment, 0x2002b6b))

  elseif ReadU8(segment, 0x2002b59) == flag then
    inBag = ReadU8(segment, 0x2002b6c)
    print("Clouds in Bag", ReadU8(segment, 0x2002b6c))

  elseif ReadU8(segment, 0x2002b5a) == flag then
    inBag = ReadU8(segment, 0x2002b6d)
    print("Clouds in Bag", ReadU8(segment, 0x2002b6d))

  elseif ReadU8(segment, 0x2002b5b) == flag then
    inBag = ReadU8(segment, 0x2002b6e)
    print("Clouds in Bag", ReadU8(segment, 0x2002b6e))

  elseif ReadU8(segment, 0x2002b5c) == flag then
    inBag = ReadU8(segment, 0x2002b6f)
    print("Clouds in Bag", ReadU8(segment, 0x2002b6f))

  elseif ReadU8(segment, 0x2002b5d) == flag then
    inBag = ReadU8(segment, 0x2002b70)
    print("Clouds in Bag", ReadU8(segment, 0x2002b70))

  elseif ReadU8(segment, 0x2002b5e) == flag then
    inBag = ReadU8(segment, 0x2002b71)
    print("Clouds in Bag", ReadU8(segment, 0x2002b71))

  elseif ReadU8(segment, 0x2002b5f) == flag then
    inBag = ReadU8(segment, 0x2002b72)
    print("Clouds in Bag", ReadU8(segment, 0x2002b72))

  elseif ReadU8(segment, 0x2002b60) == flag then
    inBag = ReadU8(segment, 0x2002b73)
    print("Clouds in Bag", ReadU8(segment, 0x2002b73))

  elseif ReadU8(segment, 0x2002b61) == flag then
    inBag = ReadU8(segment, 0x2002b74)
    print("Clouds in Bag", ReadU8(segment, 0x2002b74))

  elseif ReadU8(segment, 0x2002b62) == flag then
    inBag = ReadU8(segment, 0x2002b75)
    print("Clouds in Bag", ReadU8(segment, 0x2002b75))
  end

  item.AcquiredCount = inBag + CloudsFused

  print("Clouds Obtained", CloudsFused)
end

function updateHearts(segment, address)
  local item = Tracker:FindObjectForCode("hearts")
  if item then
    item.CurrentStage = ReadU8(segment, address)/8
  end
end

function updateSmallKeys(segment, code, address)
  local item = Tracker:FindObjectForCode(code)
  if code == "dws_smallkey" then
    if ReadU8(segment, address) > DWS_KEY_PREV_VALUE then
      DWS_KEY_COUNT = DWS_KEY_COUNT + 1
      item.AcquiredCount = DWS_KEY_COUNT
    end
    DWS_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "cof_smallkey" then
    if ReadU8(segment, address) > COF_KEY_PREV_VALUE then
      COF_KEY_COUNT = COF_KEY_COUNT + 1
      item.AcquiredCount = COF_KEY_COUNT
    end
    COF_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "fow_smallkey" then
    if ReadU8(segment, address) > FOW_KEY_PREV_VALUE then
      FOW_KEY_COUNT = FOW_KEY_COUNT + 1
      item.AcquiredCount = FOW_KEY_COUNT
    end
    FOW_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "tod_smallkey" then
    if ReadU8(segment, address) > TOD_KEY_PREV_VALUE then
      TOD_KEY_COUNT = TOD_KEY_COUNT + 1
      item.AcquiredCount = TOD_KEY_COUNT
    end
    TOD_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "pow_smallkey" then
    if ReadU8(segment, address) > POW_KEY_PREV_VALUE then
      POW_KEY_COUNT = POW_KEY_COUNT + 1
      item.AcquiredCount = POW_KEY_COUNT
    end
    POW_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "dhc_smallkey" then
    if ReadU8(segment, address) > DHC_KEY_PREV_VALUE then
      DHC_KEY_COUNT = DHC_KEY_COUNT + 1
      item.AcquiredCount = DHC_KEY_COUNT
    end
    DHC_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "dhc_smallkey_ks" then
    if ReadU8(segment, address) > DHCKS_KEY_PREV_VALUE then
      DHCKS_KEY_COUNT = DHCKS_KEY_COUNT + 1
      item.AcquiredCount = DHCKS_KEY_COUNT
    end
    DHCKS_KEY_PREV_VALUE = ReadU8(segment, address)
  elseif code == "rc_smallkey" then
    if ReadU8(segment, address) > RC_KEY_PREV_VALUE then
      RC_KEY_COUNT = RC_KEY_COUNT + 1
      item.AcquiredCount = RC_KEY_COUNT
    end
    RC_KEY_PREV_VALUE = ReadU8(segment, address)
  else
    item.AcquiredCount = 0
  end
end

function updateSpin(segment)
  local item = Tracker:FindObjectForCode("spinattack")
  if testFlag(segment, 0x2002b44, 0x01) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateRoll(segment)
  local item = Tracker:FindObjectForCode("rollattack")
  if testFlag(segment, 0x2002b44, 0x04) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateDash(segment)
  local item = Tracker:FindObjectForCode("dashattack")
  if testFlag(segment, 0x2002b44, 0x10) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateRock(segment)
  local item = Tracker:FindObjectForCode("rockbreaker")
  if testFlag(segment, 0x2002b44, 0x40) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateBeam(segment)
  local item = Tracker:FindObjectForCode("swordbeam")
  if testFlag(segment, 0x2002b45, 0x01) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateGreat(segment)
  local item = Tracker:FindObjectForCode("greatspin")
  if testFlag(segment, 0x2002b45, 0x04) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateDown(segment)
  local item = Tracker:FindObjectForCode("downthrust")
  if testFlag(segment, 0x2002b45, 0x10) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updatePeril(segment)
  local item = Tracker:FindObjectForCode("perilbeam")
  if testFlag(segment, 0x2002b45, 0x40) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateFast(segment)
  local item = Tracker:FindObjectForCode("fastspin")
  if testFlag(segment, 0x2002b4e, 0x40) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateSplit(segment)
  local item = Tracker:FindObjectForCode("fastsplit")
  if testFlag(segment, 0x2002b4f, 0x01) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateLong(segment)
  local item = Tracker:FindObjectForCode("longspin")
  if testFlag(segment, 0x2002b4f, 0x04) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateDWS(segment)
  local item = Tracker:FindObjectForCode("dws")
  if testFlag(segment, 0x2002c9c, 0x04) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateCOF(segment)
  local item = Tracker:FindObjectForCode("cof")
  if testFlag(segment, 0x2002c9c, 0x08) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateFOW(segment)
  local item = Tracker:FindObjectForCode("fow")
  if testFlag(segment, 0x2002c9c, 0x10) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateTOD(segment)
  local item = Tracker:FindObjectForCode("tod")
  if testFlag(segment, 0x2002c9c, 0x20) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updatePOW(segment)
  local item = Tracker:FindObjectForCode("pow")
  if testFlag(segment, 0x2002c9c, 0x40) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateRC(segment)
  local item = Tracker:FindObjectForCode("rc")
  if testFlag(segment, 0x2002d02, 0x04) then
    item.CurrentStage = 1
  else
    item.CurrentStage = 0
  end
end

function updateItemsFromMemorySegment(segment)
  if not isInGame() then
    return false
  end
  InvalidateReadCaches()

  if AUTOTRACKER_ENABLE_ITEM_TRACKING then

    updateToggleItemFromByteAndFlag(segment, "bombsremote", 0x2002b34, 0x01)
    updateToggleItemFromByteAndFlag(segment, "gust", 0x2002b36, 0x04)
    updateToggleItemFromByteAndFlag(segment, "cane", 0x2002b36, 0x10)
    updateToggleItemFromByteAndFlag(segment, "cape", 0x2002b37, 0x01)
    updateToggleItemFromByteAndFlag(segment, "boots", 0x2002b37, 0x04)
    updateToggleItemFromByteAndFlag(segment, "ocarina", 0x2002b37, 0x40)
    updateToggleItemFromByteAndFlag(segment, "trophy", 0x2002b41, 0x04)
    updateToggleItemFromByteAndFlag(segment, "carlov", 0x2002b41, 0x10)
    updateToggleItemFromByteAndFlag(segment, "grip", 0x2002b43, 0x01)
    updateToggleItemFromByteAndFlag(segment, "bracelets", 0x2002b43, 0x04)
    updateToggleItemFromByteAndFlag(segment, "jabber", 0x2002b48, 0x40)
    updateToggleItemFromByteAndFlag(segment, "bowandfly", 0x2002b4e, 0x01)
    updateToggleItemFromByteAndFlag(segment, "mittsandfly", 0x2002b4e, 0x04)
    updateToggleItemFromByteAndFlag(segment, "flippersandfly", 0x2002b4e, 0x10)
    updateToggleItemFromByteAndFlag(segment, "earth", 0x2002b42, 0x01)
    updateToggleItemFromByteAndFlag(segment, "fire", 0x2002b42, 0x04)
    updateToggleItemFromByteAndFlag(segment, "water", 0x2002b42, 0x10)
    updateToggleItemFromByteAndFlag(segment, "wind", 0x2002b42, 0x40)

    updateLLRKey(segment, "llrkey", 0x2002b3f, 0x40)
    updateDogFood(segment, "dogbottle", 0x2002b3f, 0x10)
    updateMush(segment, "mushroom", 0x2002b40, 0x01)
    updateBooks(segment, "books", 0x2002b40)
    updateGraveKey(segment, "gravekey", 0x2002b41, 0x01)

    updateSwords(segment)
    updateBow(segment)
    updateMitts(segment)
    updateFlippers(segment)
    updateBoomerang(segment)
    updateShield(segment)
    updateLamp(segment)
    updateBottles(segment)
    updateGoldFalls(segment)
    updateWilds(segment, "wilds", 0x6a, WildsFused)
    updateClouds(segment, "clouds", 0x65)

    updateSpin(segment)
    updateRoll(segment)
    updateDash(segment)
    updateRock(segment)
    updateBeam(segment)
    updateGreat(segment)
    updateDown(segment)
    updatePeril(segment)
    updateFast(segment)
    updateSplit(segment)
    updateLong(segment)

    updateSectionChestCountFromByteAndFlag(segment, "@Fifi/Fifi", 0x2002b3f, 0x20)
  end

  if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    return true
  end
end

function updateGearFromMemory(segment)
  if not isInGame() then
    return false
  end

  InvalidateReadCaches()

  if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    updateBombs(segment)
    updateWallet(segment)
    updateHearts(segment, 0x2002aeb)
  end

  if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    return true
  end
end

function updateLocations(segment)
  if not isInGame() then
    return false
  end

  InvalidateReadCaches()

  if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    updateDWS(segment)
    updateCOF(segment)
    updateFOW(segment)
    updateTOD(segment)
    updateRC(segment)
    updatePOW(segment)
  end

  if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    return true
  end

  --FUSIONS
  updateSectionChestCountFromByteAndFlag(segment, "@Top Right Fusion/Top Right Fusion", 0x2002c81, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Bottom Left Fusion/Bottom Left Fusion", 0x2002c81, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Top Left Fusion/Top Left Fusion", 0x2002c81, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Center Fusion/Central Fusion", 0x2002c81, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Bottom Right Fusion/Bottom Right Fusion", 0x2002c81, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Castor Wilds Fusions/Left", 0x2002c81, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Castor Wilds Fusions/Middle", 0x2002c81, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Castor Wilds Fusions/Right", 0x2002c82, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Source of the Flow Cave/Fusion", 0x2002c82, 0x02)
  updateGoldFallsUsed(segment, 0x2002c82, 0x02)
  updateWildsUsedFixed(segment, {{0x2002c81,0x40},{0x2002c81,0x80},{0x2002c82,0x01}})
  updateCloudsUsedFixed(segment, {{0x2002c81,0x02},{0x2002c81,0x04},{0x2002c81,0x08},{0x2002c81,0x10},{0x2002c81,0x20}})

  --CRENEL
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Climbing Wall Chest/Wall Chest", 0x2002cd4, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Wall Fairy/Crenel Fairy", 0x2002cf0, 0x01)
  decreaseChestCount(segment, "@Melari/Digging Spots", {{0x2002cf4, 0x01},{0x2002cf3, 0x02},{0x2002cf3, 0x80},{0x2002cf3, 0x40},{0x2002cf3, 0x20},{0x2002cf3, 0x10},{0x2002cf3, 0x04},{0x2002cf3, 0x08}})
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Climbing Wall Cave/Crenel Climbing Wall Cave", 0x2002d04, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Mt. Crenel Beanstalk/Heart Piece", 0x2002d0c, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Mt. Crenel Beanstalk Rupees/Beanstalk", 0x2002d0c, 0x08)
  clearRupees(segment, "@Mt. Crenel Beanstalk/Rupees", {{0x2002d0e,0x40},{0x2002d0e,0x80},{0x2002d0f,0x01},{0x2002d0f,0x02},{0x2002d0f,0x04},{0x2002d0f,0x08},{0x2002d0f,0x10},{0x2002d0f,0x20}})
  updateSectionChestCountFromByteAndFlag(segment, "@Rainy Minish Path Chest/Rainy Chest", 0x2002d10, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Melari/Minish Path Chest", 0x2002d11, 0x08)
  decreaseChestCount(segment, "@Grayblade/Chests", {{0x2002d1c, 0x02},{0x2002d1c,0x04}})
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Mines Cave/Crenel Mines Cave", 0x2002d23, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Bridge Cave/Bridge Cave", 0x2002d23, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Fairy Cave Heart Piece/Fairy Cave", 0x2002d2b, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Grayblade/Heart Piece", 0x2002d2c, 0x01)

  --CRENEL BASE
  updateSectionChestCountFromByteAndFlag(segment, "@Vine Rupee/Rupee", 0x2002cc5, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Base Chest/Crenel Base Chest", 0x2002cd4, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Minish Crack/Minish Crack", 0x2002cde, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Spring Water Path Chest/Spring Water Path", 0x2002d10, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Heart Piece Cave/Heart Piece", 0x2002d24, 0x01)
  decreaseChestCount(segment, "@Crenel Heart Piece Cave/Chests", {{0x2002d24, 0x02},{0x2002d24,0x04}})
  clearRupees(segment, "@Crenel Base Fairy Cave/Fairy Rupees", {{0x2002d24, 0x08},{0x2002d24,0x10},{0x2002d24,0x20}})
  updateSectionChestCountFromByteAndFlag(segment, "@Crenel Minish Hole/Minish Hole", 0x2002d28, 0x01)

  --CASTOR WILDS
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Platform Chest/Platform Chest", 0x2002cbd, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Diving Spots/Top", 0x2002cc0, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Diving Spots/Middle", 0x2002cc0, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Diving Spots/Bottom", 0x2002cc0, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Mulldozers/Bow Chest", 0x2002cde, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Northern Minish Crack/Minish Crack", 0x2002cde, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Western Minish Crack/Minish Crack", 0x2002cde, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Vine Minish Crack/Minish Crack", 0x2002cde, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Mulldozers/Left Crack", 0x2002cf0, 0x20)
  decreaseChestCount(segment, "@Castor Wilds Mitts Cave/Castor Wilds Mitts Cave", {{0x2002d04, 0x01},{0x2002d04,0x02}})
  updateSectionChestCountFromByteAndFlag(segment, "@South Cave/South Cave", 0x2002d22, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@North Cave/Northeast Cave", 0x2002d22, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Castor Wilds Top Right Cave/Castor Wilds Top Right Cave", 0x2002d23, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Darknut/Darknut", 0x2002d23, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Swiftblade the First/Heart Piece", 0x2002d2b, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Water Minish Hole/Water Hole Chest", 0x2002d2c, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Wilds Water Minish Hole/Water Hole Heart Piece", 0x2002d2c, 0x20)

  --WIND RUINS
  decreaseChestCount(segment, "@Armos/Armos", {{0x2002cc2, 0x08},{0x2002cc2,0x10}})
  updateSectionChestCountFromByteAndFlag(segment, "@Pre FOW Chest/Pre FOW Chest", 0x2002cd2, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@4 Pillars Chest/4 Pillars Chest", 0x2002cd4, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Hole/Minish Hole", 0x2002cde, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Crack/Chest", 0x2002cf0, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Wind Ruins Beanstalk/Big Chest", 0x2002d0c, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Bomb Wall/Bomb Wall", 0x2002d22, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Wall Hole/Minish Hole Heart Piece", 0x2002d2b, 0x40)

  --VALLEY
  updateSectionChestCountFromByteAndFlag(segment, "@Lost Woods Secret Chest/Left Left Left Up Up Up", 0x2002cc7, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Northwest Grave Area/Nearby Chest", 0x2002cd3, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Northeast Grave Area/Nearby Chest", 0x2002cd3, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Dampe/Dampe", 0x2002ce9, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Great Fairy/Great Fairy", 0x2002cef, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Royal Crypt/King Gustaf", 0x2002d02, 0x04)
  decreaseChestCount(segment, "@Royal Crypt/Key drops", {{0x2002d12, 0x40},{0x2002d12, 0x80}})
  decreaseChestCount(segment, "@Royal Crypt/Gibdos", {{0x2002d14, 0x10},{0x2002d14, 0x20}})
  updateSectionChestCountFromByteAndFlag(segment, "@Northwest Grave Area/Northwest Grave", 0x2002d27, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Northeast Grave Area/Northeast Grave", 0x2002d27, 0x40)

  --TRILBY
  updateSectionChestCountFromByteAndFlag(segment, "@Trilby Business Scrub/Trilby Business Scrub", 0x2002ca7, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Northern Chest/Chest", 0x2002cd2, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Rocks Chest/Rocks Chest", 0x2002cd3, 0x10)
  decreaseChestCount(segment, "@Trilby Highlands Cave/Trilby Cave", {{0x2002d04,0x80},{0x2002d05,0x02}})
  updateSectionChestCountFromByteAndFlag(segment, "@Trilby Water Mitts Cave/Trilby Cave", 0x2002d05, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Trilby Highlands Bomb Wall/Trilby Highlands Bomb Wall", 0x2002d1d, 0x20)
  clearRupees(segment, "@Trilby Highlands Drained Pond/Rupees",{{0x2002d20,0x10},{0x2002d20,0x20},{0x2002d20,0x40},{0x2002d20,0x80},{0x2002d21,0x01},{0x2002d21,0x02},{0x2002d21,0x04},{0x2002d21,0x08},{0x2002d21,0x10},{0x2002d21,0x20},{0x2002d21,0x40},{0x2002d21,0x80},{0x2002d22,0x01},{0x2002d22,0x02},{0x2002d22,0x04}})

  --WESTERN WOOD
  decreaseChestCount(segment, "@Western Wood Upper Dig Spot/Dig Spots", {{0x2002cce,0x08},{0x2002cce,0x10},{0x2002cce,0x20},{0x2002cce,0x40},{0x2002cce,0x80},{0x2002ccf,0x01}})
  decreaseChestCount(segment, "@Western Wood Lower Dig Spot/Dig Spots", {{0x2002ccf, 0x02},{0x2002ccf,0x04}})
  updateSectionChestCountFromByteAndFlag(segment, "@Western Wood Chest/Freestanding Chest",0x2002ccf, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Percy's House/Percy Reward", 0x2002ce3, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Percy's House/Moblin Reward", 0x2002ce4, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Western Woods Tree/Heart Piece", 0x2002cef, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Western Woods Beanstalk/Chest", 0x2002d0d, 0x08)
  clearRupees(segment, "@Western Woods Beanstalk/Rupees",{{0x2002d0d,0x10},{0x2002d0d,0x20},{0x2002d0d,0x40},{0x2002d0d,0x80},{0x2002d0e,0x01},{0x2002d0e,0x02},{0x2002d0e,0x04},{0x2002d0e,0x08},{0x2002d0f,0x40},{0x2002d0f,0x80},{0x2002d10,0x01},{0x2002d10,0x02},{0x2002d10,0x04},{0x2002d10,0x08},{0x2002d10,0x10},{0x2002d10,0x20}})

  --GARDENS
  decreaseChestCount(segment, "@Moat/Moat", {{0x2002cbe, 0x04},{0x2002cbe,0x08}})
  updateSectionChestCountFromByteAndFlag(segment, "@Grimblade/Heart Piece", 0x2002d2c, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Gardens Right Fountain/Dry Fountain", 0x2002d0e, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Gardens Right Fountain/Minish Hole", 0x2002d28, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Gardens Left Fountain/Minish Hole", 0x2002d28, 0x20)

  --NORTH FIELD
  updateSectionChestCountFromByteAndFlag(segment, "@North Field Digging Spot/North Field Digging Spot", 0x2002ccd, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Pre Royal Valley Chest/Chest", 0x2002cd3, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@North Trees/Top Left Tree", 0x2002d1c, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@North Trees/Top Right Tree", 0x2002d1c, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@North Trees/Bottom Left Tree", 0x2002d1c, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@North Trees/Bottom Right Tree", 0x2002d1c, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@North Trees/Center Ladder", 0x2002d1d, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@North Field Heart Piece/North Field Heart Piece", 0x2002d2b, 0x08)

  --HYRULE TOWN
  updateSectionChestCountFromByteAndFlag(segment, "@Anju/Anju", 0x2002ca5, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Hearth Ledge/Hearth Ledge", 0x2002cd5, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@School/Roof Chest", 0x2002cd5, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Bell/Bell", 0x2002cd5, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Cafe/Lady Next to Cafe", 0x2002cd6, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Hearth/Hearth Right Pot", 0x2002ce0, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Dog Food", 0x2002ce6, 0x08)
--  updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Wallet Spot (80 Rupees)", 0x2002ce6, 0x20)
--  updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Quiver Spot (600 Rupees)", 0x2002ce6, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Library/Yellow Library Minish", 0x2002ceb, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Figurine Shop/Heart Piece", 0x2002cf2, 0x10)
  decreaseChestCount(segment, "@Figurine Shop/3 Chests", {{0x2002cf2, 0x20},{0x2002cf2,0x40},{0x2002cf2,0x80}})
  updateSectionChestCountFromByteAndFlag(segment, "@Hearth/Hearth Back Door Heart Piece", 0x2002cf3, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@School/Pull the Statue", 0x2002cfc, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Town's Cave/Town Basement Left", 0x2002cfc, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Town Basement Right/Town Basement Right", 0x2002cfd, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Hyrule Well/Hyrule Well Bottom Chest", 0x2002cfd, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Hyrule Well/Hyrule Well Center Chest", 0x2002cfd, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Fountain/Mulldozers", 0x2002cfd, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Fountain/Mulldozers (Weapon)", 0x2002cfd, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Fountain/Small Chest", 0x2002cfe, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Flippers Cave/Waterfall Rupee", 0x2002cfe, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Flippers Cave/Scissor Beetles", 0x2002cfe, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Flippers Cave/Scissor Beetles (Weapon)", 0x2002cfe, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Flippers Cave/Frozen Chest", 0x2002cfe, 0x20)
  decreaseChestCount(segment, "@Town's Cave/Cave Chests", {{0x2002d04, 0x04},{0x2002d04,0x08},{0x2002d04,0x10}})
  updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Roof Chest", 0x2002d0a, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@School Garden/Heart Piece", 0x2002d0b, 0x40)
  decreaseChestCount(segment, "@School Garden/Garden Chests",{{0x2002d0b,80},{0x2002d0c,0x01},{0x2002d0c,0x02}})
  updateSectionChestCountFromByteAndFlag(segment, "@School Garden/Path Chest", 0x2002d11, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Brioche Chest/Brioche Chest", 0x2002d13, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Fountain/Heart Piece", 0x2002d14, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Town Waterfall/Waterfall", 0x2002d1d, 0x40)

  --SOUTH FIELD
  updateSectionChestCountFromByteAndFlag(segment, "@Tingle/Tingle", 0x2002ca3, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Near Link's House Chest/Chest", 0x2002cd3, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Smith's House/Intro Items", 0x2002cde, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Tree Heart Piece/Tree Heart Piece", 0x2002cee, 0x80)
  clearRupees(segment,"@South Field Drained Pond/Rupees", {{0x2002d1e,0x20},{0x2002d1e,0x40},{0x2002d1e,0x80},{0x2002d1f,0x01},{0x2002d1f,0x02},{0x2002d1f,0x04},{0x2002d1f,0x08},{0x2002d1f,0x10},{0x2002d1f,0x20},{0x2002d1f,0x40},{0x2002d1f,0x80},{0x2002d20,0x01},{0x2002d20,0x02},{0x2002d20,0x04},{0x2002d20,0x08}})
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Flippers Hole/Minish Flippers Hole", 0x2002d2c, 0x02)

  --VEIL FALLS
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls Upper Heart Piece/Upper Heart Piece", 0x2002cd0, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Source of the Flow Cave/Bombable Wall Second Chest", 0x2002cd0, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls South Rupees/Outside Rupee 1", 0x2002cd0, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls South Rupees/Outside Rupee 2", 0x2002cd0,0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls South Rupees/Outside Rupee 3", 0x2002cd0,0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls North Digging Spot/North Digging Spot", 0x2002cd0, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls Lower Heart Piece/Veil Falls Lower Heart Piece", 0x2002cd1, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls North Digging Spot/North Rock Chest", 0x2002cd3, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls South Digging Spot/South Digging Spot", 0x2002cda, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Fusion Digging Cave/Chest", 0x2002d05, 0x04)
  decreaseChestCount(segment, "@Veil Falls South Mitts Cave/Cave Chests", {{0x2002d05, 0x08},{0x2002d05,0x10}})
  updateSectionChestCountFromByteAndFlag(segment, "@Fusion Digging Cave/Heart Piece", 0x2002d05, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Middle Cave/Upper Chest", 0x2002d25, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Middle Cave/Bomb Wall Chest", 0x2002d25, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Source of the Flow Cave/Bombable Wall First Chest", 0x2002d25, 0x10)
  clearRupees(segment, "@Middle Cave/Lower Rupees", {{0x2002d25,0x20},{0x2002d25,0x40},{0x2002d25,0x80},{0x2002d26,0x01},{0x2002d26,0x02},{0x2002d26,0x04},{0x2002d26,0x08},{0x2002d26,0x10},{0x2002d26,0x20}})
  decreaseChestCount(segment, "@Middle Cave/Lower Water Rupees", {{0x2002d26,0x40},{0x2002d26,0x80},{0x2002d27,0x01},{0x2002d27,0x02},{0x2002d27,0x04},{0x2002d27,0x08}})
  updateSectionChestCountFromByteAndFlag(segment, "@Veil Falls Upper Waterfall/Waterfall Heart Piece", 0x2002d27, 0x10)

  --LON LON RANCH
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon North Heart Piece/Lon Lon North Heart Piece", 0x2002ccb, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Ranch Digging Spot/Digging Spot Above Tree", 0x2002ccb, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@North Ranch Chest/Chest", 0x2002cd3, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Pot/Lon Lon Pot", 0x2002ce5, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Minish Crack/Lon Lon Minish Crack", 0x2002cf2, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Farm Heart Piece/Minish Path Chest", 0x2002d11, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Farm Heart Piece/Lon Lon Farm Heart Piece", 0x2002d13, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Cave/Lon Lon Cave", 0x2002d1d, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Cave/Hidden Bomb Wall", 0x2002d1e, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Lon Lon Dried Up Pond/Lon Lon Pond", 0x2002d1e, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Goron Quest/Big Chest", 0x2002d2a, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Goron Quest/Small Chest", 0x2002d2a, 0x80)

  --EASTERN HILLS
  updateSectionChestCountFromByteAndFlag(segment, "@Farm Chest/Farm Chest", 0x2002cd2, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Farmer Mitts Cave/Rupee", 0x2002d04, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Eastern Hills Beanstalk/Beanstalk Heart Piece", 0x2002d0d, 0x01)
  decreaseChestCount(segment, "@Eastern Hills Beanstalk/Beanstalk Chests", {{0x2002d0d, 0x02},{0x2002d0d, 0x04}})
  updateSectionChestCountFromByteAndFlag(segment, "@Eastern Hills Bombable Wall/Eastern Hills Bomb Wall", 0x2002d22, 0x08)

  --LAKE HYLIA
  updateSectionChestCountFromByteAndFlag(segment, "@Hylia Central Heart Piece/Central Heart Piece", 0x2002cbd, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Pond Heart Piece/Pond Heart Piece", 0x2002cbd, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Hylia Southern Heart Piece/Hylia Southern Heart Piece", 0x2002cbd, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Librari/Librari", 0x2002cf2, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Middle of the Lake/Digging Cave", 0x2002d02, 0x40)
  decreaseChestCount(segment, "@North Hylia Cape Cave/North Hylia Cape Cave", {{0x2002d02,0x80},{0x2002d03,0x02},{0x2002d03,0x04},{0x2002d03,0x08},{0x2002d03,0x10},{0x2002d03,0x20},{0x2002d03,0x40}})
  updateSectionChestCountFromByteAndFlag(segment, "@North Hylia Cape Cave/Beanstalk Heart Piece", 0x2002d0c, 0x10)
  decreaseChestCount(segment, "@North Hylia Cape Cave/Beanstalk", {{0x2002d0c, 0x20},{0x2002d0c,0x40}})
  updateSectionChestCountFromByteAndFlag(segment, "@Lake Cabin/Lake Cabin Chest", 0x2002d11, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@North Minish Hole/North Minish Hole", 0x2002d2a, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@North Minish Hole/North Minish Hole (Fusion)", 0x2002d2a, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Waveblade/Heart Piece", 0x2002d2c, 0x04)

  --MINISH WOODS
  updateSectionChestCountFromByteAndFlag(segment, "@Northern Heart Piece/Northern Heart Piece", 0x2002cc3, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Shrine Heart Piece/Shrine Heart Piece", 0x2002cc3, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods North Chest/Chest", 0x2002cd2, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods East Chest/Chest", 0x2002cd2, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods South Chest/Minish South Chest", 0x2002cd2, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods West Chest/Chest", 0x2002cd3, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Post Minish Village Chest/Wind Crest Chest", 0x2002cdb, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods Great Fairy/Minish Woods Great Fairy", 0x2002cef, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods Crack/Chest", 0x2002cf0, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Belari/Belari Remote Bombs", 0x2002cf2, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Village/Dock Heart Piece", 0x2002cf4, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Village/Barrel", 0x2002cf5, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods Syrup Cave/Minish Woods Syrup Cave", 0x2002d02, 0x08)
  decreaseChestCount(segment, "@Like Like Cave/Like Like Cave", {{0x2002d02, 0x10},{0x2002d02,0x20}})
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Village/Minish Path Chest", 0x2002d11, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods North Minish Hole/Minish Woods North Minish Hole", 0x2002d28, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Woods North Minish Hole/Minish Woods North Minish Hole (Fusion)", 0x2002d28, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Flippers Cave/Middle", 0x2002d2a, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Flippers Cave/Right", 0x2002d2a, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Flippers Cave/Left", 0x2002d2a, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Minish Flippers Cave/Left Heart Piece", 0x2002d2b, 0x04)

  --CLOUD TOPS
  updateSectionChestCountFromByteAndFlag(segment, "@Right Chest/Right Chest", 0x2002cd7, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Center Left/Center Left", 0x2002cd7, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Top Left South Chest/Top Left South Chest", 0x2002cd7, 0x20)
  decreaseChestCount(segment, "@Top Left North Chests/Top Left North Chests", {{0x2002cd7, 0x40},{0x2002cd7,0x80}})
  updateSectionChestCountFromByteAndFlag(segment, "@Bottom Left Chest/Bottom Left Chest", 0x2002cd8, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Center Right/Center Right", 0x2002cd8, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Top Left North Chests/Digging Spot on the Left", 0x2002cd8, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Top Right Digging Spot/Digging Spot", 0x2002cd8, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Center Digging Spot/Digging Spot", 0x2002cd8, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Southeast North Digging Spot/Digging Spot", 0x2002cd8, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Bottom Left Digging Spot/Digging Spot", 0x2002cd8, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@South Digging Spot/Digging Spot", 0x2002cd8, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Southeast South Digging Spot/Digging Spot", 0x2002cd9, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Kill Piranhas (North)/Kill Piranhas", 0x2002cda, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Kill Piranhas (South)/Kill Piranhas", 0x2002cda, 0x04)
  decreaseChestCount(segment, "@Wind Tribe House Early/House Chests", {{0x2002cdc,0x20},{0x2002cdc,0x40},{0x2002cdc,0x80}})
  decreaseChestCount(segment, "@Wind Tribe House Fusion/House Chests", {{0x2002cdd,0x01},{0x2002cdd,0x02},{0x2002cdd,0x04},{0x2002cdd,0x40},{0x2002cdd,0x80}})
  decreaseChestCount(segment, "@Wind Tribe House/House Chests", {{0x2002cdc,0x20},{0x2002cdc,0x40},{0x2002cdc,0x80},{0x2002cdd,0x01},{0x2002cdd,0x02},{0x2002cdd,0x04},{0x2002cdd,0x40},{0x2002cdd,0x80}})
  updateSectionChestCountFromByteAndFlag(segment, "@Wind Tribe House Early/Gregal 1st Item", 0x2002ce8, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Wind Tribe House Fusion/Gregal 2nd Item", 0x2002ce8, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Wind Tribe House/Gregal 1st Item", 0x2002ce8, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Wind Tribe House/Gregal 2nd Item", 0x2002ce8, 0x40)

  --DWS
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Madderpillar Chest", 0x2002d3f, 0x08)
  decreaseChestCount(segment, "@Deepwood Shrine/Puffstool Room", {{0x2002d40, 0x04},{0x2002d40,0x08}})
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Two Lamp Chest", 0x2002d40, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Statue Room", 0x2002d40, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/West Side", 0x2002d41, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Barrel Room Northwest", 0x2002d41, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Slug Room", 0x2002d43, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Basement Big Chest", 0x2002d43, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Basement Switch Chest", 0x2002d44, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Basement Switch Room Big Chest", 0x2002d44, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Green Chu", 0x2002d44, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Upstairs Chest", 0x2002d45, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Blue Warp Heart Piece", 0x2002d45, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Madderpillar Heart Piece", 0x2002d46, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Mulldozer Drop", 0x2002d46, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Deepwood Shrine/Mulldozer Drop (Weapon)", 0x2002d46, 0x08)

  --COF
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Spiny Chu Pillar Chest", 0x2002d57, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Spiny Chu Fight", 0x2002d57, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Rollobite Pillar Chest", 0x2002d58, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Rollobite Pillar Chest (Weapon)", 0x2002d58, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Rollobite Chest", 0x2002d58, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Rollobite Chest (Weapon)", 0x2002d58, 0x80)
  decreaseChestCount(segment, "@Cave of Flames/Pre Lava Basement Room", {{0x2002d59, 0x10},{0x2002d59, 0x20}})
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Big Chest Room Small Chest", 0x2002d59, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Big Chest Room Small Chest (Weapon)", 0x2002d59, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Big Chest Room", 0x2002d59, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Big Chest Room (Weapon)", 0x2002d59, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Blade Chest", 0x2002d5a, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Spiny Beetle Fight", 0x2002d5a, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Spiny Beetle Fight (Weapon)", 0x2002d5a, 0x04)
  decreaseChestCount(segment, "@Cave of Flames/Lava Basement (Left,Right)", {{0x2002d5a, 0x80},{0x2002d5b, 0x01}})
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Lava Basement (Center)", 0x2002d5b, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Gleerok", 0x2002d5b, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Cave of Flames/Bomb Wall Heart Piece", 0x2002d5b, 0x10)
  clearRupees(segment, "@Cave of Flames/Rupees", {{0x2002d5b, 0x40},{0x2002d5b, 0x80},{0x2002d5c, 0x01},{0x2002d5c, 0x02},{0x2002d5c, 0x04}})

  --FOW
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Entrance Far Left", 0x2002d05, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Entrance Big Rupee", 0x2002d05, 0x40)
  decreaseChestCount(segment, "@Fortress of Winds/Left Side Mitts Chests (F2 & F3)", {{0x2002d06, 0x01},{0x2002d07, 0x20}})
  decreaseChestCount(segment, "@Fortress of Winds/Right Side Mitts Chests (F2 & F3)", {{0x2002d06, 0x04},{0x2002d07, 0x40}})
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Center Path Switch", 0x2002d06, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Mitts Chest", 0x2002d08, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Bombable Wall Small Chest", 0x2002d08, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Minish Dirt Room Drop", 0x2002d08, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Eyegores", 0x2002d6f, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Left Side Key Drop", 0x2002d70, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Right Side Key Drop", 0x2002d70, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Clone Puzzle Drop", 0x2002d71, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Mazaal", 0x2002d72, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Pedestal Chest", 0x2002d73, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Skull Room Chest", 0x2002d73, 0x04)
  decreaseChestCount(segment, "@Fortress of Winds/2 Lever Room", {{0x2002d73, 0x20},{0x2002d73,0x40}})
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Wizzrobe Fight", 0x2002d74, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/FoW Prize", 0x2002d74, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Fortress of Winds/Far Right Heart Piece", 0x2002d74, 0x80)
  decreaseChestCount(segment, "@Fortress of Winds/Left Side Rupees (Visible 1)", {{0x2002d07,0x04}})
  decreaseChestCount(segment, "@Fortress of Winds/Left Side Rupees (Visible 2)", {{0x2002d07,0x02}})
  clearRupees(segment, "@Fortress of Winds/Left Side Rupees",{{0x2002d06, 0x20},{0x2002d06,0x40},{0x2002d06,0x80},{0x2002d07,0x01},{0x2002d07,0x08}})
  decreaseChestCount(segment, "@Fortress of Winds/Right Side Moldorm Pots", {{0x2002d06, 0x08},{0x2002d06,0x10}})
  
  --TOD
  decreaseChestCount(segment, "@Temple of Droplets/Right Path Ice Walkway Chests", {{0x2002d8b, 0x01},{0x2002d8b,0x04}})
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Overhang Chest", 0x2002d8b, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Octo", 0x2002d8c, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Blue Chu", 0x2002d8c, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Blue Chu Frozen Chest", 0x2002d8d, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Small Key Locked Ice Block", 0x2002d8d, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/First Ice Block", 0x2002d8e, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Ice Basement Frozen Chest", 0x2002d8f, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Ice Basement Frozen Chest (Weapon)", 0x2002d8f, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Ice Basement Free Chest", 0x2002d8f, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Ice Basement Free Chest (Weapon)", 0x2002d8f, 0x08)
  decreaseChestCount(segment, "@Temple of Droplets/Dark Maze (Weapon)", {{0x2002d8f, 0x20},{0x2002d8f, 0x40},{0x2002d8f,0x80}})
  decreaseChestCount(segment, "@Temple of Droplets/Dark Maze", {{0x2002d8f, 0x20},{0x2002d8f, 0x40},{0x2002d8f,0x80}})
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Dark Maze Bomb Wall", 0x2002d91, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Dark Maze Bomb Wall (Weapon)", 0x2002d91, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Post Blue Chu Frozen Chest", 0x2002d92, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Post Ice Madderpillar Chest", 0x2002d92, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Post Ice Madderpillar Chest (Weapon)", 0x2002d92, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Underwater Pot", 0x2002d93, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Ice Puzzle Frozen Chest", 0x2002d93, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Ice Puzzle Frozen Chest (Weapon)", 0x2002d93, 0x40)
  decreaseChestCount(segment, "@Temple of Droplets/Left Path Rupees",{{0x2002d94,0x20},{0x2002d94,0x40},{0x2002d94,0x80},{0x2002d95,0x01},{0x2002d95,0x02}})
  decreaseChestCount(segment, "@Temple of Droplets/Right Path Rupees", {{0x2002d95,0x04,},{0x2002d95,0x08},{0x2002d95,0x10},{0x2002d95,0x20},{0x2002d95,0x40}})
  decreaseChestCount(segment, "@Temple of Droplets/Right Path Rupees (Weapon)", {{0x2002d95,0x04,},{0x2002d95,0x08},{0x2002d95,0x10},{0x2002d95,0x20},{0x2002d95,0x40}})
  decreaseChestCount(segment, "@Temple of Droplets/Lower Water Rupees",{{0x2002d95,0x80},{0x2002d96,0x01},{0x2002d96,0x02},{0x2002d96,0x04},{0x2002d96,0x08},{0x2002d96,0x10}})
  decreaseChestCount(segment, "@Temple of Droplets/Upper Water Rupees",{{0x2002d96,0x20},{0x2002d96,0x40},{0x2002d96,0x80},{0x2002d97,0x01},{0x2002d97,0x02},{0x2002d97,0x04}})
  updateSectionChestCountFromByteAndFlag(segment, "@Temple of Droplets/Right Path Ice Walkway Pot", 0x2002d8b, 0x02)

  --POW
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Pre Big Key Door Big Chest", 0x2002da2, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Bombarossa Maze", 0x2002da2, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Block Maze Detour", 0x2002da2, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Spark Chest", 0x2002da3, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Flail Soldiers", 0x2002da4, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Moblin Archer Chest", 0x2002da4, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Block Maze Room", 0x2002da5, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Switch Chest", 0x2002da5, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Fire Wizzrobe Fight", 0x2002da6, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Pot Puzzle", 0x2002da7, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Twin Wizzrobe Fight", 0x2002da9, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Roller Chest", 0x2002da9, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Wizzrobe Platform Fight", 0x2002daa, 0x10)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Firebar Grate", 0x2002daa, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Dark Room Big", 0x2002dab, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Dark Room Small", 0x2002dab, 0x04)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Gyorg", 0x2002dab, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Palace of Winds/Heart Piece", 0x2002dac, 0x01)
  clearRupees(segment, "@Palace of Winds/Rupees", {{0x2002da7, 0x04},{0x2002da7,0x08},{0x2002da7,0x10},{0x2002da7,0x20},{0x2002da7,0x40}})

  --DHC
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Vaati", 0x2002ca6, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Northwest Tower", 0x2002dbb, 0x40)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Northeast Tower", 0x2002dbb, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Southwest Tower", 0x2002dbc, 0x01)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Southeast Tower", 0x2002dbc, 0x02)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Big key Chest", 0x2002dbc, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Post Throne Big Chest", 0x2002dbf, 0x80)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Blade Chest", 0x2002dc0, 0x20)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Platform Chest", 0x2002dc1, 0x08)
  updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/Stone King", 0x2002dc2, 0x02)
end

function updateKeys(segment)
  if not isInGame() then
    return false
  end

  InvalidateReadCaches()

  if AUTOTRACKER_ENABLE_ITEM_TRACKING then
    updateToggleItemFromByteAndFlag(segment, "dws_map", 0x2002ead, 0x01)
    updateToggleItemFromByteAndFlag(segment, "dws_compass", 0x2002ead, 0x02)
    updateToggleItemFromByteAndFlag(segment, "dws_bigkey", 0x2002ead, 0x04)
    updateToggleItemFromByteAndFlag(segment, "cof_map", 0x2002eae, 0x01)
    updateToggleItemFromByteAndFlag(segment, "cof_compass", 0x2002eae, 0x02)
    updateToggleItemFromByteAndFlag(segment, "cof_bigkey", 0x2002eae, 0x04)
    updateToggleItemFromByteAndFlag(segment, "fow_map", 0x2002eaf, 0x01)
    updateToggleItemFromByteAndFlag(segment, "fow_compass", 0x2002eaf, 0x02)
    updateToggleItemFromByteAndFlag(segment, "fow_bigkey", 0x2002eaf, 0x04)
    updateToggleItemFromByteAndFlag(segment, "tod_map", 0x2002eb0, 0x01)
    updateToggleItemFromByteAndFlag(segment, "tod_compass", 0x2002eb0, 0x02)
    updateToggleItemFromByteAndFlag(segment, "tod_bigkey", 0x2002eb0, 0x04)
    updateToggleItemFromByteAndFlag(segment, "pow_map", 0x2002eb1, 0x01)
    updateToggleItemFromByteAndFlag(segment, "pow_compass", 0x2002eb1, 0x02)
    updateToggleItemFromByteAndFlag(segment, "pow_bigkey", 0x2002eb1, 0x04)
    updateToggleItemFromByteAndFlag(segment, "dhc_map", 0x2002eb2, 0x01)
    updateToggleItemFromByteAndFlag(segment, "dhc_compass", 0x2002eb2, 0x02)
    updateToggleItemFromByteAndFlag(segment, "dhc_bigkey", 0x2002eb2, 0x04)
    updateToggleItemFromByteAndFlag(segment, "dhc_bigkey_ks", 0x2002eb2, 0x04)

    updateSmallKeys(segment, "dws_smallkey", 0x2002e9d)
    updateSmallKeys(segment, "cof_smallkey", 0x2002e9e)
    updateSmallKeys(segment, "fow_smallkey", 0x2002e9f)
    updateSmallKeys(segment, "tod_smallkey", 0x2002ea0)
    updateSmallKeys(segment, "pow_smallkey", 0x2002ea1)
    updateSmallKeys(segment, "dhc_smallkey", 0x2002ea2)
    updateSmallKeys(segment, "dhc_smallkey_ks", 0x2002ea2)
    updateSmallKeys(segment, "rc_smallkey", 0x2002ea3)

--Misc
    updateSectionChestCountFromByteAndFlag(segment, "@Simons Shops/Simons Simulations", 0x2002c9c, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Syrup's Hut/Witch's Item (60 Rupees)", 0x2002ea4, 0x04)
    updateSectionChestCountFromByteAndFlag(segment, "@Shoe Shop/Rem", 0x2002ea4, 0x08)
    updateSectionChestCountFromByteAndFlag(segment, "@Julietta's House/Bookshelf", 0x2002ea4, 0x10)
    updateSectionChestCountFromByteAndFlag(segment, "@Dr. Left's House/Dr. Left's House", 0x2002ea4, 0x20)
    updateSectionChestCountFromByteAndFlag(segment, "@Lake Cabin/Lake Cabin Book", 0x2002ea4, 0x40)
    updateSectionChestCountFromByteAndFlag(segment, "@Lake Cabin/Lake Cabin Book (Fusion)", 0x2002ea4, 0x40)
    updateSectionChestCountFromByteAndFlag(segment, "@Melari/Melari", 0x2002ea4, 0x80)
    updateSectionChestCountFromByteAndFlag(segment, "@Belari/Belari Bomb Bag", 0x2002ea5, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Carlov/Carlov", 0x2002ea5, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Crenel Business Scrub/Crenel Business Scrub", 0x2002ea5, 0x04)
    updateSectionChestCountFromByteAndFlag(segment, "@Swiftblade's Dojo/Spin Attack", 0x2002ea5, 0x10)
    updateSectionChestCountFromByteAndFlag(segment, "@Swiftblade's Dojo/Rock Breaker", 0x2002ea5, 0x20)
    updateSectionChestCountFromByteAndFlag(segment, "@Swiftblade's Dojo/Dash Attack", 0x2002ea5, 0x40)
    updateSectionChestCountFromByteAndFlag(segment, "@Swiftblade's Dojo/Down Thrust", 0x2002ea5, 0x80)
    updateSectionChestCountFromByteAndFlag(segment, "@Grayblade/Scroll", 0x2002ea6, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Grimblade/Scroll", 0x2002ea6, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Waveblade/Scroll", 0x2002ea6, 0x04)
    updateSectionChestCountFromByteAndFlag(segment, "@Swiftblade the First/Scroll", 0x2002ea6, 0x08)
    updateSectionChestCountFromByteAndFlag(segment, "@Waterfall/Scarblade", 0x2002ea6, 0x10)
    updateSectionChestCountFromByteAndFlag(segment, "@Lower Veil Falls Waterfall/Splitblade", 0x2002ea6, 0x20)
    updateSectionChestCountFromByteAndFlag(segment, "@North Field Waterfall/Greatblade", 0x2002ea6, 0x40)
    updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Left (80 Rupees)", 0x2002ea7, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Middle (300 Rupees)", 0x2002ea7, 0x02)
    updateSectionChestCountFromByteAndFlag(segment, "@Stockwell's Shop/Right (600 Rupees)", 0x2002ea7, 0x04)
    updateSectionChestCountFromByteAndFlag(segment, "@Wind Ruins Joy Butterfly/Joy Butterfly", 0x2002ea7, 0x08)
    updateSectionChestCountFromByteAndFlag(segment, "@Castor Wilds Joy Butterfly/Joy Butterfly", 0x2002ea7, 0x10)
    updateSectionChestCountFromByteAndFlag(segment, "@Royal Valley Joy Butterfly/Joy Butterfly", 0x2002ea7, 0x20)
    updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/2 Element", 0x2002ea7, 0x80)
    updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/3 Element", 0x2002ea8, 0x01)
    updateSectionChestCountFromByteAndFlag(segment, "@Dark Hyrule Castle/4 Element", 0x2002ea8, 0x02)
  end

  if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
    return true
  end
end

ScriptHost:AddMemoryWatch("TMC Locations and Bosses", 0x2002c81, 0x200, updateLocations)
ScriptHost:AddMemoryWatch("TMC Item Data", 0x2002b30, 0x45, updateItemsFromMemorySegment)
ScriptHost:AddMemoryWatch("TMC Item Upgrades", 0x2002ae4, 0x0c, updateGearFromMemory)
ScriptHost:AddMemoryWatch("Graveyard Key", 0x2002ac0, 0x01, graveKey)
ScriptHost:AddMemoryWatch("TMC Keys", 0x2002e9d, 0x16, updateKeys)
