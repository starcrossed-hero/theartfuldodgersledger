local TheArtfulDodgersLedger = LibStub("AceAddon-3.0"):GetAddon("TheArtfulDodgersLedger")

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local UPDATE_FREQUENCY = 2

local GOLD = "|cffeec300"
local WHITE = "|cffFFFFFF"
local STATUS_STRING_FORMAT = GOLD.."Coin:|r "..WHITE.."%s|r  "..GOLD.."Marks:|r "..WHITE.."%d|r   "..GOLD.."Average:|r "..WHITE.."%s|r"

local dataObject = ldb:NewDataObject("TheArtfulDodgersLedger", {type = "data source", icon = "Interface\\Icons\\INV_Misc_Bag_11", text = string.format(STATUS_STRING_FORMAT, GetCoinTextureString(0), 0, GetCoinTextureString(0))})

local f = CreateFrame("frame") 
f:SetScript("OnUpdate", function(self, elapsed)
    UPDATE_FREQUENCY = UPDATE_FREQUENCY - elapsed
    if UPDATE_FREQUENCY <= 0 then
        UPDATE_FREQUENCY = 2
        dataObject.text = string.format(STATUS_STRING_FORMAT, GetCoinTextureString(TheArtfulDodgersLedger.db.char.sessionLootedCopper), TheArtfulDodgersLedger.db.char.sessionLootedCount, GetCoinTextureString(TheArtfulDodgersLedger:CalculateAverageCopperPerMark(TheArtfulDodgersLedger.db.char.sessionLootedCopper, TheArtfulDodgersLedger.db.char.sessionLootedCount)))
    end
end)

function dataObject:OnClick(button)
    if button == "LeftButton" then
       TheArtfulDodgersLedger:ShowFrame() 
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