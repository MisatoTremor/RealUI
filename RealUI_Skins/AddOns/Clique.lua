local _, private = ...

-- Lua Globals --
-- luacheck: globals

-- [[ Core ]]
local Aurora = private.Aurora
local Base, Skin = Aurora.Base, Aurora.Skin

do --[[ AddOns\Clique\Clique.xml ]]
    function Skin.CliqueColumnTemplate(Frame)
        Frame:DisableDrawLayer("BACKGROUND")
    end
end

function private.AddOns.Clique()
    Skin.SpellBookSkillLineTabTemplate(_G.CliqueSpellTab)

    if _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE then
        Skin.GlowBoxTemplate(_G.CliqueTabAlert)
        Skin.GlowBoxArrowTemplate(_G.CliqueTabAlertArrow)
        Skin.UIPanelCloseButton(_G.CliqueTabAlertClose)

        Skin.BasicFrameTemplate(_G.CliqueDialog)
        Skin.UIPanelButtonTemplate(_G.CliqueDialogButtonBinding)
        Skin.UIPanelButtonTemplate(_G.CliqueDialogButtonAccept)

        Skin.ButtonFrameTemplate(_G.CliqueConfig)
        Skin.UIDropDownMenuTemplate(_G.CliqueConfigDropdown)
        Skin.CliqueColumnTemplate(_G.CliqueConfigPage1Column1)
        Skin.CliqueColumnTemplate(_G.CliqueConfigPage1Column2)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage1ButtonSpell)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage1ButtonOther)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage1ButtonOptions)
        Skin.UIPanelButtonTemplate(_G.CliqueConfigPage2ButtonBinding)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage2ButtonSave)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage2ButtonCancel)
        Skin.GlowBoxTemplate(_G.CliqueConfigBindAlert)
        Skin.GlowBoxArrowTemplate(_G.CliqueConfigBindAlertArrow)
    else
        Base.SetBackdrop(_G.CliqueConfig)
        Skin.UIPanelCloseButton(_G.CliqueConfigCloseButton)

        _G.CliqueConfigPortrait:SetAlpha(0)
        _G.CliqueConfigPortraitFrame:SetAlpha(0)
        _G.CliqueConfigTitleBg:Hide()
        _G.CliqueConfigTopTileStreaks:Hide()
        _G.CliqueConfigBg:Hide()
        _G.CliqueConfigTopLeftCorner:Hide()
        _G.CliqueConfigTopRightCorner:Hide()
        _G.CliqueConfigBotLeftCorner:Hide()
        _G.CliqueConfigBotRightCorner:Hide()
        _G.CliqueConfigTopBorder:Hide()
        _G.CliqueConfigBottomBorder:Hide()
        _G.CliqueConfigLeftBorder:Hide()
        _G.CliqueConfigRightBorder:Hide()

        _G.CliqueConfigInsetBg:Hide()
        _G.CliqueConfigInsetInsetTopLeftCorner:Hide()
        _G.CliqueConfigInsetInsetTopRightCorner:Hide()
        _G.CliqueConfigInsetInsetBotLeftCorner:Hide()
        _G.CliqueConfigInsetInsetBotRightCorner:Hide()
        _G.CliqueConfigInsetInsetTopBorder:Hide()
        _G.CliqueConfigInsetInsetBottomBorder:Hide()
        _G.CliqueConfigInsetInsetLeftBorder:Hide()
        _G.CliqueConfigInsetInsetRightBorder:Hide()

        _G.CliqueConfigInsetBg:Hide()

        Skin.MagicButtonTemplate(_G.CliqueConfigPage1ButtonSpell)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage1ButtonOther)
        Skin.MagicButtonTemplate(_G.CliqueConfigPage1ButtonOptions)

        _G.CliqueConfigPage1Column1Left:Hide()
        _G.CliqueConfigPage1Column1Middle:Hide()
        _G.CliqueConfigPage1Column1Right:Hide()
        _G.CliqueConfigPage1Column2Left:Hide()
        _G.CliqueConfigPage1Column2Middle:Hide()
        _G.CliqueConfigPage1Column2Right:Hide()

        Skin.UIDropDownMenuTemplate(_G.CliqueConfigDropdown)

    end
end
