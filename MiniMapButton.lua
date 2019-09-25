local addon = LibStub("AceAddon-3.0"):GetAddon("TheArtfulDodgersLedger")
local gui = addon:GetModule("GUI")
local miniMapButtonModule = addon:NewModule("MiniMapButton")
local miniMapButton = LibStub("LibDBIcon-1.0")

local UPDATE_FREQUENCY = 2

local GOLD = "|cffeec300"
local WHITE = "|cffFFFFFF"
local STATUS_STRING_FORMAT = GOLD.."Coin:|r "..WHITE.."%s|r  "..GOLD.."Marks:|r "..WHITE.."%d|r   "..GOLD.."Average:|r "..WHITE.."%s|r"

local dataObject = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("The Artful Dodger's Ledger", {
    type = "data source", 
    icon = "Interface\\Icons\\INV_Misc_Bag_11", 
    text = string.format(STATUS_STRING_FORMAT, 
        GetCoinTextureString(0), 
        0, 
        GetCoinTextureString(0)
    )
})

function miniMapButtonModule:OnEnable()
    self.db = addon.db
    miniMapButton:Register("The Artful Dodger's Ledger", dataObject, self.db.settings.minimap)
	addon:RegisterChatCommand("adl", "Show")
end

local ldbDataSourceDisplay = CreateFrame("frame") 
ldbDataSourceDisplay:SetScript("OnUpdate", function(self, elapsed)
    UPDATE_FREQUENCY = UPDATE_FREQUENCY - elapsed
    if UPDATE_FREQUENCY <= 0 then
        UPDATE_FREQUENCY = 2
        if addon.db then
            dataObject.text = string.format(STATUS_STRING_FORMAT, 
                addon.db.stats.session.copper, 
                addon.db.stats.session.marks, 
                GetCoinTextureString(
                    addon:CalculateAverageCopperPerMark(addon.db.stats.session.copper, addon.db.stats.session.count)
                )
            )
        end
    end
end)

function dataObject:OnClick(button)
    if button == "LeftButton" then
        gui:ShowFrame()
    end
end

function dataObject:OnTooltipShow()
	self:AddLine("The Artful Dodger's Ledger")
    self:AddLine("")
    self:AddLine("")
end

function dataObject:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	dataObject.OnTooltipShow(GameTooltip)
	GameTooltip:Show()
end

function dataObject:OnLeave()
	GameTooltip:Hide()
end

function miniMapButton:OnClick(button)
    if button == "LeftButton" then
        gui:ShowFrame()
    elseif button == "RightButton" then
        miniMapButton:Hide("The Artful Dodger's Ledger")
    end
end