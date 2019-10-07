local ADDON_NAME, ns = ...
local cargBags = ns.cargBags

-- Lua Globals --
-- luacheck: globals next ipairs

local Aurora = _G.Aurora
local Base = Aurora.Base

local cargBags_Nivaya = _G.CreateFrame("Frame", ADDON_NAME, _G.UIParent)
cargBags_Nivaya:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
cargBags_Nivaya:RegisterEvent("ADDON_LOADED")

local filters = ns.filters
local itemClass = ns.itemClass
local filterEnabled = ns.filterEnabled
ns.columns = {
    "right",
    "middle",
    "left"
}

local cbNivaya = cargBags:GetImplementation("Nivaya")

local cbNivDropdown
do  --Replacement for UIDropDownMenu
    local frameHeight = 14
    local defaultWidth = 120
    local frameInset = 16

    cbNivDropdown = _G.CreateFrame("Frame", "cbNivCatDropDown", _G.UIParent)
    cbNivDropdown.ActiveButtons = 0
    cbNivDropdown.Buttons = {}

    cbNivDropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    cbNivDropdown:SetSize(defaultWidth + frameInset, 32)
    cbNivDropdown:SetClampedToScreen(true)
    Base.SetBackdrop(cbNivDropdown)

    function cbNivDropdown:CreateButton()
        local button = _G.CreateFrame("Button", nil, self)
        button:SetWidth(defaultWidth)
        button:SetHeight(frameHeight)

        local fstr = button:CreateFontString()
        fstr:SetJustifyH("LEFT")
        fstr:SetJustifyV("MIDDLE")
        fstr:SetFontObject("SystemFont_Shadow_Med1")
        fstr:SetPoint("LEFT", button, "LEFT", 0, 0)
        button.Text = fstr

        function button:SetText(str)
            button.Text:SetText(str)
        end

        button:SetText("test")

        local ntex = button:CreateTexture()
        ntex:SetColorTexture(1,1,1,0)
        ntex:SetAllPoints()
        button:SetNormalTexture(ntex)

        local htex = button:CreateTexture()
        htex:SetColorTexture(1,1,1,0.2)
        htex:SetAllPoints()
        button:SetHighlightTexture(htex)

        local ptex = button:CreateTexture()
        ptex:SetColorTexture(1,1,1,0.4)
        ptex:SetAllPoints()
        button:SetPushedTexture(ptex)

        return button
    end

    function cbNivDropdown:AddButton(text, value, func)
        local bID = self.ActiveButtons+1

        local button = self.Buttons[bID] or self:CreateButton()

        button:SetText(text or "")
        button.value = value
        button.func = func or function() end

        button:SetScript("OnClick", function(btn, ...)
            btn:func(...)
            btn:GetParent():Hide()
        end)

        button:ClearAllPoints()
        if bID == 1 then
            button:SetPoint("TOP", self, "TOP", 0, -(frameInset/2))
        else
            button:SetPoint("TOP", self.Buttons[bID-1], "BOTTOM", 0, 0)
        end

        self.Buttons[bID] = button
        self.ActiveButtons = bID

        self:UpdateSize()
    end

    function cbNivDropdown:UpdatePosition(frame, point, relativepoint, ofsX, ofsY)
        point, relativepoint, ofsX, ofsY = point or "TOPLEFT", relativepoint or "BOTTOMLEFT", ofsX or 0, ofsY or 0

        self:ClearAllPoints()
        self:SetPoint(point, frame, relativepoint, ofsX, ofsY)
    end

    function cbNivDropdown:UpdateSize()
        local maxButtons = self.ActiveButtons
        local maxwidth = defaultWidth

        for i = 1, maxButtons do
            local width = self.Buttons[i].Text:GetWidth()
            if width > maxwidth then maxwidth = width end
        end

        for i = 1, maxButtons do
            self.Buttons[i]:SetWidth(maxwidth)
        end

        local height = maxButtons * frameHeight

        self:SetSize(maxwidth + frameInset, height + frameInset)
    end

    function cbNivDropdown:Toggle(frame, point, relativepoint, ofsX, ofsY)
        cbNivaya:CatDropDownInit()
        self:UpdatePosition(frame, point, relativepoint, ofsX, ofsY)
        self:Show()
    end

    ns.cbNivDropdown = cbNivDropdown
    _G.tinsert(_G.UISpecialFrames, cbNivDropdown:GetName())
end

---------------------------------------------
---------------------------------------------
local L = ns.L
local bags = ns.bags
local bagsHidden = ns.bagsHidden

