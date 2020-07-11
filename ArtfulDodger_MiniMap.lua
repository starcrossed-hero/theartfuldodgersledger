local addon = LibStub("AceAddon-3.0"):GetAddon("ArtfulDodger")
local gui = addon:GetModule("ArtfulDodger_UI")
local minimap = addon:NewModule("ArtfulDodger_MiniMap")
local button = LibStub("LibDBIcon-1.0")

local UPDATE_FREQUENCY = 5
local UPDATE_TIMER = 0

local GOLD = "|cffeec300"
local WHITE = "|cffFFFFFF"
local STATUS_STRING_FORMAT = GOLD.."Marks:|r "..WHITE.."%d|r   "..GOLD.."Coin:|r "..WHITE.."%s|r  "..GOLD.."Per Hour:|r  "..WHITE.."%s|r"..GOLD.."  Per Mark:|r  "..WHITE.."%s|r"
--local STATUS_STRING_FORMAT = WHITE.." %s|r"..GOLD.."/hour|r  "..WHITE.."%s|r"..GOLD.."/mark|r"

local dataObject = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("The Artful Dodger's Ledger", {
    type = "data source", 
    icon = "Interface\\Icons\\INV_Misc_Bag_11", 
    text = string.format(STATUS_STRING_FORMAT, 
        0,
        GetCoinTextureString(0),
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
    UPDATE_TIMER = UPDATE_TIMER - elapsed
    if UPDATE_TIMER <= 0 then
        UPDATE_TIMER = UPDATE_FREQUENCY
        if minimap.db then
            local duration = time() - minimap.db.stats.session.start
            dataObject.text = string.format(STATUS_STRING_FORMAT, 
                minimap.db.stats.session.marks,
                GetCoinTextureString(minimap.db.stats.session.copper),
                GetCoinTextureString(addon:GetSessionCopperPerHour()),
                GetCoinTextureString(addon:GetSessionCopperPerMark())
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