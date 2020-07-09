TheArtfulDodgersLedger = LibStub("AceAddon-3.0"):NewAddon("TheArtfulDodgersLedger", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

if UnitClass('player') ~= 'Rogue' then
	return
end

local defaults = {
	char = {
		settings = {
			minimap = {
				hide = false,
				minimapPos = 136.23
			},
			gui = {
				visible = false,
                worldMapDisplay = true
			},
            session = {
                eventTrackingLimit = 100
            },
            stats = {
                updateInterval = 15
            }
		},
		stats = {			
			total = {
				start = 0,
				duration = 0,
				marks = 0,
				copper = 0
			},
			session = {
				start = 0,
				duration = 0,
				marks = 0,
				copper = 0
			}
		},
        session = {},
		history = {}
	}
}

local CURRENCY_ID
local CURRENCY_COLOR = "|cFFCC9900"
local CURRENCY_STRING = "Coin"
local CURRENCY_LINK = CURRENCY_COLOR.."["..CURRENCY_STRING.."]|r"
local CURRENCY_ICON_ID = "Interface\\Icons\\INV_Misc_Coin_01"

local MARK_STATE = {
	ALIVE = 1,
	DEAD = 2
}

local JUNKBOXES = {
	{itemId=16882, price=74},
	{itemId=16883, price=124},
	{itemId=16884, price=254},
	{itemId=16885, price=376}
}

PickPocketEvent = {}
PickPocketEvent.__index = PickPocketEvent
function PickPocketEvent:New(eventTime, eventMark, eventZone, eventSubZone, eventLoot)
	local this = {
		timestamp = eventTime or 0,
		mark = eventMark or {},
		zone = eventZone or "",
		subZone = eventSubZone or "",
		loot = eventLoot or {}
	}
	setmetatable(this, self)
	return this
end

function PickPocketEvent:CreateRow()
	return {timestamp=self.timestamp, mark=self.mark, zone=self.zone, subZone=self.subZone, loot=self.loot}
end

function PickPocketEvent:ToString()
	return string.format("PickPocketEvent: timestamp=%d, mark=%s, zone=%s, subZone=%s, loot=%d", self.timestamp, self.mark.guid, self.zone, self.subZone, #self.loot)
end

function TheArtfulDodgersLedger:OnInitialize()
	self:RegisterChatCommand('adl', "ChatCommand")
	self.db = LibStub("AceDB-3.0"):New("TheArtfulDodgersLedgerDB", defaults).char
	self.db.stats.session = defaults.char.stats.session
	self.db.stats.session.start = time()
	if self.db.stats.total.start <= 0 then
		self.db.stats.total.start = self.db.stats.session.start
	end
    self.db.session = {}
	TheArtfulDodgersLedger:SortGlobalLootedHistoryTable()
    TheArtfulDodgersLedger:StartStatUpdater()
    
    TheArtfulDodgersLedger:MapStuff()
end

function TheArtfulDodgersLedger:StartStatUpdater()
    local interval = self.db.settings.stats.updateInterval
    local timer = interval
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, elapsed)
        timer = timer - elapsed
        if timer <= 0 then
            timer = interval
            TheArtfulDodgersLedger:UpdateStats()
        end
    end)
end

function TheArtfulDodgersLedger:OnDisable()
	self.db.stats.total.duration = self.db.stats.total.duration + self.db.stats.session.duration
end

function TheArtfulDodgersLedger:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
    self:RegisterEvent("LOOT_OPENED")
end

function TheArtfulDodgersLedger:InTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return true end
    end
    return false
end

function TheArtfulDodgersLedger:GetJunkboxPrice(itemId)
    for i = 1, #JUNKBOXES do
        if JUNKBOXES[i].itemId == itemId then
            return JUNKBOXES[i].price 
        end
    end
end

function TheArtfulDodgersLedger:IsJunkbox(itemId)
    for i = 1, #JUNKBOXES do
        if JUNKBOXES[i].itemId == itemId then
            return true
        end
    end
    return false
