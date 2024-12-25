NewRollframes = CreateFrame("Frame")
NewRollframes:RegisterEvent("VARIABLES_LOADED")
NewRollframes:RegisterEvent("PARTY_MEMBERS_CHANGED");
NewRollframes:SetScript("OnEvent", function()
  if event == "VARIABLES_LOADED" then
    NewRollframes:enable()
  elseif event == "PARTY_MEMBERS_CHANGED" then
    if not UnitAffectingCombat("player") then
      NewRollframes:GetPartyMemberClass()
    end
  end
end)

local partyMemberClass = {}
local classColor = {
  ["战士"] = { r = 0.78, g = 0.61, b = 0.43 },
  ["圣骑士"] = { r = 0.96, g = 0.55, b = 0.73 },
  ["猎人"] = { r = 0.67, g = 0.83, b = 0.45 },
  ["潜行者"] = { r = 1.0, g = 0.96, b = 0.41 },
  ["牧师"] = { r = 1.0, g = 1.0, b = 1.0 },
  ["萨满祭司"] = { r = 0.0, g = 0.44, b = 0.87 },
  ["法师"] = { r = 0.25, g = 0.78, b = 0.92 },
  ["术士"] = { r = 0.53, g = 0.53, b = 0.93 },
  ["德鲁伊"] = { r = 1.0, g = 0.49, b = 0.04 }
}
function NewRollframes:GetPartyMemberClass()
  partyMemberClass = {}
  local count = 0
  local unit = "party"
  if (GetNumPartyMembers() ~= 0) then
    if UnitInRaid("player") then
      count = GetNumRaidMembers();
      unit = "raid"
    else
      count = GetNumPartyMembers();
    end;
  end
  if count > 0 then
    for i = 1, count do
      partyMemberClass[UnitName(unit .. i)] = classColor[UnitClass(unit .. i)];
    end
  end
end

--[[
职业	      颜色(0.00 ~ 1.00)	    RGB(0 ~ 255)    十六进制
-----------------------------------------------------------
战士		0.78    0.61	0.43	198	155	109	    #C59A6C
圣骑士		0.96	0.55	0.73	244	140	186	    #F38BB9
猎人		0.67	0.83	0.45	170	211	114	    #A9D271
潜行者		1.00	0.96	0.41	255	244	104	    #FEF367
牧师		1.00	1.00	1.00	255	255	255	    #FEFEFE
死亡骑士    0.77	0.12	0.23	196	30	58	    #C31D39
萨满祭司	0.00	0.44	0.87	0	112	221	    #006FDC
法师		0.25	0.78	0.92	63	198	234	    #3EC5E9
术士		0.53	0.53	0.93	135	135	237	    #8686EC
武僧		0.00	1.00	0.59	0	255	150	    #00FE95
德鲁伊		1.00	0.49	0.04	255	124	10	    #FE7B09
恶魔猎手	0.64	0.19	0.79	163	48	201	    #A22FC8
唤魔师		0.20	0.58	0.50	51	147	127	    #33937F
 ]]


local sanitize_cache = {}
NewRollframes.SanitizePattern = function(pattern)
  if not sanitize_cache[pattern] then
    local ret = pattern
    -- escape magic characters
    ret = gsub(ret, "([%+%-%*%(%)%?%[%]%^])", "%%%1")
    -- remove capture indexes
    ret = gsub(ret, "%d%$", "")
    -- catch all characters
    ret = gsub(ret, "(%%%a)", "%(%1+%)")
    -- convert all %s to .+
    ret = gsub(ret, "%%s%+", ".+")
    -- set priority to numbers over strings
    ret = gsub(ret, "%(.%+%)%(%%d%+%)", "%(.-%)%(%%d%+%)")
    -- cache it
    sanitize_cache[pattern] = ret
  end

  return sanitize_cache[pattern]
end

local capture_cache = {}
NewRollframes.GetCaptures = function(pat)
  local r = capture_cache
  if not r[pat] then
    for a, b, c, d, e in gfind(gsub(pat, "%((.+)%)", "%1"), gsub(pat, "%d%$", "%%(.-)$")) do
      r[pat] = { a, b, c, d, e }
    end
  end

  if not r[pat] then return nil, nil, nil, nil end
  return r[pat][1], r[pat][2], r[pat][3], r[pat][4], r[pat][5]
end

