local _, ns = ...

local L = {}
local gl = _G.GetLocale()

L.Search = _G.SEARCH
L.Armor = _G.AUCTION_CATEGORY_ARMOR
L.Consumables = _G.AUCTION_CATEGORY_CONSUMABLES
L.Quest = _G.AUCTION_CATEGORY_QUEST_ITEMS
L.Trades = _G.AUCTION_CATEGORY_TRADE_GOODS
L.Weapon = _G.AUCTION_CATEGORY_WEAPONS
L.bagCaptions = {
    ["cBniv_Bank"]          = _G.BANK,
    ["cBniv_BankArmor"]     = _G.BAG_FILTER_EQUIPMENT,
    ["cBniv_BankQuest"]     = _G.AUCTION_CATEGORY_QUEST_ITEMS,
    ["cBniv_BankTrade"]     = _G.BAG_FILTER_TRADE_GOODS,
    ["cBniv_BankCons"]      = _G.BAG_FILTER_CONSUMABLES,
    ["cBniv_Junk"]          = _G.BAG_FILTER_JUNK,
    ["cBniv_Armor"]         = _G.BAG_FILTER_EQUIPMENT,
    ["cBniv_Quest"]         = _G.AUCTION_CATEGORY_QUEST_ITEMS,
    ["cBniv_Consumables"]   = _G.BAG_FILTER_CONSUMABLES,
    ["cBniv_TradeGoods"]    = _G.BAG_FILTER_TRADE_GOODS,
    ["cBniv_Bag"]           = _G.INVENTORY_TOOLTIP,
    ["cBniv_Keyring"]       = _G.KEYRING,
}

L.bagTabards = _G.INVTYPE_TABARD
L.bagTravel = _G.TUTORIAL_TITLE35

if gl == "deDE" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "Cooles Zeugs"
    L.bagCaptions.cBniv_NewItems = "Neue Items"
elseif gl == "ruRU" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "Разное"
    L.bagCaptions.cBniv_NewItems = "Новые предметы"
elseif gl == "zhTW" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "施法材料"
    L.bagCaptions.cBniv_NewItems = "新增"
elseif gl == "zhCN" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "施法材料"
    L.bagCaptions.cBniv_NewItems = "新增"
elseif gl == "koKR" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "지정"
    L.bagCaptions.cBniv_NewItems = "신규"
elseif gl == "frFR" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "Divers"
    L.bagCaptions.cBniv_NewItems = "Nouveaux Objets"
elseif gl == "itIT" then
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "Cose Interessanti"
    L.bagCaptions.cBniv_NewItems = "Oggetti Nuovi"
else
    L.ResetCategory = "Reset Category"
    L.bagCaptions.cBniv_Stuff = "Cool Stuff"
    L.bagCaptions.cBniv_NewItems = "New Items"
end

ns.L = L
