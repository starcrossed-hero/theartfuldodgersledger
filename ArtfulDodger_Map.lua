local addon = LibStub("AceAddon-3.0"):GetAddon("ArtfulDodger")
local map = addon:NewModule("ArtfulDodger_Map")
local AceGUI = LibStub("AceGUI-3.0")

local mapFrame

do
    local title = "The Artful Dodger's Ledger"
    
    mapFrame = CreateFrame("FRAME", nil, WorldMapFrame.ScrollContainer)
    mapFrame:SetSize(200, 80)
    mapFrame:SetPoint("TOPLEFT")

    mapFrame.t = mapFrame:CreateTexture(nil, "BACKGROUND")
    mapFrame.t:SetAllPoints()
    mapFrame.t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    mapFrame.t:SetVertexColor(0, 0, 0, 0.5)
    
    local titleFrame = CreateFrame("Frame", nil, mapFrame)
    titleFrame:SetPoint("TOP")
    titleFrame:SetSize(200, 20)
    titleFrame.x = titleFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    titleFrame.x:SetJustifyH("MIDDLE")
    titleFrame.x:SetAllPoints()
    titleFrame.x:SetText(title)
    
    local zoneFrame = CreateFrame("Frame", nil, mapFrame)
    zoneFrame:SetPoint("TOP", titleFrame, "BOTTOM")
    zoneFrame:SetSize(200, 20)
    zoneFrame.x = zoneFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite") 
    zoneFrame.x:SetJustifyH("MIDDLE")
    zoneFrame.x:SetAllPoints()
    
    local statValueFrame = CreateFrame("Frame", nil, mapFrame)
    statValueFrame:SetPoint("TOP", zoneFrame, "BOTTOM")
    statValueFrame:SetPoint("RIGHT")
    statValueFrame:SetSize(120, 40)
    statValueFrame.x = statValueFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal") 
    statValueFrame.x:SetJustifyH("LEFT")
    statValueFrame.x:SetAllPoints()
    
    local statNameFrame = CreateFrame("Frame", nil, mapFrame)
    statNameFrame:SetPoint("TOP", zoneFrame, "BOTTOM")
    statNameFrame:SetPoint("LEFT")
    statNameFrame:SetPoint("RIGHT", statValueFrame, "LEFT")
    statNameFrame:SetSize(60, 40)
    statNameFrame.x = statNameFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    statNameFrame.x:SetText(" Marks: \n Coin: \n")
    statNameFrame.x:SetJustifyH("LEFT")
    statNameFrame.x:SetAllPoints()
    
    local mapHeaderTime = -1
    mapFrame:SetScript("OnUpdate", function(self, elapsed)
        if mapHeaderTime > 0.3 or mapHeaderTime == -1 then
            local mapId, mapInfo
            local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
            if x and y and x > 0 and y > 0 and MouseIsOver(WorldMapFrame.ScrollContainer) then
                mapId = WorldMapFrame:GetMapID()
                mapInfo = C_Map.GetMapInfoAtPosition(mapId, x, y)
                if not mapInfo or (mapInfo and mapInfo.mapType < 3) then
                    mapId = C_Map.GetBestMapForUnit("player")
                    mapInfo = C_Map.GetMapInfo(mapId)
                end
            end
            if mapInfo then
                zoneFrame.x:SetFormattedText(mapInfo.name)
                statValueFrame.x:SetFormattedText(
                        addon:GetZoneMarks(mapInfo.name).."\n"..
                        GetCoinTextureString(
                            addon:GetZoneTotalCopper(mapInfo.name)
                        )
                )
            end
        end
        mapHeaderTime = mapHeaderTime + elapsed
    end)
end

function map:ToggleMap()
    if mapFrame then
        if map.db.settings.map.visible then
            mapFrame:Show()
        else
            mapFrame:Hide()
        end
    end
end

function map:OnEnable()
    map.db = addon.db
    map:ToggleMap()
end