-- Those are default values only, change them ingame via "/cbniv":
local optDefaults = {
    NewItems = true,
    Restack = true,
    TradeGoods = true,
    Armor = true,
    CoolStuff = false,
    Junk = true,
    ItemSets = true,
    Consumables = true,
    Quest = true,
    BankBlack = true,
    scale = 1,
    FilterBank = true,
    CompressEmpty = true,
    Unlocked = true,
    SortBags = true,
    SortBank = true,
    BankCustomBags = true,
    SellJunk = true,
    hasNewBags = false,
}

-- Those are internal settings, don't touch them at all:
local defaults = {}



function cbNivaya:ShowBags(...)
    local show = {...}
    for i = 1, #show do
        local bag = show[i]
        if not bagsHidden[bag.name] then
            bag:Show()
        end
    end
end
function cbNivaya:HideBags(...)
    local hide = {...}
    for i = 1, #hide do
        local bag = hide[i]
        bag:Hide()
    end
end

function cargBags_Nivaya:ADDON_LOADED(event, addon)

    if (addon ~= ADDON_NAME) then return end
    self:UnregisterEvent(event)

    -- Global saved vars
    _G.cB_CustomBags = _G.cB_CustomBags or {}
    _G.cBniv_CatInfo = _G.cBniv_CatInfo or {}
    _G.cBnivCfg = _G.cBnivCfg or {}
    for k, v in next, optDefaults do
        if _G.type(_G.cBnivCfg[k]) == "nil" then _G.cBnivCfg[k] = v end
    end

    -- Character saved vars
    if _G.cB_KnownItems then
        _G.cB_KnownItems = nil
    end
    _G.cBniv = _G.cBniv or {}
    for k, v in next, defaults do
        if _G.type(_G.cBniv[k]) == "nil" then _G.cBniv[k] = v end
    end

    filterEnabled["Armor"] = _G.cBnivCfg.Armor
    filterEnabled["TradeGoods"] = _G.cBnivCfg.TradeGoods
    filterEnabled["Junk"] = _G.cBnivCfg.Junk
    filterEnabled["ItemSets"] = _G.cBnivCfg.ItemSets
    filterEnabled["Consumables"] = _G.cBnivCfg.Consumables
    filterEnabled["Quest"] = _G.cBnivCfg.Quest
    _G.cBniv.BankCustomBags = _G.cBnivCfg.BankCustomBags
    _G.cBniv.BagPos = true

    if not _G.cBnivCfg.hasNewBags then
        for i, name in next, {L.bagArchaeology, L.bagTabards, L.bagMechagon, L.bagTravel} do
            local found
            for _, bag in next, _G.cB_CustomBags do
                if bag.name == name then
                    found = true
                    break
                end
            end

            if not found then
                _G.tinsert(_G.cB_CustomBags, { name = name, col = 0, prio = 1, active = false })
            end
        end

        _G.cBnivCfg.hasNewBags = true
    end

    -----------------
    -- Frame Spawns
    -----------------
    local C = cbNivaya:GetContainerClass()

    -- bank bags
    bags.bankSets        = C:New("cBniv_BankSets")

    if _G.cBniv.BankCustomBags then
        for _, bag in ipairs(_G.cB_CustomBags) do
            local name = "Bank" .. bag.name
            bags[name] = C:New(name)
            bags[name]:SetExtendedFilter(filters.fItemClass, name)
            ns.existsBankBag[bag.name] = true
        end
    end

    bags.bankArmor       = C:New("cBniv_BankArmor")
    bags.bankConsumables = C:New("cBniv_BankCons")
    bags.bankBattlePet   = C:New("cBniv_BankPet")
    bags.bankQuest       = C:New("cBniv_BankQuest")
    bags.bankTrade       = C:New("cBniv_BankTrade")
    bags.bankReagent     = C:New("cBniv_BankReagent")
    bags.bank            = C:New("cBniv_Bank") -- NivayacBniv_Bank

    bags.bankSets        :SetMultipleFilters(true, filters.fBank, filters.fBankFilter, filters.fItemSets)
    bags.bankArmor       :SetExtendedFilter(filters.fItemClass, "BankArmor")
    bags.bankConsumables :SetExtendedFilter(filters.fItemClass, "BankConsumables")
    bags.bankBattlePet   :SetExtendedFilter(filters.fItemClass, "BankBattlePet")
    bags.bankQuest       :SetExtendedFilter(filters.fItemClass, "BankQuest")
    bags.bankTrade       :SetExtendedFilter(filters.fItemClass, "BankTradeGoods")
    bags.bankReagent     :SetMultipleFilters(true, filters.fBankReagent, filters.fHideEmpty)
    bags.bank            :SetMultipleFilters(true, filters.fBank, filters.fHideEmpty)

    -- inventory bags
    bags.key         = C:New("cBniv_Keyring")
    bags.bagItemSets = C:New("cBniv_ItemSets")
    bags.bagStuff    = C:New("cBniv_Stuff")

    for _, bag in ipairs(_G.cB_CustomBags) do
        if bag.prio > 0 then
            bags[bag.name] = C:New(bag.name, { isCustomBag = true } )
            bag.active = true
            filterEnabled[bag.name] = true
            bags[bag.name]:SetExtendedFilter(filters.fItemClass, bag.name)
        end
    end

    bags.bagJunk     = C:New("cBniv_Junk")
    bags.bagNew      = C:New("cBniv_NewItems")

    for _, bag in ipairs(_G.cB_CustomBags) do
        if bag.prio <= 0 then
            bags[bag.name] = C:New(bag.name, { isCustomBag = true } )
            bag.active = true
            filterEnabled[bag.name] = true
            bags[bag.name]:SetExtendedFilter(filters.fItemClass, bag.name)
        end
    end

    bags.armor       = C:New("cBniv_Armor")
    bags.quest       = C:New("cBniv_Quest")
    bags.consumables = C:New("cBniv_Consumables")
    bags.battlepet   = C:New("cBniv_BattlePet")
    bags.tradegoods  = C:New("cBniv_TradeGoods")
    bags.main        = C:New("cBniv_Bag") -- NivayacBniv_Bag

    bags.key         :SetExtendedFilter(filters.fItemClass, "Keyring")
    bags.bagItemSets :SetFilter(filters.fItemSets, true)
    bags.bagStuff    :SetExtendedFilter(filters.fItemClass, "Stuff")
    bags.bagJunk     :SetExtendedFilter(filters.fItemClass, "Junk")
    bags.bagNew      :SetFilter(filters.fNewItems, true)
    bags.armor       :SetExtendedFilter(filters.fItemClass, "Armor")
    bags.quest       :SetExtendedFilter(filters.fItemClass, "Quest")
    bags.consumables :SetExtendedFilter(filters.fItemClass, "Consumables")
    bags.battlepet   :SetExtendedFilter(filters.fItemClass, "BattlePet")
    bags.tradegoods  :SetExtendedFilter(filters.fItemClass, "TradeGoods")
    bags.main        :SetMultipleFilters(true, filters.fBags, filters.fHideEmpty)

    bags.main:SetPoint("BOTTOMRIGHT", -99, 26)
    bags.bank:SetPoint("TOPLEFT", 20, -20)

    cbNivaya:CreateAnchors()
    cbNivaya:Init()
    cbNivaya:ToggleBagPosButtons()
