TheArtfulDodgersLedger = LibStub("AceAddon-3.0"):NewAddon("TheArtfulDodgersLedger", "AceConsole-3.0", "AceEvent-3.0")

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
				visible = false
			}
		},
		stats = {
			total = {
				marks = 0,
				copper = 0
			},
			session = {
				marks = 0,
				copper = 0
			}
		},
		history = {}
	}
}

local CURRENCY_COLOR = "|cFFCC9900"
local CURRENCY_STRING = "Coin"
local CURRENCY_LINK = CURRENCY_COLOR.."["..CURRENCY_STRING.."]|r"
local CURRENCY_ICON_ID = 11966

local EVENT_STATE = {
	ACTIVE = 1,
	INACTIVE = 2,
	ERROR = 3,
	LOOTED = 4
}

local EVENT_TYPE = {
	PICKPOCKET = 1,
	JUNKBOX = 2,
	UNKNOWN = 3
}

local JUNKBOX = {
	BATTERED = 16882,
	WORN = 16883,
	STURDY = 16884,
	HEAVY = 16885
}

PickPocketEvent = {}
PickPocketEvent.__index = PickPocketEvent
function PickPocketEvent:New(eventTime, eventType, eventState, eventMark, eventZone, eventSubZone, eventLoot)
	local this = {
		timestamp = eventTime or 0,
		type = eventType or EVENT_TYPE.UNKNOWN,
		state = eventState or EVENT_STATE.INACTIVE,
		mark = eventMark or "",
		zone = eventZone or "",
		subZone = eventSubZone or "",
		loot = eventLoot or {}
	}
	setmetatable(this, self)
	return this
end

function PickPocketEvent:CreateRow()
	return {timestamp=self.timestamp, type=self.type, mark=self.mark, zone=self.zone, subZone=self.subZone, loot=self.loot}
end

function PickPocketEvent:ToString()
	return string.format("PickPocketEvent: timestamp=%d, type=%s, state=%s, mark=%s, zone=%s, subZone=%s, loot=%d", self.timestamp, self.type, self.state, self.mark, self.zone, self.subZone, table.getn(self.loot))
end

local CURRENT_EVENT

function TheArtfulDodgersLedger:OnInitialize()
	self:RegisterChatCommand('adl', "ChatCommand")
	self.db = LibStub("AceDB-3.0"):New("TheArtfulDodgersLedgerDB", defaults).char
	self.db.stats = defaults.char.stats
end

function TheArtfulDodgersLedger:OnDisable()
	self.db.stats = defaults.char.stats
end

function TheArtfulDodgersLedger:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("LOOT_READY")
	self:RegisterEvent("ITEM_LOCK_CHANGED")
end

--hooksecurefunc("ContainerFrameItemButton_OnClick", function(self, button)
	--local itemLink = GetContainerItemLink(self:GetParent():GetID(), self:GetID());
--end)

function TheArtfulDodgersLedger:ITEM_LOCK_CHANGED(event, bag, slot)
	if event and bag and slot then
		local icon, itemCount, locked, quality, readable, lootable, itemLink, isFiltered, noValue, itemID = GetContainerItemInfo(bag, slot)
		if self:InTable(JUNKBOX, itemID) then
			CURRENT_EVENT = PickPocketEvent:New(time(), EVENT_TYPE.JUNKBOX, EVENT_STATE.ACTIVE, itemLink)
		end
	end
end

function TheArtfulDodgersLedger:InTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return true end
    end
    return false
end

function TheArtfulDodgersLedger:GetLootedHistoryEvent(eventIndex)
	return self.db.history[eventIndex].timestamp, self.db.history[eventIndex].mark, self.db.history[eventIndex].zone, self.db.history[eventIndex].subZone, self.db.history[eventIndex].loot
end

function TheArtfulDodgersLedger:GetLootedHistoryEventItem(loot, lootIndex)
	return loot[lootIndex].timestamp, loot[lootIndex].icon, loot[lootIndex].name, loot[lootIndex].link, loot[lootIndex].quantity, loot[lootIndex].quality, loot[lootIndex].price
end

function TheArtfulDodgersLedger:ResetLoot()
	self.db.history = defaults.char.history
	self.db.stats = defaults.char.stats
end

function TheArtfulDodgersLedger:COMBAT_LOG_EVENT_UNFILTERED(event)
	local timestamp, subEvent, _, _, sourceName, _, _, _, destName, _, _, _, spellName = CombatLogGetCurrentEventInfo()
	if self:IsPickPocketEvent(sourceName, subEvent, spellName) then
		CURRENT_EVENT = PickPocketEvent:New(time(), EVENT_TYPE.PICKPOCKET, EVENT_STATE.ACTIVE, destName, GetRealZoneText(), GetSubZoneText())
	end
end

function TheArtfulDodgersLedger:IsPickPocketEvent(sourceName, subEvent, spellName)
	if sourceName == UnitName("player") and subEvent == "SPELL_CAST_SUCCESS" and spellName == "Pick Pocket" then
		return true
	end
	return false
end

