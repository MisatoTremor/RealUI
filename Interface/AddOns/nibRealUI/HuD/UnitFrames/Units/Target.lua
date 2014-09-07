local nibRealUI = LibStub("AceAddon-3.0"):GetAddon("nibRealUI")

local MODNAME = "UnitFrames"
local UnitFrames = nibRealUI:GetModule(MODNAME)
local AngleStatusBar = nibRealUI:GetModule("AngleStatusBar")
local RC = LibStub("LibRangeCheck-2.0")
local db, ndb, ndbc

local oUF = oUFembed

local positions = {
    [1] = {
        health = {
            x = 2,
            widthOfs = 13,
            coords = {1, 0.1328125, 0.1875, 1},
        },
        power = {
            x = 7,
            widthOfs = 10,
            coords = {1, 0.23046875, 0, 0.5},
        },
        healthBox = {1, 0, 0, 1},
        statusBox = {1, 0, 0, 1},
    },
    [2] = {
        health = {
            x = 2,
            widthOfs = 15,
            coords = {1, 0.494140625, 0.0625, 1},
        },
        power = {
            x = 9,
            widthOfs = 12,
            coords = {1, 0.1015625, 0, 0.625},
        },
        healthBox = {1, 0, 0, 1},
        statusBox = {1, 0, 0, 1},
    },
}

local function CreateHealthBar(parent)
    local texture = UnitFrames.textures[UnitFrames.layoutSize].F1.health
    local pos = positions[UnitFrames.layoutSize].health
    local health = CreateFrame("Frame", nil, parent)
    health:SetPoint("TOPLEFT", parent, 0, 0)
    health:SetSize(texture.width, texture.height)

    health.bar = AngleStatusBar:NewBar(health, pos.x, -1, texture.width - pos.widthOfs, texture.height - 2, "RIGHT", "RIGHT", "RIGHT", true)

    health.bg = health:CreateTexture(nil, "BACKGROUND")
    health.bg:SetTexture(texture.bar)
    health.bg:SetTexCoord(pos.coords[1], pos.coords[2], pos.coords[3], pos.coords[4])
    health.bg:SetVertexColor(0, 0, 0, 0.4)
    health.bg:SetAllPoints(health)

    health.border = health:CreateTexture(nil, "BORDER")
    health.border:SetTexture(texture.border)
    health.border:SetTexCoord(pos.coords[1], pos.coords[2], pos.coords[3], pos.coords[4])
    health.border:SetAllPoints(health)

    health.text = health:CreateFontString(nil, "OVERLAY")
    health.text:SetPoint("BOTTOMLEFT", health, "TOPLEFT", 0, 2)
    health.text:SetFont(unpack(nibRealUI:Font()))
    health.text:SetJustifyH("LEFT")
    parent:Tag(health.text, "[realui:healthPercent][realui:health]")

    health.frequentUpdates = true
    health.Override = UnitFrames.HealthOverride
    return health
end

local function CreatePowerBar(parent)
    local texture = UnitFrames.textures[UnitFrames.layoutSize].F1.power
    local pos = positions[UnitFrames.layoutSize].power
    local power = CreateFrame("Frame", nil, parent)
    power:SetPoint("BOTTOMLEFT", parent, 5, 0)
    power:SetSize(texture.width, texture.height)

    power.bar = AngleStatusBar:NewBar(power, pos.x, -1, texture.width - pos.widthOfs, texture.height - 2, "LEFT", "LEFT", "RIGHT", true)

    ---[[
    power.bg = power:CreateTexture(nil, "BACKGROUND")
    power.bg:SetTexture(texture.bar)
    power.bg:SetTexCoord(pos.coords[1], pos.coords[2], pos.coords[3], pos.coords[4])
    power.bg:SetVertexColor(0, 0, 0, 0.4)
    power.bg:SetAllPoints(power)
    ---]]

    power.border = power:CreateTexture(nil, "BORDER")
    power.border:SetTexture(texture.border)
    power.border:SetTexCoord(pos.coords[1], pos.coords[2], pos.coords[3], pos.coords[4])
    power.border:SetAllPoints(power)

    power.text = power:CreateFontString(nil, "OVERLAY")
    power.text:SetPoint("TOPLEFT", power, "BOTTOMLEFT", 0, -3)
    power.text:SetFont(unpack(nibRealUI:Font()))
    parent:Tag(power.text, "[realui:power]")

    power.frequentUpdates = true
    power.Override = UnitFrames.PowerOverride
    return power
end

local function CreatePvPStatus(parent)
    local texture = UnitFrames.textures[UnitFrames.layoutSize].F1.healthBox
    local coords = positions[UnitFrames.layoutSize].healthBox
    local pvp = parent:CreateTexture(nil, "OVERLAY", nil, 1)
    pvp:SetTexture(texture.bar)
    pvp:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    pvp:SetSize(texture.width, texture.height)
    pvp:SetPoint("TOPLEFT", parent, 8, -1)

    local border = parent:CreateTexture(nil, "OVERLAY", nil, 3)
    border:SetTexture(texture.border)
    border:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    border:SetAllPoints(pvp)

    pvp.Override = function(self, event, unit)
        --print("PvP Override", self, event, unit, IsPVPTimerRunning())
        pvp:SetVertexColor(0, 0, 0, 0.6)
        if UnitIsPVP(unit) then
            if UnitIsFriend(unit, "target") then
                self.PvP:SetVertexColor(unpack(db.overlay.colors.status.pvpFriendly))
            else
                self.PvP:SetVertexColor(unpack(db.overlay.colors.status.pvpEnemy))
            end
        end
    end
    return pvp
