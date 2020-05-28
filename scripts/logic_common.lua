function canDamage()
  if Tracker:ProviderCountForCode("sword") > 0 then
    return 1
  elseif Tracker:ProviderCountForCode("bow") > 0 then
    return 1
  elseif Tracker:ProviderCountForCode("lights") > 0 then
    return 1
  else
    return Tracker:ProviderCountForCode("bombs")
  end
end
function noGust()
  if Tracker:ProviderCountForCode("gust") == 0 then
    return 1
  else
    return 0
  end
end
function has7Scrolls()
a=0
  if Tracker:ProviderCountForCode("spinattack") > 0 then
    a=a+1
  end
  if Tracker:ProviderCountForCode("rockbreaker") > 0 then
    a=a+1
  end  
  if Tracker:ProviderCountForCode("dashattack") > 0 then
    a=a+1
  end  
  if Tracker:ProviderCountForCode("downthrust") > 0 then
    a=a+1
  end  
  if Tracker:ProviderCountForCode("rollattack") > 0 then
    a=a+1
  end  
  if Tracker:ProviderCountForCode("swordbeam") > 0 then
    a=a+1
  end  
  if Tracker:ProviderCountForCode("perilbeam") > 0 then
    a=a+1
  end
  if Tracker:ProviderCountForCode("greatspin") > 0 then
    a=a+1
  end
  if Tracker:ProviderCountForCode("fastspin") > 0 then
    a=a+1
  end
  if Tracker:ProviderCountForCode("longspin") > 0 then
    a=a+1
  end
  if Tracker:ProviderCountForCode("fastsplit") > 0 then
    a=a+1
  end
  if a > 6 then
    return 1
  else
    return 0
  end
end