function TheArtfulDodgersLedger:UI_ERROR_MESSAGE(event, errorType, message)
	if CURRENT_EVENT.state == EVENT_STATE.ACTIVE then
		print(CURRENT_EVENT.timestamp, CURRENT_EVENT.state, event, errorType, message)
	end
	if message == ERR_ALREADY_PICKPOCKETED or message == SPELL_FAILED_TARGET_NO_POCKETS or message == RESIST then
		CURRENT_EVENT.state = EVENT_STATE.ERROR
		self:EndPickpocketEvent()
	end
end

function TheArtfulDodgersLedger:LOOT_READY(autoloot)
	if CURRENT_EVENT and CURRENT_EVENT.state == EVENT_STATE.ACTIVE then
		local numLootItems = GetNumLootItems()
		for slotNumber = 1, numLootItems do
			local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(slotNumber)
			if slotNumber > 1 then
                local lootLink = GetLootSlotLink(i)
                local newItem = Item:CreateFromItemLink(lootLink)
                newItem:ContinueOnItemLoad(function()
                    local itemName, itemLink, _, _, _, itemType, itemSubType, _, _, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, _, _, isCraftingReagent = GetItemInfo(lootLink)
					local item = {name=lootName, link=lootLink, quantity=lootQuantity, quality=lootQuality, icon=itemIcon, price=itemSellPrice}
					print("LOOT_READY: ", item.name, item.price)
					self:AddToEventLoot(item, slotNumber, numLootItems)				
				end)
			else
				local item = {name=CURRENCY_STRING, link=CURRENCY_LINK, quantity=1, quality=1, icon=CURRENCY_ICON_ID, price=self:GetCopperFromLootName(lootName)}
				print("LOOT_READY: ", item.name, item.price)
				self:AddToEventLoot(item, slotNumber, numLootItems)
			end
		end
	end
end

function TheArtfulDodgersLedger:AddToEventLoot(lootItem, slotNumber, numLootItems)
	print("AddToEventLoot: ", lootItem.name, slotNumber, numLootItems)
	table.insert(CURRENT_EVENT.loot, lootItem)
	if slotNumber == numLootItems then
		CURRENT_EVENT.state = EVENT_STATE.LOOTED
		self:EndPickpocketEvent()
	else
end

--function TheArtfulDodgersLedger:CHAT_MSG_MONEY(event, message)
--	if CURRENT_EVENT.state == EVENT_STATE.ACTIVE then
--		self:EndPickpocketEvent()
--	end
--end

function TheArtfulDodgersLedger:EndPickpocketEvent()
	if CURRENT_EVENT.state = EVENT_STATE.LOOTED then
		local itemCopper = self:GetItemSellValueTotal()
		print(CURRENT_EVENT:ToString())
		table.insert(self.db.history, CURRENT_EVENT)
		self:SortGlobalLootedHistoryTable()
		self:AddToLootedCopper(itemCopper)
		if CURRENT_EVENT.type == EVENT_TYPE.PICKPOCKET then 
			self:AddToLootedCounts(1)
		end
	end
	CURRENT_EVENT = nil
end

function TheArtfulDodgersLedger:SortGlobalLootedHistoryTable()
	table.sort(self.db.history, function(a,b) return a.timestamp > b.timestamp end)
end

function TheArtfulDodgersLedger:GetItemSellValueTotal()
	local totalCopper = 0
	for i = 1, table.getn(CURRENT_EVENT.loot) do
		print("GetItemSellValueTotal: ", CURRENT_EVENT.loot[i].name, CURRENT_EVENT.loot[i].price)
		totalCopper = totalCopper + CURRENT_EVENT.loot[i].price
	end
	return totalCopper
end

function TheArtfulDodgersLedger:AddToLootedCounts(count)
    self.db.stats.total.marks = self.db.stats.total.marks + count
    self.db.stats.session.marks = self.db.stats.session.marks + count
end

function TheArtfulDodgersLedger:AddToLootedCopper(copper)
    self.db.stats.total.copper = self.db.stats.total.copper + copper
    self.db.stats.session.copper = self.db.stats.session.copper + copper
end

function TheArtfulDodgersLedger:GetPrettyPrintGlobalLootedString()
	return self:GetPrettyPrintString("historic", "stash", GetCoinTextureString(self.db.stats.total.copper), self.db.stats.total.marks, GetCoinTextureString(self:GetGlobalAverage()))
end

function TheArtfulDodgersLedger:GetPrettyPrintSessionLootedString()
	return self:GetPrettyPrintString("current", "purse", GetCoinTextureString(self.db.stats.session.copper), self.db.stats.session.marks, GetCoinTextureString(self:GetSessionAverage()))
end

function TheArtfulDodgersLedger:GetPrettyPrintString(period, store, copper, count, average)
	return string.format("Your %s pilfering has increased your %s by %s. You've pick pocketed from %d mark(s) and stolen an average of %s from each victim.", period, store, copper, count, average)
end

function TheArtfulDodgersLedger:CalculateAverageCopperPerMark(copper, count)
	if copper and count and copper > 0 and count > 0 then
		return self:Round((copper / count))
	end
	return 0
end

function TheArtfulDodgersLedger:GetSessionAverage()
	return self:CalculateAverageCopperPerMark(self.db.stats.session.copper, self.db.stats.session.marks)
end

function TheArtfulDodgersLedger:GetGlobalAverage()
	return self:CalculateAverageCopperPerMark(self.db.stats.total.copper, self.db.stats.total.marks)
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
		print(self:GetPrettyPrintGlobalLootedString())
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