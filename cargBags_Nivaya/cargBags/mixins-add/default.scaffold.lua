--[[
LICENSE
    cargBags: An inventory framework addon for World of Warcraft

    Copyright (C) 2010  Constantin "Cargor" Schomburg <xconstruct@gmail.com>

    cargBags is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    cargBags is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with cargBags; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

DESCRIPTION
    Provides a Scaffold that generates a default Blizz' ContainerButton

DEPENDENCIES
    mixins/api-common.lua
]]
local _, ns = ...
local cargBags = ns.cargBags

-- Lua Globals --
-- luacheck: globals select tonumber

local function Round(num, idp)
    local mult = 10^(idp or 0)
    return _G.floor(num * mult + 0.5) / mult
end

local function ItemColorGradient(perc, ...)
    if perc >= 1 then
        return select(select('#', ...) - 2, ...)
    elseif perc <= 0 then
        return ...
    end

    local num = select('#', ...) / 3
    local segment, relperc = _G.math.modf(perc*(num-1))
    local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

    return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
end

local function CreateInfoString(button, position)
    local str = button:CreateFontString(nil, "OVERLAY")
    if position == "TOP" then
        str:SetJustifyH("LEFT")
        str:SetPoint("TOPLEFT", button, "TOPLEFT", 1.5, -1.5)
    else
        str:SetJustifyH("RIGHT")
        str:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1.5, 1.5)
    end
    str:SetFontObject("NumberFont_Outline_Med")

    return str
end

local function ItemButton_Scaffold(self)
    self:SetSize(37, 37)
    local name = self:GetName()
    self.Icon = _G[name.."IconTexture"]
    self.Count = _G[name.."Count"]
    self.Cooldown = _G[name.."Cooldown"]
    self.Quest = _G[name.."IconQuestTexture"]
    self.Border = _G.CreateFrame("Frame", nil, self)
    self.Border:SetPoint("TOPLEFT", self.Icon, 0, 0)
    self.Border:SetPoint("BOTTOMRIGHT", self.Icon, 0, 0)
    _G.Aurora.Base.SetBackdrop(self.Border, _G.Aurora.Color.frame)

    self.TopString = CreateInfoString(self, "TOP")
    self.BottomString = CreateInfoString(self, "BOTTOM")
end

--[[!
    Update the button with new item-information
    @param item <table> The itemTable holding information, see Implementation:GetItemInfo()
    @callback OnUpdate(item)
]]
local function ItemButton_Update(self, item)
    if item.texture then
        self.Icon:SetTexture(item.texture)
        self.Icon:SetTexCoord(.08, .92, .08, .92)
    else
        if _G.cBnivCfg.CompressEmpty then
            self.Icon:SetTexture(self.bgTex)
            self.Icon:SetTexCoord(.08, .92, .08, .92)
        else
            self.Icon:SetColorTexture(1,1,1,0.1)
        end
    end

    -- Count
    local texture, itemCount = _G.GetContainerItemInfo(item.bagID, item.slotID)
    itemCount = itemCount or (texture and 1 or 0)
    if itemCount > 1 then
        self.Count:SetText(itemCount >= 1e3 and "*" or itemCount)
        self.Count:Show()
    else
        self.Count:Hide()
    end
    item.count = itemCount
    self.count = itemCount

    -- Durability
    local dCur, dMax = _G.GetContainerItemDurability(item.bagID, item.slotID)
    if dMax and (dMax > 0) and (dCur < dMax) then
        local dPer = (dCur / dMax * 100)
        local r, g, b = ItemColorGradient((dCur/dMax), 1, 0, 0, 1, 1, 0, 0, 1, 0)
        self.TopString:SetText(Round(dPer).."%")
        self.TopString:SetTextColor(r, g, b)
    else
        self.TopString:SetText("")
    end

    -- Item Level
    if item.link then
        if (item.equipLoc ~= "") and (item.level and item.level > 0) then
            self.BottomString:SetText(item.level)
        else
            self.BottomString:SetText("")
        end
        self.BottomString:SetTextColor(_G.GetItemQualityColor(item.rarity or 1))
    else
        self.BottomString:SetText("")
    end

    self:UpdateCooldown(item)
    self:UpdateLock(item)
    self:UpdateQuest(item)

    if self.OnUpdate then self:OnUpdate(item) end
end

--[[!
    Updates the buttons cooldown with new item-information
    @param item <table> The itemTable holding information, see Implementation:GetItemInfo()
    @callback OnUpdateCooldown(item)
]]
local function ItemButton_UpdateCooldown(self, item)
    local start, duration, enable = _G.GetContainerItemCooldown(item.bagID, item.slotID)
    _G.CooldownFrame_Set(self.Cooldown, start, duration, enable)

    if self.OnUpdateCooldown then self:OnUpdateCooldown(item, start, duration, enable) end
end

--[[!
    Updates the buttons lock with new item-information
    @param item <table> The itemTable holding information, see Implementation:GetItemInfo()
    @callback OnUpdateLock(item)
]]
local function ItemButton_UpdateLock(self, item)
    local _, _, isLocked = _G.GetContainerItemInfo(item.bagID, item.slotID)
    self.Icon:SetDesaturated(isLocked)

    if self.OnUpdateLock then self:OnUpdateLock(item, isLocked) end
end

--[[!
    Updates the buttons quest texture with new item information
    @param item <table> The itemTable holding information, see Implementation:GetItemInfo()
    @callback OnUpdateQuest(item)
]]
local function ItemButton_UpdateQuest(self, item)
    if item.questID or item.isQuestItem then
        self.Border:SetBackdropBorderColor(1, 1, 0, 1)
    elseif item.rarity and item.rarity > 1 then
        local r, g, b = _G.GetItemQualityColor(item.rarity)
        self.Border:SetBackdropBorderColor(r, g, b, 1)
    else
        self.Border:SetBackdropBorderColor(0, 0, 0, 1)
    end
    if self.OnUpdateQuest then self:OnUpdateQuest(item) end
end

cargBags:RegisterScaffold("Default", function(self)
    self.glowTex = "Interface\\Buttons\\UI-ActionButton-Border" --! @property glowTex <string> The textures used for the glow
    self.glowAlpha = 0.8 --! @property glowAlpha <number> The alpha of the glow texture
    self.glowBlend = "ADD" --! @property glowBlend <string> The blendMode of the glow texture
    self.glowCoords = { 14/64, 50/64, 14/64, 50/64 } --! @property glowCoords <table> Indexed table of texCoords for the glow texture
    self.bgTex = nil --! @property bgTex <string> Texture used as a background if no item is in the slot

    --self.CreateFrame = ItemButton_CreateFrame
    self.Scaffold = ItemButton_Scaffold

    self.Update = ItemButton_Update
    self.UpdateCooldown = ItemButton_UpdateCooldown
    self.UpdateLock = ItemButton_UpdateLock
    self.UpdateQuest = ItemButton_UpdateQuest

    --self.OnEnter = ItemButton_OnEnter
    --self.OnLeave = ItemButton_OnLeave
end)
