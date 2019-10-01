local addon = LibStub("AceAddon-3.0"):GetAddon("TheArtfulDodgersLedger")
local gui = addon:GetModule("GUI")
local minimap = addon:NewModule("MiniMapButton")
local button = LibStub("LibDBIcon-1.0")

local UPDATE_FREQUENCY = 2

local GOLD = "|cffeec300"
local WHITE = "|cffFFFFFF"
local STATUS_STRING_FORMAT = GOLD.."Coin:|r "..WHITE.."%s|r  "..GOLD.."Marks:|r "..WHITE.."%d|r   "..GOLD.."Avg/Hr:|r  "..WHITE.."%s|r"..GOLD.."  Avg/Mk:|r  "..WHITE.."%s|r"

local dataObject = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("The Artful Dodger's Ledger", {
    type = "data source", 
    icon = "Interface\\Icons\\INV_Misc_Bag_11", 
    text = string.format(STATUS_STRING_FORMAT, 
        GetCoinTextureString(0), 
        0, 
        GetCoinTextureString(0),
        GetCoinTextureString(0)
    )
})

function minimap:OnEnable()
    minimap.db = addon.db
    button:Register("The Artful Dodger's Ledger", dataObject, self.db.settings.minimap)
	addon:RegisterChatCommand("adl", "Show")
end

local ldbDataSourceDisplay = CreateFrame("frame") 
ldbDataSourceDisplay:SetScript("OnUpdate", function(self, elapsed)
    UPDATE_FREQUENCY = UPDATE_FREQUENCY - elapsed
    if UPDATE_FREQUENCY <= 0 then
        UPDATE_FREQUENCY = 2
        if minimap.db then
            local duration = time() - minimap.db.stats.session.start
            dataObject.text = string.format(STATUS_STRING_FORMAT, 
                GetCoinTextureString(minimap.db.stats.session.copper), 
                minimap.db.stats.session.marks, 
                GetCoinTextureString(
                    addon:CalculateAverageCopperPerMark(minimap.db.stats.session.copper, minimap.db.stats.session.marks)
                ),
                GetCoinTextureString(
                    addon:CalculateAverageCopperPerHour(minimap.db.stats.session.copper, minimap.db.stats.session.duration)
                )
            )
            minimap.db.stats.session.duration = duration
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
    self:AddLine(addon:GetPrettyPrintTotalLootedString())
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

function button:OnClick(button)
    if button == "LeftButton" then
        gui:ShowFrame()
    elseif button == "RightButton" then
        button:Hide("The Artful Dodger's Ledger")
    end
end