end

function TheArtfulDodgersLedger:GetPickPocketMarkIndex(guid)
    for event = 1, #self.db.session do
        if guid == self.db.session[event].mark.guid then
            return event
        end
    end
    return nil
end

function TheArtfulDodgersLedger:GetPickPocketHistoryMarkIndex(guid)
    for event = 1, #self.db.history do
        if guid == self.db.history[event].mark.guid then
            return event
        end
    end
    return nil
end

function TheArtfulDodgersLedger:GetPickPocketHistoryEventByGuid(guid)
    for event = 1, #self.db.history do
        if guid == self.db.history[event].mark.guid then
            return event
        end
    end
    return nil
end

function TheArtfulDodgersLedger:DeletePickPocketHistoryByGuid(guid)
    for i = 1, #self.db.history do
        if self.db.history[i] and guid == self.db.history[i].mark.guid then
            table.remove(self.db.history, i)
        end
    end
    return nil
end

function TheArtfulDodgersLedger:IsPickPocketMark(guid)
    return TheArtfulDodgersLedger:IsGuidInEventTable(self.db.session, guid)
end

function TheArtfulDodgersLedger:IsAlreadyLooted(guid)
    return TheArtfulDodgersLedger:IsGuidInEventTable(self.db.history, guid)
end

function TheArtfulDodgersLedger:IsGuidInEventTable(table, guid)
    for event = 1, #table do
        if guid == table[event].mark.guid then
            return true
        end
    end
    return false
end

function TheArtfulDodgersLedger:MapStuff()
    
    local cFrame = CreateFrame("FRAME", nil, WorldMapFrame.ScrollContainer)
    cFrame:SetSize(150, 125)
    cFrame:SetPoint("RIGHT", 0, 0)

    cFrame.t = cFrame:CreateTexture(nil, "BACKGROUND")
    cFrame.t:SetAllPoints()
    cFrame.t:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    cFrame.t:SetVertexColor(0, 0, 0, 0.5)
    
    local mapHeader = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer)
    mapHeader:SetPoint("RIGHT", 0, 0)
    mapHeader:SetSize(125, 100)
    mapHeader.x = mapHeader:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge") 
    mapHeader.x:SetJustifyH"LEFT"
    mapHeader.x:SetAllPoints()
    mapHeader.x:SetText("Ledger")
    mapHeader:SetParent(cFrame)
    
    local mapHeaderTime = -1
    mapHeader:SetScript("OnUpdate", function(self, elapsed)
        if mapHeaderTime > 0.1 or mapHeaderTime == -1 then
            local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition()
            if x and y and x > 0 and y > 0 and MouseIsOver(WorldMapFrame.ScrollContainer) then
                local mapId = WorldMapFrame:GetMapID()
                local info = C_Map.GetMapInfoAtPosition(mapId, x, y)
                if info then
                    mapHeader.x:SetFormattedText("Ledger\nAvg: "..GetCoinTextureString(TheArtfulDodgersLedger:GetZoneCopperPerMark(info.name)).."\nTot: "..GetCoinTextureString(TheArtfulDodgersLedger:GetZoneTotalCopper(info.name)))
                end
            end
        end
        mapHeaderTime = mapHeaderTime + elapsed
    end)
end

function TheArtfulDodgersLedger:SavePickPocketEvent(event)
    if #self.db.session >= self.db.settings.session.eventTrackingLimit then
        table.remove(self.db.session, 0)
    end
    table.insert(self.db.session, event)
end

function TheArtfulDodgersLedger:GetLootedHistoryEvent(eventIndex)
	return self.db.history[eventIndex].timestamp, self.db.history[eventIndex].mark, self.db.history[eventIndex].zone, self.db.history[eventIndex].subZone, self.db.history[eventIndex].loot
end

function TheArtfulDodgersLedger:GetLootedHistoryEventItem(loot, lootIndex)
	return loot[lootIndex].timestamp, loot[lootIndex].icon, loot[lootIndex].name, loot[lootIndex].link, loot[lootIndex].quantity, loot[lootIndex].quality, loot[lootIndex].price