end

local function CreateCombatResting(parent)
    local texture = UnitFrames.textures[UnitFrames.layoutSize].F1.statusBox
    local coords = positions[UnitFrames.layoutSize].healthBox
    -- Combat status has priority so we'll use the BG as its base
    local combat = parent:CreateTexture(nil, "BORDER")
    combat:SetTexture(texture.bar)
    combat:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    combat:SetSize(texture.width, texture.height)
    combat:SetPoint("TOPLEFT", parent, "TOPRIGHT", -8, 0)

    -- Resting is second priority, so we use the border then change the BG in Override.
    local resting = parent:CreateTexture(nil, "OVERLAY", nil, 3)
    resting:SetTexture(texture.border)
    resting:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    resting:SetAllPoints(combat)

    combat.Override = UnitFrames.CombatResting
    resting.Override = UnitFrames.CombatResting
    
    return combat, resting
end

local function CreateRange(parent)
    local RangeColors = {
        [5] = nibRealUI.media.colors.green,
        [30] = nibRealUI.media.colors.yellow,
        [40] = nibRealUI.media.colors.amber,
        [50] = nibRealUI.media.colors.orange,
        [100] = nibRealUI.media.colors.red,
    }

    local range = parent:CreateTexture(nil, "OVERLAY")
    range:SetTexture(nibRealUI.media.icons.DoubleArrow)
    range:SetSize(16, 16)
    range:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", 0, 0)
    range.insideAlpha = 1
    range.outsideAlpha = 0.5

    range.text = parent:CreateFontString(nil, "OVERLAY")
    range.text:SetFont(unpack(nibRealUI:Font()))
    range.text:SetPoint("BOTTOMRIGHT", range, "BOTTOMLEFT", 0, 0)

    range.Override = function(self, status)
        --print("Range Override", self, status)
        local minRange, maxRange = RC:GetRange("target")

        if (UnitIsUnit("player", "target")) or (minRange and minRange > 80) then maxRange = nil end
        if maxRange then
            if maxRange <= 5 then
                section = 5
            elseif maxRange <= 30 then
                section = 30
            elseif maxRange <= 40 then
                section = 40
            elseif maxRange <= 50 then
                section = 50
            else
                section = 100
            end
            self.Range.text:SetFormattedText("%d", maxRange)
            self.Range.text:SetTextColor(RangeColors[section][1], RangeColors[section][2], RangeColors[section][3])
            self.Range:Show()
        else
            self.Range.text:SetText("")
            self.Range:Hide()
        end
    end

    return range
end

local function CreateThreat(parent)
    local threat = parent:CreateTexture(nil, "OVERLAY")
    threat:SetTexture(nibRealUI.media.icons.Lightning)
    threat:SetSize(16, 16)
    threat:SetPoint("TOPRIGHT", parent, "TOPLEFT", 0, 0)

    threat.text = parent:CreateFontString(nil, "OVERLAY")
    threat.text:SetFont(unpack(nibRealUI:Font()))
    threat.text:SetPoint("BOTTOMRIGHT", threat, "BOTTOMLEFT", 0, 0)

    threat.Override = function(self, event, unit)
        --print("Threat Override", self, event, unit)
        local isTanking, status, _, rawPercentage = UnitDetailedThreatSituation("player", "target")

        local tankLead
        if ( isTanking ) then
            tankLead = UnitThreatPercentageOfLead("player", "target")
        end
        local display = tankLead or rawPercentage
        if not (UnitIsDeadOrGhost("target")) and (display and (display ~= 0)) then
            self.Threat.text:SetFormattedText("%d%%", display)
            r, g, b = GetThreatStatusColor(status)
            self.Threat.text:SetTextColor(r, g, b)
            self.Threat:Show()
        else
            self.Threat.text:SetText("")
            self.Threat:Hide()
        end
    end

    return threat
end

local function CreateTarget(self)
    self.Health = CreateHealthBar(self)
    self.Power = CreatePowerBar(self)
    self.PvP = CreatePvPStatus(self.Health)
    self.Combat, self.Resting = CreateCombatResting(self.Power)
    self.Range = CreateRange(self.Health)
    self.Threat = CreateThreat(self.Power)
    
    self.Name = self:CreateFontString(nil, "OVERLAY")
    self.Name:SetPoint("BOTTOMRIGHT", self.Health, "TOPRIGHT", -12, 2)
    self.Name:SetFont(unpack(nibRealUI:Font()))
    self:Tag(self.Name, "[realui:level] [realui:name]")

    self:SetSize(self.Health:GetWidth(), self.Health:GetHeight() + self.Power:GetHeight() + 3)

    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)

    function self:PostUpdate(event)
        self.Combat.Override(self, event)
    end
end

-- Init
tinsert(UnitFrames.units, function(...)
    db = UnitFrames.db.profile
    ndb = nibRealUI.db.profile
    ndbc = nibRealUI.db.char

    oUF:RegisterStyle("RealUI:target", CreateTarget)
    oUF:SetActiveStyle("RealUI:target")
    local target = oUF:Spawn("target", "RealUITargetFrame")
    target:SetPoint("LEFT", "RealUIPositionersUnitFrames", "RIGHT", db.positions[UnitFrames.layoutSize].target.x, db.positions[UnitFrames.layoutSize].target.y)
    target:RegisterEvent("UNIT_THREAT_LIST_UPDATE", target.Threat.Override)
end)