NewRollframes.cmatch = function(str, pat)
  -- read capture indexes
  local a, b, c, d, e = NewRollframes.GetCaptures(pat)
  local _, _, va, vb, vc, vd, ve = string.find(str, NewRollframes.SanitizePattern(pat))

  -- put entries into the proper return values
  local ra, rb, rc, rd, re
  ra = e == "1" and ve or d == "1" and vd or c == "1" and vc or b == "1" and vb or va
  rb = e == "2" and ve or d == "2" and vd or c == "2" and vc or a == "2" and va or vb
  rc = e == "3" and ve or d == "3" and vd or a == "3" and va or b == "3" and vb or vc
  rd = e == "4" and ve or a == "4" and va or c == "4" and vc or b == "4" and vb or vd
  re = a == "5" and va or d == "5" and vd or c == "5" and vc or b == "5" and vb or ve

  return ra, rb, rc, rd, re
end

NewRollframes.GetExpansion = function()
  local _, _, _, client = GetBuildInfo()
  client = client or 11200

  -- detect client expansion
  if client >= 20000 and client <= 20400 then
    return "tbc"
  elseif client >= 30000 and client <= 30300 then
    return "wotlk"
  else
    return "vanilla"
  end
end

NewRollframes.GetGlobalEnv = function()
  if NewRollframes.GetExpansion() == 'vanilla' then
    return getfenv(0)
  else
    return _G or getfenv(0)
  end
end