end

function TheArtfulDodgersLedger:ResetAll()
    self.db.session = defaults.char.session
	self.db.history = defaults.char.history
	self.db.stats = defaults.char.stats
    TheArtfulDodgersLedger:UpdateStats()
end

function TheArtfulDodgersLedger:ResetSessionStats()
    self.db.session = defaults.char.session
	self.db.stats.session = defaults.char.stats.session
    TheArtfulDodgersLedger:UpdateStats()
end

function TheArtfulDodgersLedger:COMBAT_LOG_EVENT_UNFILTERED(event)
	local timestamp, subEvent, _, _, sourceName, _, _, destGuid, destName, _, _, _, spellName = CombatLogGetCurrentEventInfo()
	if self:IsNewPickPocketEvent(sourceName, subEvent, spellName) then
		if subEvent == "SPELL_CAST_SUCCESS" then
            local event = PickPocketEvent:New(time(), {name = destName, guid = destGuid, level = UnitLevel("target"), state = MARK_STATE.ALIVE}, GetRealZoneText(), GetSubZoneText())
            print("Successful pick pocket: ", destGuid)
			TheArtfulDodgersLedger:SavePickPocketEvent(event)
		end
    end
end

function TheArtfulDodgersLedger:IsNewPickPocketEvent(sourceName, subEvent, spellName)
	if sourceName == UnitName("player") and spellName == "Pick Pocket" then
		return true
	end
	return false
end