end

-----------------------------------------------
-- Store the anchoring order:
-- read: "tar" is anchored to "src" in the direction denoted by "dir".
-----------------------------------------------
local function CreateAnchorInfo(src, tar, dir)
    tar.AnchorTo = src
    tar.AnchorDir = dir
    if src then
        if not src.AnchorTargets then src.AnchorTargets = {} end
        src.AnchorTargets[tar] = true
    end
end
function cbNivaya:CreateAnchors()

    -- neccessary if this function is used to update the anchors:
    for name, bag in next, bags do
        if name ~= "main" or name ~= "bank" then
            bag:ClearAllPoints()
        end
        bag.AnchorTo = nil
        bag.AnchorDir = nil
        bag.AnchorTargets = nil
    end
    local ref = { [0] = 0, [1] = 0 }

    -- Main Anchors:
    CreateAnchorInfo(nil, bags.main, "Bottom")
    CreateAnchorInfo(nil, bags.bank, "Bottom")

    -- Bank Anchors:
    CreateAnchorInfo(bags.bank, bags.bankArmor, "Right")
    CreateAnchorInfo(bags.bankArmor, bags.bankSets, "Bottom")
    CreateAnchorInfo(bags.bankSets, bags.bankTrade, "Bottom")

    CreateAnchorInfo(bags.bank, bags.bankReagent, "Bottom")
    CreateAnchorInfo(bags.bankReagent, bags.bankConsumables, "Bottom")
    CreateAnchorInfo(bags.bankConsumables, bags.bankQuest, "Bottom")
    CreateAnchorInfo(bags.bankQuest, bags.bankBattlePet, "Bottom")

    -- Bank Custom Container Anchors:
    if _G.cBniv.BankCustomBags then
        for _, bag in ipairs(_G.cB_CustomBags) do
            if bag.active then
                local c = bag.col
                if ref[c] == 0 then ref[c] = (c == 0) and bags.bankBattlePet or bags.bankTrade end
                CreateAnchorInfo(ref[c], bags["Bank" .. bag.name], "Bottom")
                ref[c] = bags["Bank" .. bag.name]
            end
        end
    end

    -- Bag Anchors:
    CreateAnchorInfo(bags.main,          bags.key,            "Bottom")

    CreateAnchorInfo(bags.main,          bags.bagItemSets,    "Left")
    CreateAnchorInfo(bags.bagItemSets,   bags.armor,          "Top")
    CreateAnchorInfo(bags.armor,         bags.battlepet,      "Top")
    CreateAnchorInfo(bags.battlepet,     bags.bagStuff,       "Top")

    CreateAnchorInfo(bags.consumables,   bags.quest,          "Top")

    CreateAnchorInfo(bags.bagItemSets,   bags.bagJunk,        "Left")
    CreateAnchorInfo(bags.bagJunk,       bags.tradegoods,     "Top")
    CreateAnchorInfo(bags.tradegoods,    bags.consumables,    "Top")
    CreateAnchorInfo(bags.quest,         bags.bagNew,         "Top")

    -- Custom Container Anchors:
    ref[0], ref[1], ref[2] = 0, 0, 0
    for _, bag in ipairs(_G.cB_CustomBags) do
        if bag.active then
            local c = bag.col if ref[c] == 0 then ref[c] = (c == 0) and bags.main
            or (c == 1) and bags.bagStuff
            or (c == 2) and bags.bagNew or bags.quest or bags.consumables or bags.tradegoods end


            CreateAnchorInfo(ref[c], bags[bag.name], "Top")
            ref[c] = bags[bag.name]
        end
    end

    -- Finally update all anchors:
    for _, bag in next, bags do cbNivaya:UpdateAnchors(bag) end
