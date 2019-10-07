local _, ns = ...
local cargBags = ns.cargBags

-- Lua Globals --
local next, ipairs = _G.next, _G.ipairs

local Aurora = _G.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin

local L = ns.L
local bags = ns.bags
local bagsHidden = ns.bagsHidden

local mediaPath = [[Interface\AddOns\cargBags_Nivaya\media\]]
local Textures = {
    Background =    mediaPath .. "texture",
    Search =        mediaPath .. "Search",
    BagToggle =     mediaPath .. "BagToggle",
    ResetNew =      mediaPath .. "ResetNew",
    Restack =       mediaPath .. "Restack",
    Config =        mediaPath .. "Config",
    SellJunk =      mediaPath .. "SellJunk",
    Deposit =       mediaPath .. "Deposit",
    TooltipIcon =   mediaPath .. "TooltipIcon",
    Up =            mediaPath .. "Up",
    Down =          mediaPath .. "Down",
    Left =          mediaPath .. "Left",
    Right =         mediaPath .. "Right",
}

local itemSlotSize = ns.options.itemSlotSize
------------------------------------------
-- MyContainer specific
------------------------------------------
local cbNivaya = cargBags:GetImplementation("Nivaya")
local MyContainer = cbNivaya:GetContainerClass()

local GetNumFreeSlots = function(bagType)
    local free, max = 0, 0
    if bagType == "bag" then
        for i = 0, 4 do
            free = free + _G.GetContainerNumFreeSlots(i)
            max = max + _G.GetContainerNumSlots(i)
        end
    elseif bagType == "bankReagent" then
        free = _G.GetContainerNumFreeSlots(-3)
        max = _G.GetContainerNumSlots(-3)
    else
        local containerIDs = {-1,5,6,7,8,9,10,11}
        for _, i in next, containerIDs do
            free = free + _G.GetContainerNumFreeSlots(i)
            max = max + _G.GetContainerNumSlots(i)
        end
    end
    return free, max
end

local QuickSort, invTypes
do
    invTypes = {
        INVTYPE_HEAD        = 1,
        INVTYPE_NECK        = 2,
        INVTYPE_SHOULDER    = 3,
        INVTYPE_CLOAK       = 4,
        INVTYPE_CHEST       = 5,
        INVTYPE_ROBE        = 5, -- Holiday chest
        INVTYPE_BODY        = 6, -- Shirt
        INVTYPE_TABARD      = 7,
        INVTYPE_WRIST       = 8,
        INVTYPE_HAND        = 9,
        INVTYPE_WAIST       = 10,
        INVTYPE_LEGS        = 11,
        INVTYPE_FEET        = 12,
        INVTYPE_FINGER      = 13,
        INVTYPE_TRINKET     = 14,

        INVTYPE_2HWEAPON    = 15,
        INVTYPE_RANGED      = 16, -- Bows
        INVTYPE_RANGEDRIGHT = 16, -- Wands, Guns, and Crossbows

        INVTYPE_WEAPON      = 17, -- One-Hand
        INVTYPE_WEAPONMAINHAND = 18,
        INVTYPE_WEAPONOFFHAND = 19,
        INVTYPE_SHIELD      = 20,
        INVTYPE_HOLDABLE    = 21,

        INVTYPE_AMMO        = 22,

        INVTYPE_BAG         = 25
    }
    local func = function(v1, v2)
        local item1, item2 = v1[1], v2[1]
        if (item1 == nil) or (item2 == nil) then return not not item1 end

        -- higher quality first
        if item1.rarity ~= item2.rarity then
            if item1.rarity and item2.rarity then
                return item1.rarity > item2.rarity
            elseif (item1.rarity == nil) or (item2.rarity == nil) then
                return not not item1.rarity
            else
                return false
            end
        end

        -- group item types
        if item1.typeID ~= item2.typeID then
            return item1.typeID > item2.typeID
        elseif item1.subTypeID ~= item2.subTypeID then
            return item1.subTypeID > item2.subTypeID
        end

        -- group equipment types
        if (item1.equipLoc ~= "" and item2.equipLoc ~= "") and (item1.equipLoc ~= item2.equipLoc) then
            if not invTypes[item1.equipLoc] or not invTypes[item2.equipLoc] then
                _G.print("Compairing unknown slot", item1.link, item1.equipLoc, item2.link, item2.equipLoc)
            else
                return invTypes[item1.equipLoc] < invTypes[item2.equipLoc]
            end
        end

        -- group same items
        if item1.id ~= item2.id then
            return item1.id > item2.id
        end

        -- sort larger stacks first
        if item1.count and item2.count then
            return item1.count > item2.count
        end
    end;
    QuickSort = function(tbl) _G.table.sort(tbl, func) end