NewRollframes.enable = function(self)
  local _G = NewRollframes.GetGlobalEnv()
  local font_default, font_size = "Fonts\\ARIALN.TTF", 14

  NewRollframes.roll = CreateFrame("Frame", "STLootRoll", UIParent)
  NewRollframes.roll.frames = {}

  -- squash vanilla item placeholders
  local LOOT_ROLL_GREED = string.gsub(LOOT_ROLL_GREED, "%%s|Hitem:%%d:%%d:%%d:%%d|h%[%%s%]|h%%s", "%%s")
  local LOOT_ROLL_NEED = string.gsub(LOOT_ROLL_NEED, "%%s|Hitem:%%d:%%d:%%d:%%d|h%[%%s%]|h%%s", "%%s")
  local LOOT_ROLL_PASSED = string.gsub(LOOT_ROLL_PASSED, "%%s|Hitem:%%d:%%d:%%d:%%d|h%[%%s%]|h%%s", "%%s")

  -- try to detect the everyone string
  local _, _, everyone, _ = strfind(LOOT_ROLL_ALL_PASSED, LOOT_ROLL_PASSED)
  NewRollframes.roll.blacklist = { YOU, everyone }

  NewRollframes.roll.cache = {}

  NewRollframes.roll.scan = CreateFrame("Frame", "STLootRollMonitor", UIParent)
  NewRollframes.roll.scan:RegisterEvent("CHAT_MSG_LOOT")
  NewRollframes.roll.scan:SetScript("OnEvent", function()
    local player, item = NewRollframes.cmatch(arg1, LOOT_ROLL_GREED)
    if player and item then
      NewRollframes.roll:AddCache(item, player, "GREED")
      return
    end

    local player, item = NewRollframes.cmatch(arg1, LOOT_ROLL_NEED)
    if player and item then
      NewRollframes.roll:AddCache(item, player, "NEED")
      return
    end

    local player, item = NewRollframes.cmatch(arg1, LOOT_ROLL_PASSED)
    if player and item then
      NewRollframes.roll:AddCache(item, player, "PASS")
      return
    end
  end)

  function NewRollframes.roll:AddCache(hyperlink, name, roll)
    -- skip invalid names
    for _, invalid in pairs(NewRollframes.roll.blacklist) do
      if name == invalid then return end
    end

    local _, _, itemLink = string.find(hyperlink, "(item:%d+:%d+:%d+:%d+)")
    local itemName = GetItemInfo(itemLink)

    -- delete obsolete tables
    if NewRollframes.roll.cache[itemName] and NewRollframes.roll.cache[itemName]["TIMESTAMP"] < GetTime() - 60 then
      NewRollframes.roll.cache[itemName] = nil
    end

    -- initialize itemtable
    if not NewRollframes.roll.cache[itemName] then
      NewRollframes.roll.cache[itemName] = { ["GREED"] = {}, ["NEED"] = {}, ["PASS"] = {}, ["TIMESTAMP"] = GetTime() }
    end

    -- ignore already listed names
    for _, existing in pairs(NewRollframes.roll.cache[itemName][roll]) do
      if name == existing then return end
    end

    table.insert(NewRollframes.roll.cache[itemName][roll], name)

    for id = 1, 4 do
      if NewRollframes.roll.frames[id]:IsVisible() and NewRollframes.roll.frames[id].itemname == itemName then
        local count_greed = NewRollframes.roll.cache[itemName] and
            table.getn(NewRollframes.roll.cache[itemName]["GREED"]) or 0
        local count_need  = NewRollframes.roll.cache[itemName] and table.getn(NewRollframes.roll.cache[itemName]["NEED"]) or
        0
        local count_pass  = NewRollframes.roll.cache[itemName] and table.getn(NewRollframes.roll.cache[itemName]["PASS"]) or
        0
        NewRollframes.roll.frames[id].greed.count:SetText(count_greed > 0 and count_greed or "")
        NewRollframes.roll.frames[id].need.count:SetText(count_need > 0 and count_need or "")
        NewRollframes.roll.frames[id].pass.count:SetText(count_pass > 0 and count_pass or "")
      end
    end
  end

  function NewRollframes.roll:CreateLootRoll(id)
    local size = 20
    -- local rawborder, border = GetBorderSize()
    local border = 4
    local esize = 20
    local f = CreateFrame("Frame", "STLootRollFrame" .. id, UIParent)

    local function CreateBackdrop(f, b, a)
      if not f then return end
      f.backdrop = CreateFrame("Frame", nil, f)
      f.backdrop:SetPoint("TOPLEFT", f, "TOPLEFT", -b, b)
      f.backdrop:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", b, -b)
      f.backdrop:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
      })

      f.backdrop:SetBackdropColor(0, 0, 0, a)
      f.backdrop:SetBackdropBorderColor(1, 1, 1, a)
    end

    CreateBackdrop(f, border, .1)
    -- CreateBackdrop(f, nil, nil, .8)
    -- CreateBackdropShadow(f)
    f.backdrop:SetFrameStrata("BACKGROUND")
    f.hasItem = 1

    f:SetWidth(240)
    f:SetHeight(size)

    f.icon = CreateFrame("Button", "STLootRollFrame" .. id .. "Icon", f)
    CreateBackdrop(f.icon, border, .1)
    f.icon:SetPoint("LEFT", f, "LEFT", -30, 0)
    f.icon:SetWidth(esize * 1.2)
    f.icon:SetHeight(esize * 1.2)

    f.icon.tex = f.icon:CreateTexture("OVERLAY")
    f.icon.tex:SetTexCoord(.08, .92, .08, .92)
    f.icon.tex:SetAllPoints(f.icon)

    f.icon:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetLootRollItem(this:GetParent().rollID)
      CursorUpdate()
    end)

    f.icon:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    f.icon:SetScript("OnClick", function()
      if IsControlKeyDown() then
        DressUpItemLink(GetLootRollItemLink(this:GetParent().rollID))
      elseif IsShiftKeyDown() then
        if ChatEdit_InsertLink then
          ChatEdit_InsertLink(GetLootRollItemLink(this:GetParent().rollID))
        elseif ChatFrameEditBox:IsVisible() then
          ChatFrameEditBox:Insert(GetLootRollItemLink(this:GetParent().rollID))
        end
      end
    end)

    f.need = CreateFrame("Button", "STLootRollFrame" .. id .. "Need", f)
    f.need:SetPoint("LEFT", f.icon, "RIGHT", border * 3, -1)
    f.need:SetWidth(esize)
    f.need:SetHeight(esize)
    f.need:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
    f.need:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight")

    f.need.count = f.need:CreateFontString("NEED")
    f.need.count:SetPoint("CENTER", f.need, "CENTER", 0, 0)
    f.need.count:SetJustifyH("CENTER")
    f.need.count:SetFont(font_default, font_size, "OUTLINE")

    f.need:SetScript("OnClick", function()
      RollOnLoot(this:GetParent().rollID, 1)
    end)
    f.need:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("|cffffffff" .. NEED)
      if f.itemname and NewRollframes.roll.cache[f.itemname] then
        for _, player in pairs(NewRollframes.roll.cache[f.itemname]["NEED"]) do
          if not partyMemberClass[player] then
            GameTooltip:AddLine(player)
          else
            GameTooltip:AddLine(player, partyMemberClass[player].r, partyMemberClass[player].g,
              partyMemberClass[player].b)
          end
        end
      end
      GameTooltip:Show()
    end)
    f.need:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    f.greed = CreateFrame("Button", "STLootRollFrame" .. id .. "Greed", f)
    f.greed:SetPoint("LEFT", f.icon, "RIGHT", border * 7 + esize, -2)
    f.greed:SetWidth(esize)
    f.greed:SetHeight(esize)
    f.greed:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
    f.greed:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Highlight")

    f.greed.count = f.greed:CreateFontString("GREED")
    f.greed.count:SetPoint("CENTER", f.greed, "CENTER", 0, 1)
    f.greed.count:SetJustifyH("CENTER")
    f.greed.count:SetFont(font_default, font_size, "OUTLINE")

    f.greed:SetScript("OnClick", function()
      RollOnLoot(this:GetParent().rollID, 2)
    end)
    f.greed:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("|cffffffff" .. GREED)
      if f.itemname and NewRollframes.roll.cache[f.itemname] then
        for _, player in pairs(NewRollframes.roll.cache[f.itemname]["GREED"]) do
          if not partyMemberClass[player] then
            GameTooltip:AddLine(player)
          else
            GameTooltip:AddLine(player, partyMemberClass[player].r, partyMemberClass[player].g,
              partyMemberClass[player].b)
          end
        end
      end
      GameTooltip:Show()
    end)
    f.greed:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    f.pass = CreateFrame("Button", "STLootRollFrame" .. id .. "Pass", f)
    f.pass:SetPoint("LEFT", f.icon, "RIGHT", f:GetWidth() + border * 2, 0)   -- border * 7 + esize * 2, 0)
    f.pass:SetWidth(esize)
    f.pass:SetHeight(esize)
    f.pass:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    f.pass:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Highlight")

    f.pass.count = f.pass:CreateFontString("PASS")
    f.pass.count:SetPoint("CENTER", f.pass, "CENTER", 0, -1)
    f.pass.count:SetJustifyH("CENTER")
    f.pass.count:SetFont(font_default, font_size, "OUTLINE")

    f.pass:SetScript("OnClick", function()
      RollOnLoot(this:GetParent().rollID, 0)
    end)
    f.pass:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      GameTooltip:SetText("|cffffffff" .. PASS)
      if f.itemname and NewRollframes.roll.cache[f.itemname] then
        for _, player in pairs(NewRollframes.roll.cache[f.itemname]["PASS"]) do
          if not partyMemberClass[player] then
            GameTooltip:AddLine(player)
          else
            GameTooltip:AddLine(player, partyMemberClass[player].r, partyMemberClass[player].g,
              partyMemberClass[player].b)
          end
        end
      end
      GameTooltip:Show()
    end)
    f.pass:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)

    f.boe = CreateFrame("Frame", "STLootRollFrame" .. id .. "BOE", f)
    -- f.boe:SetPoint("LEFT", f.icon, "RIGHT", border*9+esize*3, 0)
    f.boe:SetPoint("RIGHT", f.icon, "LEFT", 5, 0)
    f.boe:SetWidth(esize * 3 + 10)
    f.boe:SetHeight(esize)
    f.boe.text = f.boe:CreateFontString("BOE")
    f.boe.text:SetAllPoints(f.boe)
    f.boe.text:SetJustifyH("LEFT")
    f.boe.text:SetFont(font_default, font_size, "OUTLINE")

    f.name = CreateFrame("Frame", "STLootRollFrame" .. id .. "Name", f)
    f.name:SetPoint("LEFT", f.icon, "RIGHT", border * 11 + esize * 4, 0)
    f.name:SetPoint("RIGHT", f, "RIGHT", border * 2, 0)
    f.name:SetHeight(esize)
    f.name.text = f.name:CreateFontString("NAME")
    -- f.name.text:SetAllPoints(f.name)
    f.name.text:SetPoint("LEFT", f.greed, "RIGHT", border, 0)
    f.name.text:SetJustifyH("LEFT")
    f.name.text:SetFont(font_default, font_size, "OUTLINE")

    f.time = CreateFrame("Frame", "STLootRollFrame" .. id .. "Time", f)
    f.time:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.time:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.time:SetFrameStrata("LOW")
    f.time.bar = CreateFrame("StatusBar", "STLootRollFrame" .. id .. "TimeBar", f.time)
    f.time.bar:SetAllPoints(f.time)
    -- f.time.bar:SetStatusBarTexture(pfUI.media["img:bar"])
    f.time.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.time.bar:SetMinMaxValues(0, 100)
    -- local r, g, b, a = strsplit(",", C.appearance.border.color)
    local r, g, b, a = 255 / 255, 210 / 255, 0 / 255, 1
    -- local r, g, b, a = 1, 1, 1, 1
    f.time.bar:SetStatusBarColor(r, g, b)
    f.time.bar:SetValue(20)
    f.time.bar:SetScript("OnUpdate", function()
      if not this:GetParent():GetParent().rollID then return end
      local left = GetLootRollTimeLeft(this:GetParent():GetParent().rollID)
      local min, max = this:GetMinMaxValues()
      if left < min or left > max then left = min end
      this:SetValue(left)
    end)

    return f
  end

  NewRollframes.roll:RegisterEvent("CANCEL_LOOT_ROLL")
  NewRollframes.roll:SetScript("OnEvent", function()
    for i = 1, 4 do
      if NewRollframes.roll.frames[i].rollID == arg1 then
        NewRollframes.roll.frames[i]:Hide()
      end
    end
  end)

  function _G.GroupLootFrame_OpenNewFrame(id, rollTime)
    -- clear cache if possible
    local visible = nil
    for i = 1, 4 do
      visible = visible or NewRollframes.roll.frames[i]:IsVisible()
    end
    if not visible then NewRollframes.roll.cache = {} end

    -- setup roll frames
    for i = 1, 4 do
      if not NewRollframes.roll.frames[i]:IsVisible() then
        NewRollframes.roll.frames[i].rollID = id
        NewRollframes.roll.frames[i].rollTime = rollTime
        NewRollframes.roll:UpdateLootRoll(i)
        return
      end
    end
  end

  function NewRollframes.roll:UpdateLootRoll(id)
    local texture, name, count, quality, bop = GetLootRollItemInfo(NewRollframes.roll.frames[id].rollID)
    local color                              = ITEM_QUALITY_COLORS[quality]

    NewRollframes.roll.frames[id].itemname   = name

    local count_greed                        = NewRollframes.roll.cache[name] and
        table.getn(NewRollframes.roll.cache[name]["GREED"]) or 0
    local count_need                         = NewRollframes.roll.cache[name] and
        table.getn(NewRollframes.roll.cache[name]["NEED"]) or 0
    local count_pass                         = NewRollframes.roll.cache[name] and
        table.getn(NewRollframes.roll.cache[name]["PASS"]) or 0

    NewRollframes.roll.frames[id].greed.count:SetText(count_greed > 0 and count_greed or "")
    NewRollframes.roll.frames[id].need.count:SetText(count_need > 0 and count_need or "")
    NewRollframes.roll.frames[id].pass.count:SetText(count_pass > 0 and count_pass or "")

    NewRollframes.roll.frames[id].name.text:SetText(name)
    NewRollframes.roll.frames[id].name.text:SetTextColor(color.r, color.g, color.b, 1)
    NewRollframes.roll.frames[id].icon.tex:SetTexture(texture)
    NewRollframes.roll.frames[id].backdrop:SetBackdropBorderColor(color.r, color.g, color.b)
    NewRollframes.roll.frames[id].time.bar:SetMinMaxValues(0, NewRollframes.roll.frames[id].rollTime)

    -- if C.loot.raritytimer == "1" then
    NewRollframes.roll.frames[id].time.bar:SetStatusBarColor(color.r, color.g, color.b, .5)
    -- end

    if bop then
      -- NewRollframes.roll.frames[id].boe.text:SetText(T["BoP"])
      NewRollframes.roll.frames[id].boe.text:SetText("拾取绑定")
      NewRollframes.roll.frames[id].boe.text:SetTextColor(1, .3, .3, 1)
    else
      -- NewRollframes.roll.frames[id].boe.text:SetText(T["BoE"])
      NewRollframes.roll.frames[id].boe.text:SetText("")
      NewRollframes.roll.frames[id].boe.text:SetTextColor(.3, 1, .3, 1)
    end

    NewRollframes.roll.frames[id]:Show()
  end

  for i = 1, 4 do
    if not NewRollframes.roll.frames[i] then
      NewRollframes.roll.frames[i] = NewRollframes.roll:CreateLootRoll(i)
      -- NewRollframes.roll.frames[i]:SetPoint("CENTER", 0, -i*35)
      NewRollframes.roll.frames[i]:SetPoint("CENTER", 15, i * 27 + 100)
      -- UpdateMovable(NewRollframes.roll.frames[i])
      NewRollframes.roll.frames[i]:Hide()
    end
  end
end