end

function cbNivaya:UpdateAnchors(bag)
    if not bag.AnchorTargets then return end
    for target in next, bag.AnchorTargets do
        local anchorTo, direction = target.AnchorTo, target.AnchorDir
        if anchorTo then
            local isHidden = bagsHidden[anchorTo.name]
            target:ClearAllPoints()

            if not isHidden      and direction == "Top"    then target:SetPoint("BOTTOM", anchorTo, "TOP", 0, 9)
            elseif  isHidden     and direction == "Top"    then target:SetPoint("BOTTOM", anchorTo, "BOTTOM")
            elseif  not isHidden and direction == "Bottom" then target:SetPoint("TOP", anchorTo, "BOTTOM", 0, -9)
            elseif  isHidden     and direction == "Bottom" then target:SetPoint("TOP", anchorTo, "TOP")
            elseif  direction == "Left"  then target:SetPoint("BOTTOMRIGHT", anchorTo, "BOTTOMLEFT", -9, 0)
            elseif  direction == "Right" then target:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 9, 0)
            end
        end
    end
end

function cbNivaya:OnOpen()
    if not bags.main:GetPoint() then
        bags.main:SetPoint("BOTTOMRIGHT", -99, 26)
    end

    bags.main:Show()
    cbNivaya:ShowBags(bags.armor, bags.bagNew, bags.bagItemSets, bags.quest, bags.consumables, bags.battlepet,
                      bags.tradegoods, bags.bagStuff, bags.bagJunk)
    for _, bag in next, _G.cB_CustomBags do
        if bag.active then cbNivaya:ShowBags(bags[bag.name]) end
    end
end

function cbNivaya:OnClose()
    cbNivaya:HideBags(bags.main, bags.armor, bags.bagNew, bags.bagItemSets, bags.quest, bags.consumables, bags.battlepet,
                      bags.tradegoods, bags.bagStuff, bags.bagJunk, bags.key)
    for _, bag in ipairs(_G.cB_CustomBags) do
        if bag.active then cbNivaya:HideBags(bags[bag.name]) end
    end
end