function TheArtfulDodgersLedger:UI_ERROR_MESSAGE(event, errorType, message)
	if (
		message == ERR_ALREADY_PICKPOCKETED or 
		message == SPELL_FAILED_TARGET_NO_POCKETS or 
		message == SPELL_FAILED_ONLY_STEALTHED or 
		message == SPELL_FAILED_ONLY_SHAPESHIFT) then
        print("Pick pocket actually failed, deleting most recent")
        table.remove(self.db.session, #self.db.session)
    end
end

function TheArtfulDodgersLedger:LOOT_OPENED(event, slotNumber)
    local markIndex, guid, isLootable
    local loot = {}
    local numLootItems = GetNumLootItems()
    for slotNumber = 1, numLootItems do
        local guid1, quant1, guid2, quant2 = GetLootSourceInfo(slotNumber)
        markIndex = TheArtfulDodgersLedger:GetPickPocketMarkIndex(guid1)
        if markIndex then
            local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(slotNumber)
            isLootable, _ = CanLootUnit(guid1)
            if slotNumber > 1 and lootName then
                local lootLink = GetLootSlotLink(slotNumber)
                local newItem = Item:CreateFromItemLink(lootLink)
                newItem:ContinueOnItemLoad(function()
                    local itemName, itemLink, _, _, _, itemType, itemSubType, _, _, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, _, _, isCraftingReagent = GetItemInfo(lootLink)
                    local itemId = newItem:GetItemID()
                    local item = {name=lootName, link=lootLink, quantity=lootQuantity, quality=lootQuality, icon=itemIcon, price=itemSellPrice}
                    if TheArtfulDodgersLedger:IsJunkbox(itemId) then
                        item.price = TheArtfulDodgersLedger:GetJunkboxPrice(itemId)     
                    end
                    table.insert(loot, item)		
                end)
            else
                local item = {name=CURRENCY_STRING, link=CURRENCY_LINK, quantity=1, quality=1, icon=CURRENCY_ICON_ID, price=self:GetCopperFromLootName(lootName)}
                table.insert(loot, item)
            end
        end
    end
    if markIndex then
        local shouldSaveToHistory = TheArtfulDodgersLedger:UpdateSessionLootState(markIndex, loot, isLootable)
        if shouldSaveToHistory then
            TheArtfulDodgersLedger:SavePickPocketHistory(markIndex) 
        end
    end 
end

function TheArtfulDodgersLedger:UpdateSessionLootState(markIndex, loot, isLootable)
    local event = self.db.session[markIndex]
    local mark = self.db.session[markIndex].mark
    if isLootable then
        if mark.state == MARK_STATE.ALIVE then
            print("Looting while dead, received loot while alive, skipping: ", mark.guid)
            return false
        else
            print("Looting while dead, deleting previous loot: ", mark.guid)
            TheArtfulDodgersLedger:DeletePickPocketHistoryByGuid(mark.guid)
        end
    end
    event.loot = loot
    return true
end

function TheArtfulDodgersLedger:GetTotalCopperFromHistory()
    local copper = 0;
    for event = 1, #self.db.history do
        for i = 1, table.getn(self.db.history[event].loot) do
		  copper = copper + self.db.history[event].loot[i].price
        end
	end
    return copper
end

function TheArtfulDodgersLedger:GetTotalCopperPerZone()
    local zones = {}
    for event = 1, #self.db.history do
        local zone = self.db.history[event].zone
        if zone then
            local copper = 0
            for i = 1, #self.db.history[event].loot do
                 copper = copper + self.db.history[event].loot[i].price
            end
            if not zones[zone] then
                zones[zone] = {copper = 0, marks = 0}
            end
            zones[zone].copper = zones[zone].copper + copper
            zones[zone].marks = zones[zone].marks + 1
        end
    end
    return zones
end

function TheArtfulDodgersLedger:GetTotalCopperFromSession()
    local copper = 0;
    for event = 1, #self.db.session do
        for i = 1, table.getn(self.db.session[event].loot) do
		  copper = copper + self.db.session[event].loot[i].price
        end
	end
    return copper
end

function TheArtfulDodgersLedger:SavePickPocketHistory(markIndex)
    print("Saving to history: ", self.db.session[markIndex]:ToString())
    table.insert(self.db.history, self.db.session[markIndex])
    self:SortGlobalLootedHistoryTable()
end

function TheArtfulDodgersLedger:SortGlobalLootedHistoryTable()
	table.sort(self.db.history, function(a,b) return a.timestamp > b.timestamp end)
end

function TheArtfulDodgersLedger:SortTable(columnName)
	table.sort(self.db.history, function(a,b) return a[columnName] > b[columnName] end)
end

function TheArtfulDodgersLedger:GetItemSellValueTotal(markIndex)
	local totalCopper = 0
	for i = 1, table.getn(self.db.session[markIndex].loot) do
		totalCopper = totalCopper + self.db.session[markIndex].loot[i].price
	end
	return totalCopper
end

function TheArtfulDodgersLedger:GetZoneCopperPerMark(zone)
	local zoneStats = self.db.stats.zones[zone] --TheArtfulDodgersLedger:GetZoneLootStats(zone)
    if zoneStats then
	   return TheArtfulDodgersLedger:GetCopperPerMark(zoneStats.copper, zoneStats.marks)
    end
    return 0
end

function TheArtfulDodgersLedger:GetZoneTotalCopper(zone)
    local zone = self.db.stats.zones[zone]
    if zone then
        return zone.copper
    end
    return 0
end

function TheArtfulDodgersLedger:GetZoneLootStats(zone)
	local copper = 0
	local marks = 0
	for event = 1, #self.db.history do
		if self.db.history[event].zone == zone then
			for loot = 1, #self.db.history[event].loot do
				marks = marks + 1
				copper = copper + self.db.history[event].loot[loot].price
			end
		end
	end
	return {marks = marks, copper = copper}
end

function TheArtfulDodgersLedger:GetPrettyPrintTotalLootedString()
	return self:GetPrettyPrintString(date("%b. %d %I:%M %p", self.db.stats.total.start), "historic", "stash", GetCoinTextureString(self.db.stats.total.copper), self.db.stats.total.marks, GetCoinTextureString(self:GetTotalCopperPerMark()))
end

function TheArtfulDodgersLedger:GetPrettyPrintSessionLootedString()
	return self:GetPrettyPrintString(date("%b. %d %I:%M %p", self.db.stats.session.start), "current", "purse", GetCoinTextureString(self.db.stats.session.copper), self.db.stats.session.marks, GetCoinTextureString(self:GetSessionCopperPerMark()))
end

function TheArtfulDodgersLedger:GetPrettyPrintString(date, period, store, copper, count, average)
	return string.format("\nSince |cffFFFFFF%s|r,\n\nYour |cff334CFF%s|r pilfering has "..GREEN_FONT_COLOR_CODE.."increased|r your %s by |cffFFFFFF%s|r \nYou've "..RED_FONT_COLOR_CODE.."picked the pockets|r of |cffFFFFFF%d|r mark(s)\nYou've "..RED_FONT_COLOR_CODE.."stolen|r an average of |cffFFFFFF%s|r from each victim", date, period, store, copper, count, average)
end

function TheArtfulDodgersLedger:GetCopperPerMark(copper, count)
	if copper and count and copper > 0 and count > 0 then
        local avg = self:Round((copper / count))
		return avg
	end
	return 0
end

function TheArtfulDodgersLedger:GetSessionCopperPerMark()
	return self:GetCopperPerMark(self.db.stats.session.copper, self.db.stats.session.marks)
end

function TheArtfulDodgersLedger:GetTotalCopperPerMark()
	return self:GetCopperPerMark(self.db.stats.total.copper, self.db.stats.total.marks)
end

function TheArtfulDodgersLedger:GetCopperPerHour(copper, seconds)
	if copper > 0 and seconds > 0 then
		return math.floor(((copper / seconds) * 3600))
	end
	return 0
end

function TheArtfulDodgersLedger:GetSessionCopperPerHour()
    return self:GetCopperPerHour(self.db.stats.session.copper, self.db.stats.session.duration)
end

function TheArtfulDodgersLedger:GetTotalCopperPerHour()
    return self:GetCopperPerHour(self.db.stats.total.copper, self.db.stats.total.duration)
end

function TheArtfulDodgersLedger:UpdateStats()
    self.db.stats.session.copper = self:GetTotalCopperFromSession()
    self.db.stats.session.marks = #self.db.session
    self.db.stats.total.copper = self:GetTotalCopperFromHistory()
    self.db.stats.total.marks = #self.db.history
    self.db.stats.zones = self:GetTotalCopperPerZone()
end

function TheArtfulDodgersLedger:Round(x)
	return x + 0.5 - (x + 0.5) % 1
end

function TheArtfulDodgersLedger:GetCopperFromLootName(lootName)
	return self:TotalCopper(self:GetCurrencyValues(lootName)) or 0
end

function TheArtfulDodgersLedger:GetCurrencyValues(money)
	local gold = money:match(GOLD_AMOUNT:gsub("%%d", "%(%%d+%)")) or 0
	local silver = 	money:match(SILVER_AMOUNT:gsub("%%d", "%(%%d+%)")) or 0
	local copper = money:match(COPPER_AMOUNT:gsub("%%d", "%(%%d+%)")) or 0
	
	return {gold=gold, silver=silver, copper=copper}
end

function TheArtfulDodgersLedger:TotalCopper(currency)
	return (currency.gold * 1000) + (currency.silver * 100) + currency.copper
end

function TheArtfulDodgersLedger:ChatCommand(input)
	local input = strlower(input)
	
	if input == 'global' then
		print(self:GetPrettyPrintTotalLootedString())
	elseif input == 'session' then
		print(self:GetPrettyPrintSessionLootedString())
	elseif input == 'show' then
		self:ShowFrame()
	elseif input == 'clear' then
		self:ResetLoot()
	elseif input == "help" or input == "" then
		print('Usage')
		print('/adl help')
		print('/adl global - Total stats from Pick Pocketing')
		print('/adl session - Current stats from Pick Pocketing')
		print('/adl clear - Clear Pick Pocketing data')
	end
end