end

function MyContainer:OnContentsChanged()
    cargBags.debug("style MyContainer:OnContentsChanged", self.name)

    local col, row = 0, 0
    local yPosOffs = self.Caption and 20 or 0
    local isEmpty = true

    local tName = self.name
    local tBankBags = tName:find("cBniv_Bank%a+")
    local tBank = tBankBags or (tName == "cBniv_Bank")
    local tReagent = (tName == "cBniv_BankReagent")

    local buttonIDs = {}
    for i, button in next, self.buttons do
        local item = cbNivaya:GetItem(button.bagID, button.slotID)
        if item.link then
            if (item.equipLoc and item.equipLoc ~= "") and not invTypes[item.equipLoc] then
                _G.print("Unknown slot", item.link, item.equipLoc)
            end
            buttonIDs[i] = { item, button }
        else
            buttonIDs[i] = { nil, button }
        end
    end
    if ((tBank or tReagent) and _G.cBnivCfg.SortBank) or (not (tBank or tReagent) and _G.cBnivCfg.SortBags) then QuickSort(buttonIDs) end

    for _, v in ipairs(buttonIDs) do
        local button = v[2]
        button:ClearAllPoints()

        local xPos = col * (itemSlotSize + 2) + 2
        local yPos = (-1 * row * (itemSlotSize + 2)) - yPosOffs

        button:SetPoint("TOPLEFT", self, "TOPLEFT", xPos, yPos)
        if col >= (self.Columns - 1) then
            col = 0
            row = row + 1
        else
            col = col + 1
        end
        isEmpty = false
    end

    if _G.cBnivCfg.CompressEmpty then
        local xPos = col * (itemSlotSize + 2) + 2
        local yPos = (-1 * row * (itemSlotSize + 2)) - yPosOffs

        local tDrop = self.DropTarget
        if tDrop then
            tDrop:ClearAllPoints()
            tDrop:SetPoint("TOPLEFT", self, "TOPLEFT", xPos, yPos)
            if col >= (self.Columns - 1) then
                col = 0
                row = row + 1
            else
                col = col + 1
            end
        end

        bags.main.EmptySlotCounter:SetText(GetNumFreeSlots("bag"))
        bags.bank.EmptySlotCounter:SetText(GetNumFreeSlots("bank"))
        bags.bankReagent.EmptySlotCounter:SetText(GetNumFreeSlots("bankReagent"))
    end

    -- This variable stores the size of the item button container
    self.ContainerHeight = (row + (col > 0 and 1 or 0)) * (itemSlotSize + 2)

    if (self.UpdateDimensions) then self:UpdateDimensions() end -- Update the bag's height
    local t = (tName == "cBniv_Bag") or (tName == "cBniv_Bank") or (tName == "cBniv_BankReagent")
    local tAS = (tName == "cBniv_Ammo") or (tName == "cBniv_Soulshards")
    if (not tBankBags and bags.main:IsShown() and not (t or tAS)) or (tBankBags and bags.bank:IsShown()) then
        if isEmpty then self:Hide() else self:Show() end
    end

    bagsHidden[tName] = (not t) and isEmpty or false
    cbNivaya:UpdateAnchors(self)
end