function cbNivaya:OnBankOpened()
    if not bags.bank:GetPoint() then
        bags.bank:SetPoint("TOPLEFT", 20, -20)
    end

    bags.bank:Show()
    cbNivaya:ShowBags(bags.bankSets, bags.bankReagent, bags.bankArmor, bags.bankQuest, bags.bankTrade, bags.bankConsumables, bags.bankBattlePet)
    if _G.cBniv.BankCustomBags then
        for _, bag in ipairs(_G.cB_CustomBags) do
            if bag.active then cbNivaya:ShowBags(bags["Bank"..bag.name]) end
        end
    end
end

function cbNivaya:OnBankClosed()
    cbNivaya:HideBags(bags.bank, bags.bankSets, bags.bankReagent, bags.bankArmor, bags.bankQuest, bags.bankTrade, bags.bankConsumables, bags.bankBattlePet)
    if _G.cBniv.BankCustomBags then
        for _, bag in ipairs(_G.cB_CustomBags) do
            if bag.active then cbNivaya:HideBags(bags["Bank"..bag.name]) end
        end
    end
end

function cbNivaya:ToggleBagPosButtons()
    for _, bag in ipairs(_G.cB_CustomBags) do
        if bag.active then
            local b = bags[bag.name]
            if _G.cBniv.BagPos then
                b.rightBtn:Hide()
                b.leftBtn:Hide()
                b.downBtn:Hide()
                b.upBtn:Hide()
            else
                b.rightBtn:Show()
                b.leftBtn:Show()
                b.downBtn:Show()
                b.upBtn:Show()
            end
        end
    end
    _G.cBniv.BagPos = not _G.cBniv.BagPos
end

local SetFrameMovable = function(f, isUnlocked)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:RegisterForClicks("LeftButton", "RightButton")
    if isUnlocked then
        f:SetScript("OnMouseDown", function()
            f:ClearAllPoints()
            f:StartMoving()
        end)
        f:SetScript("OnMouseUp",  f.StopMovingOrSizing)
    else
        f:SetScript("OnMouseDown", nil)
        f:SetScript("OnMouseUp", nil)
    end
end

local DropDownInitialized
function cbNivaya:CatDropDownInit()
    if DropDownInitialized then return end
    DropDownInitialized = true
    local info = {}--UIDropDownMenu_CreateInfo()

    local function AddInfoItem(type)
        local caption = "cBniv_"..type
        local t = L.bagCaptions[caption] or L[type]
        info.text = t and t or type
        info.value = type

        if (type == "-------------") or (type == _G.CANCEL) then
            info.func = nil
        else
            info.func = function(dropdown)
                cbNivaya:CatDropDownOnClick(dropdown, type)
            end
        end

        cbNivDropdown:AddButton(info.text, type, info.func)
    end

    AddInfoItem("ResetCategory")
    AddInfoItem("-------------")
    AddInfoItem("Armor")
    AddInfoItem("BattlePet")
    AddInfoItem("Consumables")
    AddInfoItem("Quest")
    AddInfoItem("TradeGoods")
    AddInfoItem("Stuff")
    AddInfoItem("Junk")
    AddInfoItem("Bag")
    AddInfoItem("-------------")

    local numActive = 0
    _G.table.sort(_G.cB_CustomBags, function(a, b)
        return a.name < b.name
    end)
    for _, bag in ipairs(_G.cB_CustomBags) do
        if bag.active then
            numActive = numActive + 1
            AddInfoItem(bag.name)
        end
    end
    if numActive > 0 then
        AddInfoItem("-------------")
    end
    AddInfoItem(_G.CANCEL)

    _G.hooksecurefunc(bags.main, "Hide", function() cbNivDropdown:Hide() end)
end

function cbNivaya:CatDropDownOnClick(dropdown, type)
    local value = dropdown.value
    local itemID = cbNivDropdown.itemID

    if (type == "ResetCategory") then
        _G.cBniv_CatInfo[itemID] = nil
    else
        _G.cBniv_CatInfo[itemID] = value
        if itemID ~= nil then itemClass[itemID] = nil end
    end
    cbNivaya:UpdateAll()
end

local function StatusMsg(str1, str2, data, name, short)
    local R,G,t = "|cFFFF0000", "|cFF00FF00", ""
    if (data ~= nil) then t = data and G..(short and "on|r" or "enabled|r") or R..(short and "off|r" or "disabled|r") end
    t = (name and "|cFFFFFF00cargBags_Nivaya:|r " or "")..str1..t..str2
    _G.ChatFrame1:AddMessage(t)
end

local function StatusMsgVal(str1, str2, data, name)
    local G,t = "|cFF00FF00", ""
    if (data ~= nil) then t = G..data.."|r" end
    t = (name and "|cFFFFFF00cargBags_Nivaya:|r " or "")..str1..t..str2
    _G.ChatFrame1:AddMessage(t)
