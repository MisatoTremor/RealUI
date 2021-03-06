local ADDON_NAME, private = ...

local loaded = _G.LoadAddOn("RealUI_Skins")
local tries = 1
while not loaded do
    loaded = _G.LoadAddOn("RealUI_Skins")
    tries = tries + 1
    if tries > 3 then
        _G.StaticPopupDialogs["REALUI_SKINS_NOT_FOUND"] = {
            text = "Module \"Skins\" was not found. RealUI will now be disabled.",
            button1 = _G.OKAY,
            OnShow = function(self)
                self:SetScale(2)
                self:ClearAllPoints()
                self:SetPoint("CENTER")
            end,
            OnAccept = function(self, data)
                _G.DisableAddOn("nibRealUI")
                _G.ReloadUI()
            end,
            timeout = 0,
            exclusive = 1,
            whileDead = 1,
        }
        _G.StaticPopup_Show("REALUI_SKINS_NOT_FOUND")
        break
    end
end

-- RealUI --
private.RealUI = _G.LibStub("AceAddon-3.0"):NewAddon(_G.RealUI, ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local RealUI = private.RealUI

local xpac, major, minor = _G.strsplit(".", _G.GetBuildInfo())
RealUI.isPatch = _G.tonumber(xpac) == 8 and (_G.tonumber(major) >= 2 and _G.tonumber(minor) >= 0)

local classLocale, classToken, classID = _G.UnitClass("player")
RealUI.charInfo = {
    name = _G.UnitName("player"),
    realm = _G.GetRealmName(),
    faction = _G.UnitFactionGroup("player"),
    class = {
        locale = classLocale,
        token = classToken,
        id = classID,
        color = _G.CUSTOM_CLASS_COLORS[classToken] or _G.CUSTOM_CLASS_COLORS.PRIEST
    },
    specs = {
        current = {}
    }
}

for specIndex = 1, _G.GetNumSpecializationsForClassID(classID) do
    local id, name, _, iconID, role, isRecommended = _G.GetSpecializationInfoForClassID(classID, specIndex)
    RealUI.charInfo.specs[specIndex] = {
        index = specIndex,
        id = id,
        name = name,
        icon = iconID,
        role = role,
        isRecommended = isRecommended,
    }

    if isRecommended then
        RealUI.charInfo.specs.current = RealUI.charInfo.specs[specIndex]
    end
end

RealUI.globals = {
    anchorPoints = {
        "TOPLEFT",    "TOP",    "TOPRIGHT",
        "LEFT",       "CENTER", "RIGHT",
        "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
    },
    cornerPoints = {
        "TOPLEFT",
        "TOPRIGHT",
        "BOTTOMLEFT",
        "BOTTOMRIGHT",
    },
    stratas = {
        "BACKGROUND",
        "LOW",
        "MEDIUM",
        "HIGH",
        "DIALOG",
        "TOOLTIP"
    }
}


local black = _G.Aurora.Color.black
local a = RealUI:GetAddOnDB("RealUI_Skins").profile.frameColor.a
local LDD = _G.LibStub("LibDropDown")
LDD:RegisterStyle("REALUI", {
    padding = 10,
    spacing = 1,
    backdrop = {
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]], edgeSize = 1,
    },
    backdropColor = _G.CreateColor(black.r, black.g, black.b, a),
    backdropBorderColor = black,
})