--[[function MyContainer:OnButtonAdd(button)
    if not button.Border then return end

    local _,bagType = GetContainerNumFreeSlots(button.bagID)
    if button.bagID == KEYRING_CONTAINER then
        button.Border:SetBackdropBorderColor(0, 0, 0)     -- Key ring
    elseif bagType and bagType > 0 and bagType < 8 then
        button.Border:SetBackdropBorderColor(1, 1, 0)       -- Ammo bag
    elseif bagType and bagType > 4 then
        button.Border:SetBackdropBorderColor(1, 1, 1)       -- Profession bags
    else
        button.Border:SetBackdropBorderColor(0, 0, 0)       -- Normal bags
    end
end]]--

-- Sell Junk
local JS = _G.CreateFrame("Frame")
JS:RegisterEvent("MERCHANT_SHOW")
local function SellJunk()
    if not _G.cBnivCfg.SellJunk or _G.UnitLevel("player") < 5 then return end
    cargBags.debug("style SellJunk")

    local profit, soldCount = 0, 0
    local item

    for BagID = 0, 4 do
        for BagSlot = 1, _G.GetContainerNumSlots(BagID) do
            item = cbNivaya:GetItem(BagID, BagSlot)
            if item then
                if item.rarity == 0 and item.sellPrice ~= 0 then
                    if not item.count then
                        _G.print("Item has no count", item.name, item.id)
                    else
                        profit = profit + (item.sellPrice * item.count)
                        soldCount = soldCount + 1
                        _G.UseContainerItem(BagID, BagSlot)
                    end
                end
            end
        end
    end

    if profit > 0 then
        local money = _G.GetMoneyString(profit, true)
        _G.print("Vendor trash sold from", soldCount, "items: |cff00a956+|r"..money)
    end
end
JS:SetScript("OnEvent", SellJunk)

-- Restack Items
local function restackItems(self)
    local tBag, tBank = (self.name == "cBniv_Bag"), (self.name == "cBniv_Bank")
    --local loc = tBank and "bank" or "bags"
    if tBank then
        _G.SortBankBags()
        _G.SortReagentBankBags()
    elseif tBag then
        _G.SortBags()
    end
end

-- Reset New
local function resetNewItems(self)
    cargBags.debug("style resetNewItems")
    _G.wipe(ns.newItems)
    _G.C_NewItems.ClearAll()
    cbNivaya:UpdateAll()
end

local function UpdateDimensions(self)
    local height = 0            -- Normal margin space
    if self.BagBar and self.BagBar:IsShown() then
        height = height + 40    -- Bag button space
    end
    if self.Space then
        height = height + 16    -- additional info display space
    end
    if self.bagToggle then
        local tBag = (self.name == "cBniv_Bag")
        local extraHeight = (tBag and self.hintShown) and (self.hint:GetStringHeight() + 4) or 0
        height = height + 24 + extraHeight
    end
    if self.Caption then        -- Space for captions
        height = height + self.Caption:GetStringHeight() + 12
    end
    self:SetHeight(self.ContainerHeight + height)
end

local function SetFrameMovable(f, v)
    f:SetMovable(true)
    f:SetUserPlaced(true)
    f:RegisterForClicks("LeftButton", "RightButton")
    if v then
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

local function IconButton_OnEnter(self)
    self.mouseover = true
    self.icon:SetVertexColor(_G.RealUI.charInfo.class.color:GetRGB())

    if self.tooltip then
        self.tooltip:Show()
        self.tooltipIcon:Show()
    end
end

local function IconButton_OnLeave(self)
    self.mouseover = false
    if self.tag == "SellJunk" then
        if _G.cBnivCfg.SellJunk then
            self.icon:SetVertexColor(0.8, 0.8, 0.8)
        else
            self.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    else
        self.icon:SetVertexColor(0.8, 0.8, 0.8)
    end
    if self.tooltip then
        self.tooltip:Hide()
        self.tooltipIcon:Hide()
    end
end

