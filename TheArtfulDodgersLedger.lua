TheArtfulDodgersLedger = LibStub("AceAddon-3.0"):NewAddon("TheArtfulDodgersLedger", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

if UnitClass('player') ~= 'Rogue' then
	return
end

-- Global variables set to track copper and pick pocket counts that persist
-- GLOBAL_LOOTED_COPPER
-- GLOBAL_LOOTED_COUNT

local SESSION_LOOTED_COPPER = 0
local SESSION_LOOTED_COUNT = 0

local PICKPOCKET_ACTIVE = false
local PICKPOCKET_TIMESTAMP = 0
local PICKPOCKET_ERROR = false
local PICKPOCKET_READY = false
local PICKPOCKET_LOOTED = false
local PICKPOCKET_EVENT = {
							active=false, 
							looted=false,
							lootCount=0,
							timestamp=0,
							mark="",
							zone="",
							subZone=""
						 }

local LOOT_CLEARED_COUNT = 0
local LOOT_READY_ITEMS = {}

local CURRENCY_COLOR = "|cFFCC9900"
local CURRENCY_STRING = "Coin"
local CURRENCY_LINK = CURRENCY_COLOR.."["..CURRENCY_STRING.."]|r"
local CURRENCY_ICON_ID = 11966

local LOOT_TOTAL_STRING = "Pilfered coins:  %s"
local LOOT_MARKS_STRING = "Pockets picked:  %d"
local LOOT_AVERAGE_STRING = "Average per mark:  %s"

local DATE_FORMAT = "%b. %d - %I:%M %p"

function TheArtfulDodgersLedger:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("LOOT_READY")
	--self:RegisterEvent("LOOT_SLOT_CLEARED")
	--self:RegisterEvent("CHAT_MSG_MONEY")
end

function TheArtfulDodgersLedger:OnDisable()
	self:Reset()
end

function TheArtfulDodgersLedger:ShowFrame()
	local frame = AceGUI:Create("Frame")
	frame:SetTitle("The Artful Dodger's Ledger")
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame:SetLayout("Flow")

	local header = AceGUI:Create("Heading")
	header:SetText("Total Accounting")
	header:SetRelativeWidth(1)
	frame:AddChild(header)
	
	scrollcontainer = AceGUI:Create("SimpleGroup")
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetLayout("Fill")
	scrollcontainer:SetPoint("TOP")

	frame:AddChild(scrollcontainer)

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	scrollcontainer:AddChild(scroll)
	
	for event = 1, table.getn(GLOBAL_LOOTED_HISTORY) do
		local eventTime, mark, zone, subZone, loot = self:GetLootedHistoryEvent(event)
		for item = 1, table.getn(loot) do
			local label = AceGUI:Create("InteractiveLabel")
			local _, icon, name, link, quantity, _, price = self:GetLootedHistoryEventItem(loot, item)
			if icon ~= nil then
				label:SetImage(GetItemIcon(icon))
			else
				label:SetImage(GetItemIcon(CURRENCY_ICON_ID))
			end
			local priceString = price
			if priceString ~= nil then
				priceString = GetCoinTextureString(price)
			end
			label:SetText(date(DATE_FORMAT, eventTime).."|  "..zone.." - "..subZone.."   "..mark.."   "..link.."   "..quantity.."   "..priceString)
			label:SetFullWidth(true)
			label:SetPoint("CENTER")
			scroll:AddChild(label)
		end
	end
	
	totalContainer = AceGUI:Create("SimpleGroup")
	totalContainer:SetFullWidth(true)
	totalContainer:SetLayout("Flow")
	frame:AddChild(totalContainer)
	
	local globalLabel = AceGUI:Create("Label")
	globalLabel:SetText(string.format(LOOT_TOTAL_STRING, GetCoinTextureString(GLOBAL_LOOTED_COPPER)))
	totalContainer:AddChild(globalLabel)
	
	local sessionLabel = AceGUI:Create("Label")
	sessionLabel:SetText(string.format(LOOT_MARKS_STRING, GLOBAL_LOOTED_COUNT))
	totalContainer:AddChild(sessionLabel)
	
	local averageLabel = AceGUI:Create("Label")
	averageLabel:SetText(string.format(LOOT_AVERAGE_STRING, GetCoinTextureString(self:GetGlobalAverage())))
	totalContainer:AddChild(averageLabel)
	
	local controlContainer = AceGUI:Create("SimpleGroup")
	controlContainer:SetFullWidth(true)
	controlContainer:SetLayout("Flow")
	frame:AddChild(controlContainer)
	
	local resetButton = AceGUI:Create("Button")
	resetButton:SetText("Reset All Stats")
	resetButton:SetWidth(200)
	controlContainer:AddChild(resetButton)
end

function TheArtfulDodgersLedger:GetLootedHistoryEvent(eventIndex)
	return GLOBAL_LOOTED_HISTORY[eventIndex].timestamp, GLOBAL_LOOTED_HISTORY[eventIndex].mark, GLOBAL_LOOTED_HISTORY[eventIndex].zone, GLOBAL_LOOTED_HISTORY[eventIndex].subZone, GLOBAL_LOOTED_HISTORY[eventIndex].loot
end

function TheArtfulDodgersLedger:GetLootedHistoryEventItem(loot, lootIndex)
	return loot[lootIndex].timestamp, loot[lootIndex].icon, loot[lootIndex].name, loot[lootIndex].link, loot[lootIndex].quantity, loot[lootIndex].quality, loot[lootIndex].price
end

function TheArtfulDodgersLedger:ResetLoot()
	LOOT_READY_ITEMS = {}
	GLOBAL_LOOTED_HISTORY = {}
    GLOBAL_LOOTED_COPPER = 0
	GLOBAL_LOOTED_COUNT = 0
	SESSION_LOOTED_COPPER = 0
	SESSION_LOOTED_COUNT = 0
end

function TheArtfulDodgersLedger:Reset()
    PICKPOCKET_ACTIVE = false
	PICKPOCKET_ERROR = false
	PICKPOCKET_READY = false
	PICKPOCKET_LOOTED = false
	LOOT_READY_ITEMS = {}
	LOOT_CLEARED_COUNT = 0
	local PICKPOCKET_EVENT = {
							active=false,
							looted=false,
							lootCount=0,
							timestamp=0,
							mark="",
							zone="",
							subZone=""
						 }
end

function TheArtfulDodgersLedger:OnInitialize()
	self:RegisterChatCommand('adl', "ChatCommand")
	if GLOBAL_LOOTED_COPPER == nil then
		GLOBAL_LOOTED_COPPER = 0
	end
	if GLOBAL_LOOTED_COUNT == nil then
		GLOBAL_LOOTED_COUNT = 0
	end
	if GLOBAL_LOOTED_HISTORY == nil then
		GLOBAL_LOOTED_HISTORY = {}
	end
	CreateFrame("FRAME", testframe, UIParent)
end

function TheArtfulDodgersLedger:COMBAT_LOG_EVENT_UNFILTERED(event)
	local timestamp, subEvent, _, _, sourceName, _, _, _, destName, _, _, _, spellName = CombatLogGetCurrentEventInfo()
    if self:IsPickpocketEvent(sourceName, subEvent, spellName) then
		self:Reset()
        PICKPOCKET_ACTIVE = true
		PICKPOCKET_TIMESTAMP = time()
		PICKPOCKET_EVENT.active = true
		PICKPOCKET_EVENT.timestamp = time()
		PICKPOCKET_EVENT.mark = destName
		PICKPOCKET_EVENT.zone = GetRealZoneText()
		PICKPOCKET_EVENT.subZone = GetSubZoneText()
		print(PICKPOCKET_TIMESTAMP, sourceName, subEvent, spellName)
	end
end

function TheArtfulDodgersLedger:IsPickpocketEvent(sourceName, subEvent, spellName)
	if sourceName == UnitName("player") and subEvent == "SPELL_CAST_SUCCESS" and spellName == "Pick Pocket" then
		return true
	end
	return false
end

function TheArtfulDodgersLedger:UI_ERROR_MESSAGE(event, errorType, message)
	if message == ERR_ALREADY_PICKPOCKETED or message == SPELL_FAILED_TARGET_NO_POCKETS or message == RESIST then
		print(PICKPOCKET_TIMESTAMP, event, errorType, message)
		self:Reset()
	end
end

function TheArtfulDodgersLedger:LOOT_READY(event, slot)
	local epochTime = time()
	if PICKPOCKET_EVENT.active == true then
		for i = 1, GetNumLootItems() do
			local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i)
			local currencyValue = self:GetCopperFromLootName(lootName)
			local lootPrice = select(11, GetItemInfo(lootName)) or 0
			local lootLink = select(2, GetItemInfo(lootName))
			if lootLink ~= nil then
				lootIcon = tonumber(strmatch(lootLink, "item:(%d+)"))
			else
				lootLink = ""
			end
			if currencyValue > 0 then
				lootName = CURRENCY_STRING
				lootIcon = CURRENCY_ICON_ID
				lootQuantity = 1
				lootPrice = currencyValue
				lootLink = CURRENCY_LINK
			end
			--if self:PickpocketLootItemsContains(lootName, epochTime) == false then
			print(event, "insert", epochTime, lootName)
			table.insert(LOOT_READY_ITEMS, {timestamp=epochTime, icon=lootIcon, name=lootName, link=lootLink, quantity=lootQuantity, quality=lootQuality, price=lootPrice})
			--end
		end
		PICKPOCKET_EVENT.active = false
		self:EndPickpocketEvent()
		--if UnitAffectingCombat('player')== true and self:FuzzyMatchingTimestamp(epochTime, PICKPOCKET_EVENT.timestamp) == true then
		--	PICKPOCKET_EVENT.active = false
		--	self:EndPickpocketEvent()
		--end
	end