end

local function AddBag(name, silent)
    if bags[name] then
        if not silent then
            StatusMsg("A container with this name already exists.", "", nil, true, false)
        end
    else
        _G.tinsert(_G.cB_CustomBags, { name = name, col = 0, prio = 1, active = false })
        if not silent then
            StatusMsg("The new custom container has been created", ". Reload your UI for this change to take effect!", nil, true, false)
        end
    end
end
local function HandleSlash(msg)
    local str, str2 = _G.strsplit(" ", msg, 2)
    local updateBags

    if ((str == "addbag") or (str == "delbag") or (str == "movebag") or (str == "bagprio") or (str == "orderup") or (str == "orderdn")) and (not str2) then
        StatusMsg("You have to specify a name, e.g. /cbniv "..str.." TestBag.", "", nil, true, false)
        return false
    end

    local numBags, idx = 0, -1
    for i,v in ipairs(_G.cB_CustomBags) do
        numBags = numBags + 1
        if v.name == str2 then idx = i end
    end

    if ((str == "delbag") or (str == "movebag") or (str == "bagprio") or (str == "orderup") or (str == "orderdn")) and (idx == -1) then
        StatusMsg("There is no custom container named |cFF00FF00"..str2, "|r.", nil, true, false)
        return false
    end

    if str == "new" then
        _G.cBnivCfg.NewItems = not _G.cBnivCfg.NewItems
        StatusMsg("The \"New Items\" filter is now ", ".", _G.cBnivCfg.NewItems, true, false)
        updateBags = true
    elseif str == "trade" then
        _G.cBnivCfg.TradeGoods = not _G.cBnivCfg.TradeGoods
        filterEnabled["TradeGoods"] = _G.cBnivCfg.TradeGoods
        StatusMsg("The \"Trade Goods\" filter is now ", ".", _G.cBnivCfg.TradeGoods, true, false)
        updateBags = true
    elseif str == "armor" then
        _G.cBnivCfg.Armor = not _G.cBnivCfg.Armor
        filterEnabled["Armor"] = _G.cBnivCfg.Armor
        StatusMsg("The \"Armor and Weapons\" filter is now ", ".", _G.cBnivCfg.Armor, true, false)
        updateBags = true
    elseif str == "junk" then
        _G.cBnivCfg.Junk = not _G.cBnivCfg.Junk
        filterEnabled["Junk"] = _G.cBnivCfg.Junk
        StatusMsg("The \"Junk\" filter is now ", ".", _G.cBnivCfg.Junk, true, false)
        updateBags = true
    elseif str == "sets" then
        _G.cBnivCfg.ItemSets = not _G.cBnivCfg.ItemSets
        filterEnabled["ItemSets"] = _G.cBnivCfg.ItemSets
        StatusMsg("The \"ItemSets\" filters are now ", ".", _G.cBnivCfg.ItemSets, true, false)
        updateBags = true
    elseif str == "consumables" then
        _G.cBnivCfg.Consumables = not _G.cBnivCfg.Consumables
        filterEnabled["Consumables"] = _G.cBnivCfg.Consumables
        StatusMsg("The \"Consumables\" filters are now ", ".", _G.cBnivCfg.Consumables, true, false)
        updateBags = true
    elseif str == "quest" then
        _G.cBnivCfg.Quest = not _G.cBnivCfg.Quest
        filterEnabled["Quest"] = _G.cBnivCfg.Quest
        StatusMsg("The \"Quest\" filters are now ", ".", _G.cBnivCfg.Quest, true, false)
        updateBags = true
    elseif str == "bankbg" then
        _G.cBnivCfg.BankBlack = not _G.cBnivCfg.BankBlack
        StatusMsg("Black background color for the bank is now ", ". Reload your UI for this change to take effect!", _G.cBnivCfg.BankBlack, true, false)
    elseif str == "bankfilter" then
        _G.cBnivCfg.FilterBank = not _G.cBnivCfg.FilterBank
        StatusMsg("Bank filtering is now ", ". Reload your UI for this change to take effect!", _G.cBnivCfg.FilterBank, true, false)
    elseif str == "empty" then
        _G.cBnivCfg.CompressEmpty = not _G.cBnivCfg.CompressEmpty
        if _G.cBnivCfg.CompressEmpty then
            bags.bank.DropTarget:Show()
            bags.main.DropTarget:Show()
            bags.main.EmptySlotCounter:Show()
            bags.bank.EmptySlotCounter:Show()
        else
            bags.bank.DropTarget:Hide()
            bags.main.DropTarget:Hide()
            bags.main.EmptySlotCounter:Hide()
            bags.bank.EmptySlotCounter:Hide()
        end
        StatusMsg("Empty bagspace compression is now ", ".", _G.cBnivCfg.CompressEmpty, true, false)
        updateBags = true
    elseif str == "unlock" then
        _G.cBnivCfg.Unlocked = not _G.cBnivCfg.Unlocked
        SetFrameMovable(bags.main, _G.cBnivCfg.Unlocked)
        SetFrameMovable(bags.bank, _G.cBnivCfg.Unlocked)
        StatusMsg("Movable bags are now ", ".", _G.cBnivCfg.Unlocked, true, false)
        updateBags = true
    elseif str == "sortbags" then
        _G.cBnivCfg.SortBags = not _G.cBnivCfg.SortBags
        StatusMsg("Auto sorting bags is now ", ". Reload your UI for this change to take effect!", _G.cBnivCfg.SortBags, true, false)
    elseif str == "sortbank" then
        _G.cBnivCfg.SortBank = not _G.cBnivCfg.SortBank
        StatusMsg("Auto sorting bank is now ", ". Reload your UI for this change to take effect!", _G.cBnivCfg.SortBank, true, false)

    elseif str == "scale" then
        local scale = _G.tonumber(str2)
        if scale then
            _G.cBnivCfg.scale = scale
            for _, bag in next, bags do bag:SetScale(scale) end
            StatusMsgVal("Overall scale has been set to ", ".", scale, true)
        else
            StatusMsg("You have to specify a number, e.g. /cbniv scale 0.8.", "", nil, true, false)
        end

    elseif str == "addtrade" then
        AddBag(L.bagParts, true)
        AddBag(L.bagJewelcrafting, true)
        AddBag(L.bagCloth, true)
        AddBag(L.bagLeatherworking, true)
        AddBag(L.bagMetalStone, true)
        AddBag(L.bagCooking, true)
        AddBag(L.bagHerb, true)
        AddBag(L.bagElemental, true)
        AddBag(L.bagEnchanting, true)
        AddBag(L.bagInscription, true)
        StatusMsg("Trade Good categories have been added", ". Reload your UI for this change to take effect!", nil, true, false)
    elseif str == "addbag" then
        AddBag(str2)

    elseif str == "delall" then
        _G.cB_CustomBags = nil
        StatusMsg("All custom containers have been removed", ". Reload your UI for this change to take effect!", nil, true, false)
    elseif str == "delbag" then
        _G.tremove(_G.cB_CustomBags, idx)
        StatusMsg("The specified custom container has been removed", ". Reload your UI for this change to take effect!", nil, true, false)

    elseif str == "listbags" then
        if numBags == 0 then
            StatusMsgVal("There are ", " custom containers.", 0, true, false)
        else
            StatusMsgVal("There are ", " custom containers:", numBags, true, false)
            for i, v in ipairs(_G.cB_CustomBags) do
                StatusMsg(i..". "..v.name.." (|cFF00FF00"..ns.columns[v.col+1].."|r column, |cFF00FF00"..((v.prio == 1) and "high" or "low").."|r priority)", "", nil, true, false)
            end
        end

    elseif str == "bagpos" then
        cbNivaya:ToggleBagPosButtons()
        StatusMsg("Custom container movers are now ", ".", _G.cBniv.BagPos, true, false)

    elseif str == "bagprio" then
        local tprio = (_G.cB_CustomBags[idx].prio + 1) % 2
        _G.cB_CustomBags[idx].prio = tprio
        StatusMsg("The priority of the specified custom container has been set to |cFF00FF00"..((tprio == 1) and "high" or "low").."|r. Reload your UI for this change to take effect!", "", nil, true, false)

    elseif str == "bankbags" then
        _G.cBnivCfg.BankCustomBags = not _G.cBnivCfg.BankCustomBags
        StatusMsg("Display of custom containers in the bank is now ", ". Reload your UI for this change to take effect!", _G.cBnivCfg.BankCustomBags, true, false)

    -- /cbniv ? Item Name OR item number
    -- Returns detailed information about the item in question
    elseif str == "?" and str2 then
        local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = _G.GetItemInfo(str2)
        _G.print("Item Name:",itemName,"(",itemLink,") (Rarity: (",itemRarity,")) level:",itemLevel," minimum level:",itemMinLevel," type:",itemType,":",itemSubType," count:",itemStackCount," equipped:",itemEquipLoc," sell price:",itemSellPrice," Item texture:",itemTexture)

    else
        _G.ChatFrame1:AddMessage("|cFFFFFF00cargBags_Nivaya:|r")
        StatusMsg("(", ") |cFFFFFF00unlock|r - Toggle unlocked status.", _G.cBnivCfg.Unlocked, false, true)
        StatusMsg("(", ") |cFFFFFF00new|r - Toggle the \"New Items\" filter.", _G.cBnivCfg.NewItems, false, true)
        StatusMsg("(", ") |cFFFFFF00trade|r - Toggle the \"Trade Goods\" filter .", _G.cBnivCfg.TradeGoods, false, true)
        StatusMsg("(", ") |cFFFFFF00armor|r - Toggle the \"Armor and Weapons\" filter .", _G.cBnivCfg.Armor, false, true)
        StatusMsg("(", ") |cFFFFFF00junk|r - Toggle the \"Junk\" filter.", _G.cBnivCfg.Junk, false, true)
        StatusMsg("(", ") |cFFFFFF00sets|r - Toggle the \"ItemSets\" filters.", _G.cBnivCfg.ItemSets, false, true)
        StatusMsg("(", ") |cFFFFFF00consumables|r - Toggle the \"Consumables\" filters.", _G.cBnivCfg.Consumables, false, true)
        StatusMsg("(", ") |cFFFFFF00quest|r - Toggle the \"Quest\" filters.", _G.cBnivCfg.Quest, false, true)
        StatusMsg("(", ") |cFFFFFF00bankbg|r - Toggle black bank background color.", _G.cBnivCfg.BankBlack, false, true)
        StatusMsg("(", ") |cFFFFFF00bankfilter|r - Toggle bank filtering.", _G.cBnivCfg.FilterBank, false, true)
        StatusMsg("(", ") |cFFFFFF00empty|r - Toggle empty bagspace compression.", _G.cBnivCfg.CompressEmpty, false, true)
        StatusMsg("(", ") |cFFFFFF00sortbags|r - Toggle auto sorting the bags.", _G.cBnivCfg.SortBags, false, true)
        StatusMsg("(", ") |cFFFFFF00sortbank|r - Toggle auto sorting the bank.", _G.cBnivCfg.SortBank, false, true)
        StatusMsgVal("(", ") |cFFFFFF00scale|r [number] - Set the overall scale.", _G.cBnivCfg.scale, false)
        StatusMsg("", " |cFFFFFF00addtrade|r - Add bags for specific Trade Good sub categories.")
        StatusMsg("", " |cFFFFFF00addbag|r [name] - Add a custom container.")
        StatusMsg("", " |cFFFFFF00delall|r - Remove all custom containers.")
        StatusMsg("", " |cFFFFFF00delbag|r [name] - Remove a custom container.")
        StatusMsg("", " |cFFFFFF00listbags|r - List all custom containers.")
        StatusMsg("", " |cFFFFFF00bagpos|r - Toggle buttons to move custom containers (up, down, left, right).")
        StatusMsg("", " |cFFFFFF00bagprio|r [name] - Changes the filter priority of a custom container. High priority prevents items from being classified as junk or new, low priority doesn't.")
        StatusMsg("(", ") |cFFFFFF00bankbags|r - Show custom containers in the bank too.", _G.cBnivCfg.BankCustomBags, false, true)
    end

    if updateBags then
        cbNivaya:UpdateAll()
    end
end

_G.SLASH_CBNIV1 = '/cbniv'
_G.SlashCmdList.CBNIV = HandleSlash

local buttonCollector = {}
local Event =  _G.CreateFrame('Frame', nil)
Event:RegisterEvent("PLAYER_ENTERING_WORLD")
Event:SetScript('OnEvent', function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        for bagID = _G.KEYRING_CONTAINER, _G.NUM_BAG_SLOTS + _G.NUM_BANKBAGSLOTS do
            local slots = _G.GetContainerNumSlots(bagID)
            for slotID = 1, slots do
                local button = cbNivaya.buttonClass:New(bagID, slotID)
                buttonCollector[#buttonCollector+1] = button
                cbNivaya:SetButton(bagID, slotID, nil)
            end
        end
        for i,button in next, buttonCollector do
            if button.container then
                button.container:RemoveButton(button)
            end
            button:Free()
        end
        cbNivaya:UpdateAll()

        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