local createMoverButton = function (parent, texture, tag)
    local button = _G.CreateFrame("Button", nil, parent)
    button:SetWidth(17)
    button:SetHeight(17)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
    button.icon:SetWidth(16)
    button.icon:SetHeight(16)
    button.icon:SetTexture(texture)
    button.icon:SetVertexColor(0.8, 0.8, 0.8)

    button.tag = tag
    button:SetScript("OnEnter", function() IconButton_OnEnter(button) end)
    button:SetScript("OnLeave", function() IconButton_OnLeave(button) end)
    button.mouseover = false

    return button
end

local createIconButton = function (name, parent, texture, point, hint, isBag)
    local button = _G.CreateFrame("Button", nil, parent)
    button:SetWidth(17)
    button:SetHeight(17)

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetPoint(point, button, point, point == "BOTTOMLEFT" and 2 or -2, 2)
    button.icon:SetWidth(16)
    button.icon:SetHeight(16)
    button.icon:SetTexture(texture)
    if name == "SellJunk" then
        if _G.cBnivCfg.SellJunk then
            button.icon:SetVertexColor(0.8, 0.8, 0.8)
        else
            button.icon:SetVertexColor(0.4, 0.4, 0.4)
        end
    else
        button.icon:SetVertexColor(0.8, 0.8, 0.8)
    end

    button.tooltip = button:CreateFontString()
    -- button.tooltip:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", isBag and -76 or -59, 4.5)
    button.tooltip:SetFontObject("SystemFont_Shadow_Med1")
    button.tooltip:SetJustifyH("RIGHT")
    button.tooltip:SetText(hint)
    button.tooltip:SetTextColor(0.8, 0.8, 0.8)
    button.tooltip:Hide()

    button.tooltipIcon = button:CreateTexture(nil, "ARTWORK")
    -- button.tooltipIcon:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", isBag and -71 or -54, 1)
    button.tooltipIcon:SetWidth(16)
    button.tooltipIcon:SetHeight(16)
    button.tooltipIcon:SetTexture(Textures.TooltipIcon)
    button.tooltipIcon:SetVertexColor(0.9, 0.2, 0.2)
    button.tooltipIcon:Hide()

    button.tag = name
    button:SetScript("OnEnter", function() IconButton_OnEnter(button) end)
    button:SetScript("OnLeave", function() IconButton_OnLeave(button) end)
    button.mouseover = false

    return button
end


local GetFirstFreeSlot = function(bagtype)
    if bagtype == "bag" then
        for bagID = 0, 4 do
            if _G.GetContainerNumFreeSlots(bagID) > 0 then
                local numSlots = _G.GetContainerNumSlots(bagID)
                for slotID = 1, numSlots do
                    local link = _G.GetContainerItemLink(bagID, slotID)
                    if not link then return bagID, slotID end
                end
            end
        end
    elseif bagtype == "bankReagent" then
        local bagID = -3
        if _G.GetContainerNumFreeSlots(bagID) > 0 then
            local numSlots = _G.GetContainerNumSlots(bagID)
            for slotID = 1, numSlots do
                local link = _G.GetContainerItemLink(bagID, slotID)
                if not link then return bagID, slotID end
            end
        end
    else
        local containerIDs = {-1,5,6,7,8,9,10,11}
        for _, bagID in next, containerIDs do
            if _G.GetContainerNumFreeSlots(bagID) > 0 then
                local numSlots = _G.GetContainerNumSlots(bagID)
                for slotID = 1, numSlots do
                    local link = _G.GetContainerItemLink(bagID, slotID)
                    if not link then return bagID, slotID end
                end
            end
        end
    end
    return false
end