end

function TheArtfulDodgersLedger:LOOT_SLOT_CLEARED(event, slot)
	if PICKPOCKET_EVENT.active == true then
		PICKPOCKET_EVENT.lootCount = PICKPOCKET_EVENT.lootCount + 1
		if GetNumLootItems() == PICKPOCKET_EVENT.lootCount then 
			print(event, slot, "PICKPOCKET_LOOTED", "count=", PICKPOCKET_EVENT.lootCount)
			PICKPOCKET_EVENT.looted = true
		end
	end
end

function TheArtfulDodgersLedger:CHAT_MSG_MONEY(event, message)
	if PICKPOCKET_EVENT.active == true and PICKPOCKET_EVENT.looted == true then
		print(event, message, "PICKPOCKET_ACTIVE AND LOOTED")
		self:EndPickpocketEvent()
	end
end

function TheArtfulDodgersLedger:EndPickpocketEvent()
	print("endpickpocket", PICKPOCKET_EVENT.timestamp, PICKPOCKET_EVENT.mark)
	local itemCopper = self:GetItemSellValueTotal()
	table.insert(GLOBAL_LOOTED_HISTORY, {timestamp=PICKPOCKET_EVENT.timestamp, mark=PICKPOCKET_EVENT.mark, zone=PICKPOCKET_EVENT.zone, subZone=PICKPOCKET_EVENT.subZone, loot=LOOT_READY_ITEMS})
	self:SortGlobalLootedHistoryTable()
	self:AddToLootedCopper(itemCopper)
	self:AddToLootedCounts(1)
	self:Reset()
end

function TheArtfulDodgersLedger:GetItemSellValueTotal()
	local totalCopper = 0
	for i = 1, table.getn(LOOT_READY_ITEMS) do
		local timestamp = LOOT_READY_ITEMS[i].timestamp
		if timestamp ~= nil and self:FuzzyMatchingTimestamp(timestamp, PICKPOCKET_EVENT.timestamp) then
			print("Adding: ", LOOT_READY_ITEMS[i].name, LOOT_READY_ITEMS[i].price)
			totalCopper = totalCopper + LOOT_READY_ITEMS[i].price
		end
	end
	
	return totalCopper
end

function TheArtfulDodgersLedger:SortGlobalLootedHistoryTable()
	table.sort(GLOBAL_LOOTED_HISTORY, function(a,b) return a.timestamp > b.timestamp end)
end

function TheArtfulDodgersLedger:AddToLootedCounts(count)
	GLOBAL_LOOTED_COUNT = GLOBAL_LOOTED_COUNT + count
	SESSION_LOOTED_COUNT = SESSION_LOOTED_COUNT + count
end

function TheArtfulDodgersLedger:AddToLootedCopper(totalCopper)
	GLOBAL_LOOTED_COPPER = GLOBAL_LOOTED_COPPER + totalCopper
	SESSION_LOOTED_COPPER = SESSION_LOOTED_COPPER + totalCopper
end

function TheArtfulDodgersLedger:GetPrettyPrintGlobalLootedString()
	return self:GetPrettyPrintString("historic", "stash", GetCoinTextureString(GLOBAL_LOOTED_COPPER), GLOBAL_LOOTED_COUNT, GetCoinTextureString(self:GetGlobalAverage()))
end

function TheArtfulDodgersLedger:GetPrettyPrintSessionLootedString()
	return self:GetPrettyPrintString("current", "purse", GetCoinTextureString(SESSION_LOOTED_COPPER), SESSION_LOOTED_COUNT, GetCoinTextureString(self:GetSessionAverage()))
end

function TheArtfulDodgersLedger:GetPrettyPrintString(period, store, copper, count, average)
	return string.format("Your %s pilfering has increased your %s by %s. You've pick pocketed from %d mark(s) and stolen an average of %s from each victim.", period, store, copper, count, average)
end

function TheArtfulDodgersLedger:CalculateAverageCopperPerMark(copper, count)
	if copper > 0 and count > 0 then
		return self:Round((copper / count))
	end
	return 0
end

function TheArtfulDodgersLedger:GetSessionAverage()
	return self:CalculateAverageCopperPerMark(SESSION_LOOTED_COPPER, SESSION_LOOTED_COUNT)
end

function TheArtfulDodgersLedger:GetGlobalAverage()
	return self:CalculateAverageCopperPerMark(GLOBAL_LOOTED_COPPER, GLOBAL_LOOTED_COUNT)
end

function TheArtfulDodgersLedger:Round(x)
	return x + 0.5 - (x + 0.5) % 1
end

function TheArtfulDodgersLedger:FuzzyMatchingTimestamp(timestamp1, timestamp2)
	return math.abs((tonumber(timestamp1) - tonumber(timestamp2))) < 2
end

function TheArtfulDodgersLedger:PickpocketLootItemsContains(key, timestamp)
	for item = 1, table.getn(LOOT_READY_ITEMS) do
		local itemName = LOOT_READY_ITEMS[item].name
		local itemTimestamp = LOOT_READY_ITEMS[item].timestamp
		if itemName == key and self:FuzzyMatchingTimestamp(timestamp, itemTimestamp) then
			print("true")
			return true
		end
	end
	return false
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