function MyContainer:OnCreate(name, settings)
    --print("MyContainer:OnCreate", name)
    settings = settings or {}
    self.Settings = settings
    self.name = name

    local tBag, tBank, tReagent = (name == "cBniv_Bag"), (name == "cBniv_Bank"), (name == "cBniv_BankReagent")
    local tBankBags = name:find("Bank")

    local numSlotsBag = {GetNumFreeSlots("bag")}
    local numSlotsBank = {GetNumFreeSlots("bank")}
    local numSlotsReagent = {GetNumFreeSlots("bankReagent")}

    local usedSlotsBag = numSlotsBag[2] - numSlotsBag[1]
    local usedSlotsBank = numSlotsBank[2] - numSlotsBank[1]
    local usedSlotsReagent = numSlotsReagent[2] - numSlotsReagent[1]

    self:EnableMouse(true)

    self.UpdateDimensions = UpdateDimensions

    self:SetFrameStrata("HIGH")
    _G.tinsert(_G.UISpecialFrames, self:GetName()) -- Close on "Esc"

    if tBag or tBank then
        SetFrameMovable(self, _G.cBnivCfg.Unlocked)
    end

    if tBank or tBankBags then
        self.Columns = (usedSlotsBank > ns.options.sizes.bank.largeItemCount) and ns.options.sizes.bank.columnsLarge or ns.options.sizes.bank.columnsSmall
    elseif tReagent then
        self.Columns = (usedSlotsReagent > ns.options.sizes.bank.largeItemCount) and ns.options.sizes.bank.columnsLarge or ns.options.sizes.bank.columnsSmall
    else
        self.Columns = (usedSlotsBag > ns.options.sizes.bags.largeItemCount) and ns.options.sizes.bags.columnsLarge or ns.options.sizes.bags.columnsSmall
    end
    self.ContainerHeight = 0
    self:UpdateDimensions()
    self:SetWidth((itemSlotSize + 2) * self.Columns + 2)

    -- The frame background
    local background = _G.CreateFrame("Frame", nil, self)
    background:SetFrameStrata("HIGH")
    background:SetFrameLevel(1)
    background:SetPoint("TOPLEFT", -4, 4)
    background:SetPoint("BOTTOMRIGHT", 4, -4)
    Base.SetBackdrop(background)

    -- Caption, close button
    local caption = background:CreateFontString(background, "OVERLAY", nil)
    caption:SetFontObject("SystemFont_Shadow_Med1")
    if caption then
        local t = L.bagCaptions[self.name] or (tBankBags and self.name:sub(5))
        if not t then t = self.name end
        caption:SetText(t)
        caption:SetPoint("TOPLEFT", 7.5, -7.5)
        self.Caption = caption

        if tBag or tBank then
            local close = _G.CreateFrame("Button", nil, self, "UIPanelCloseButton")
            Skin.UIPanelCloseButton(close)
            close:SetPoint("TOPRIGHT", 10, 10)
            close:SetScript("OnClick", function(container)
                if cbNivaya:AtBank() then
                    _G.CloseBankFrame()
                else
                    _G.CloseAllBags()
                end
            end)
        end
    end

    -- mover buttons
    if settings.isCustomBag then
        local moveLR = function(dir)
            local idx = -1
            for i, bag in ipairs(_G.cB_CustomBags) do if bag.name == name then idx = i end end
            if idx == -1 then return end

            if dir == "left" then
                _G.cB_CustomBags[idx].col = (_G.cB_CustomBags[idx].col + 1) % #ns.columns
            else
                _G.cB_CustomBags[idx].col = (_G.cB_CustomBags[idx].col - 1) % #ns.columns
            end

            cbNivaya:CreateAnchors()
        end

        local moveUD = function(dir)
            local idx = -1
            for i, bag in ipairs(_G.cB_CustomBags) do if bag.name == name then idx = i end end
            if idx == -1 then return end

            local pos = idx
            local offset = (dir == "up") and 1 or -1
            repeat
                pos = pos + offset
            until
                (not _G.cB_CustomBags[pos]) or (_G.cB_CustomBags[pos].col == _G.cB_CustomBags[idx].col)

            if (_G.cB_CustomBags[pos] ~= nil) then
                local ele = _G.cB_CustomBags[idx]
                _G.cB_CustomBags[idx] = _G.cB_CustomBags[pos]
                _G.cB_CustomBags[pos] = ele
                cbNivaya:CreateAnchors()
            end
        end

        local rightBtn = createMoverButton(self, Textures.Right, "Right")
        rightBtn:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 0)
        rightBtn:SetScript("OnClick", function() moveLR("right") end)

        local leftBtn = createMoverButton(self, Textures.Left, "Left")
        leftBtn:SetPoint("TOPRIGHT", self, "TOPRIGHT", -17, 0)
        leftBtn:SetScript("OnClick", function() moveLR("left") end)

        local downBtn = createMoverButton(self, Textures.Down, "Down")
        downBtn:SetPoint("TOPRIGHT", self, "TOPRIGHT", -34, 0)
        downBtn:SetScript("OnClick", function() moveUD("down") end)

        local upBtn = createMoverButton(self, Textures.Up, "Up")
        upBtn:SetPoint("TOPRIGHT", self, "TOPRIGHT", -51, 0)
        upBtn:SetScript("OnClick", function() moveUD("up") end)

        self.rightBtn = rightBtn
        self.leftBtn = leftBtn
        self.downBtn = downBtn
        self.upBtn = upBtn
    end

    if tBag or tBank then
        -- Bag bar for changing bags
        local bagType = tBag and "backpack+bags" or "bank"
        local numBags = tBag and _G.NUM_BAG_SLOTS or _G.NUM_BANKBAGSLOTS

        local bagButtons = self:SpawnPlugin("BagBar", bagType)
        bagButtons:SetSize(bagButtons:LayoutButtons("grid", numBags))
        bagButtons.highlightFunction = function(button, match) button:SetAlpha(match and 1 or 0.1) end
        bagButtons.isGlobal = true

        bagButtons:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -2, 25)
        bagButtons:Hide()

        -- main window gets a fake bag button for toggling key ring
        self.BagBar = bagButtons

        -- We don't need the bag bar every time, so let's create a toggle button for them to show
        self.bagToggle = createIconButton("Bags", self, Textures.BagToggle, "BOTTOMRIGHT", "Toggle Bags", tBag)
        self.bagToggle:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
        self.bagToggle:SetScript("OnClick", function()
            if(self.BagBar:IsShown()) then
                self.BagBar:Hide()
            --  if self.hint then self.hint:Show() end
            --  self.hintShown = true
            else
                self.BagBar:Show()
            --  if self.hint then self.hint:Hide() end
            --  self.hintShown = false
            end
            self:UpdateDimensions()
        end)

        -- Button to reset new items:
        if tBag and _G.cBnivCfg.NewItems then
            self.resetBtn = createIconButton("ResetNew", self, Textures.ResetNew, "BOTTOMRIGHT", "Reset New", tBag)
            self.resetBtn:SetPoint("BOTTOMRIGHT", self.bagToggle, "BOTTOMLEFT", 0, 0)
            self.resetBtn:SetScript("OnClick", function() resetNewItems(self) end)
        end

        -- Button to restack items:
        if _G.cBnivCfg.Restack then
            self.restackBtn = createIconButton("Restack", self, Textures.Restack, "BOTTOMRIGHT", "Restack", tBag)
            if self.resetBtn then
                self.restackBtn:SetPoint("BOTTOMRIGHT", self.resetBtn, "BOTTOMLEFT", 0, 0)
            else
                self.restackBtn:SetPoint("BOTTOMRIGHT", self.bagToggle, "BOTTOMLEFT", 0, 0)
            end
            self.restackBtn:SetScript("OnClick", function() restackItems(self) end)
        end

        -- Button to show /cbniv options:
        self.optionsBtn = createIconButton("Options", self, Textures.Config, "BOTTOMRIGHT", "Options", tBag)
        if self.restackBtn then
            self.optionsBtn:SetPoint("BOTTOMRIGHT", self.restackBtn, "BOTTOMLEFT", 0, 0)
        elseif self.resetBtn then
            self.optionsBtn:SetPoint("BOTTOMRIGHT", self.resetBtn, "BOTTOMLEFT", 0, 0)
        else
            self.optionsBtn:SetPoint("BOTTOMRIGHT", self.bagToggle, "BOTTOMLEFT", 0, 0)
        end
        self.optionsBtn:SetScript("OnClick", function()
            _G.SlashCmdList.CBNIV("")
            _G.print("Usage: /cbniv |cffffff00command|r")
        end)

        -- Button to toggle Sell Junk:
        if tBag then
            local sjHint = _G.cBnivCfg.SellJunk and "Sell Junk |cffd0d0d0(on)|r" or "Sell Junk |cffd0d0d0(off)|r"
            self.junkBtn = createIconButton("SellJunk", self, Textures.SellJunk, "BOTTOMRIGHT", sjHint, tBag)
            if self.optionsBtn then
                self.junkBtn:SetPoint("BOTTOMRIGHT", self.optionsBtn, "BOTTOMLEFT", 0, 0)
            elseif self.restackBtn then
                self.junkBtn:SetPoint("BOTTOMRIGHT", self.restackBtn, "BOTTOMLEFT", 0, 0)
            elseif self.resetBtn then
                self.junkBtn:SetPoint("BOTTOMRIGHT", self.resetBtn, "BOTTOMLEFT", 0, 0)
            else
                self.junkBtn:SetPoint("BOTTOMRIGHT", self.bagToggle, "BOTTOMLEFT", 0, 0)
            end
            self.junkBtn:SetScript("OnClick", function()
                _G.cBnivCfg.SellJunk = not(_G.cBnivCfg.SellJunk)
                if _G.cBnivCfg.SellJunk then
                    self.junkBtn.tooltip:SetText("Sell Junk |cffd0d0d0(on)|r")
                else
                    self.junkBtn.tooltip:SetText("Sell Junk |cffd0d0d0(off)|r")
                end
            end)
        end

        -- Button to send reagents to Reagent Bank:
        if tBank then
            local rbHint = _G.REAGENTBANK_DEPOSIT
            self.reagentBtn = createIconButton("SendReagents", self, Textures.Deposit, "BOTTOMRIGHT", rbHint, tBag)
            if self.optionsBtn then
                self.reagentBtn:SetPoint("BOTTOMRIGHT", self.optionsBtn, "BOTTOMLEFT", 0, 0)
            elseif self.restackBtn then
                self.reagentBtn:SetPoint("BOTTOMRIGHT", self.restackBtn, "BOTTOMLEFT", 0, 0)
            else
                self.reagentBtn:SetPoint("BOTTOMRIGHT", self.bagToggle, "BOTTOMLEFT", 0, 0)
            end
            self.reagentBtn:SetScript("OnClick", function()
                --print("Deposit!!!")
                _G.DepositReagentBank()
            end)
        end

        -- Tooltip positions
        local btnTable = {self.bagToggle}
        if self.optionsBtn then _G.tinsert(btnTable, self.optionsBtn) end
        if self.restackBtn then _G.tinsert(btnTable, self.restackBtn) end
        if tBag then
            if self.resetBtn then _G.tinsert(btnTable, self.resetBtn) end
            if self.junkBtn then _G.tinsert(btnTable, self.junkBtn) end
        end
        if tBank then
            if self.reagentBtn then _G.tinsert(btnTable, self.reagentBtn) end
        end
        local ttPos = -(#btnTable * 15 + 18)
        if tBank then ttPos = ttPos + 3 end
        for k,v in next, btnTable do
            v.tooltip:ClearAllPoints()
            v.tooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", ttPos, 5.5)
            v.tooltipIcon:ClearAllPoints()
            v.tooltipIcon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", ttPos + 5, 1.5)
        end
    end

    -- Item drop target
    if (tBag or tBank or tReagent) then
        self.DropTarget = _G.CreateFrame("Button", self.name.."DropTarget", self, "ItemButtonTemplate")
        local dtNT = _G[self.DropTarget:GetName().."NormalTexture"]
        if dtNT then dtNT:SetTexture(nil) end


        local DropTargetProcessItem = function()
            -- if CursorHasItem() then  -- Commented out to fix Guild Bank -> Bags item dragging
                local bID, sID = GetFirstFreeSlot((tBag and "bag") or (tBank and "bank") or "bankReagent")
                if bID then _G.PickupContainerItem(bID, sID) end
            -- end
        end
        self.DropTarget:SetScript("OnMouseUp", DropTargetProcessItem)
        self.DropTarget:SetScript("OnReceiveDrag", DropTargetProcessItem)
        self.DropTarget:SetSize(itemSlotSize - 1, itemSlotSize - 1)

        self.DropTarget.bg = _G.CreateFrame("Frame", nil, self.DropTarget)
        self.DropTarget.bg:SetAllPoints()
        Base.SetBackdrop(self.DropTarget.bg, Aurora.Color.frame)

        local fs = self:CreateFontString(nil, "OVERLAY")
        fs:SetFontObject("NumberFont_Outline_Med")
        fs:SetJustifyH("LEFT")
        fs:SetPoint("BOTTOMRIGHT", self.DropTarget, "BOTTOMRIGHT", 1.5, 1.5)
        self.EmptySlotCounter = fs

        if _G.cBnivCfg.CompressEmpty then
            self.DropTarget:Show()
            self.EmptySlotCounter:Show()
        else
            self.DropTarget:Hide()
            self.EmptySlotCounter:Hide()
        end
    end

    if tBag then
        local infoFrame = _G.CreateFrame("Button", nil, self)
        infoFrame:SetPoint("BOTTOMLEFT", 5, -6)
        infoFrame:SetPoint("BOTTOMRIGHT", -86, -6)
        infoFrame:SetHeight(32)

        -- Search bar
        local search = self:SpawnPlugin("SearchBar", infoFrame)
        search.isGlobal = true
        search.highlightFunction = function(button, match) button:SetAlpha(match and 1 or 0.1) end

        local searchIcon = background:CreateTexture(nil, "ARTWORK")
        searchIcon:SetTexture(Textures.Search)
        searchIcon:SetVertexColor(0.8, 0.8, 0.8)
        searchIcon:SetPoint("BOTTOMLEFT", infoFrame, "BOTTOMLEFT", -3, 8)
        searchIcon:SetWidth(16)
        searchIcon:SetHeight(16)

        -- Hint
        self.hint = background:CreateFontString(nil, "OVERLAY", nil)
        self.hint:SetPoint("BOTTOMLEFT", infoFrame, -0.5, 31.5)
        self.hint:SetFontObject("SystemFont_Shadow_Med1")
        self.hint:SetTextColor(1, 1, 1, 0.4)
        self.hint:SetText("Ctrl + Alt + Right Click an item to assign category")
        self.hintShown = true

        -- The money display
        local money = self:SpawnPlugin("TagDisplay", "[money]", self)
        money:SetPoint("TOPRIGHT", self, -25.5, -2.5)
        money:SetFontObject("SystemFont_Shadow_Med1")
        money:SetJustifyH("RIGHT")
        money:SetShadowColor(0, 0, 0, 0)
    end

    self:SetScale(_G.cBnivCfg.scale)
    return self
end

------------------------------------------
-- MyButton specific
------------------------------------------
local MyButton = cbNivaya:GetItemButtonClass()
MyButton:Scaffold("Default")

function MyButton:OnAdd()
    self:SetScript("OnMouseUp", function(btn, mouseButton)
        if mouseButton == "RightButton" and (_G.IsAltKeyDown()) and (_G.IsControlKeyDown()) then
            local item = cbNivaya:GetItem(btn.bagID, btn.slotID)
            if item.name and item.id then
                ns.cbNivDropdown.itemName = item.name
                ns.cbNivDropdown.itemID = item.id
                --ToggleDropDownMenu(1, nil, ns.cbNivDropdown, btn, 0, 0)
                ns.cbNivDropdown:Toggle(btn, nil, nil, 0, 0)
            end
        end
    end)
end
