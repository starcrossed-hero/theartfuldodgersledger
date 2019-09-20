TheArtfulDodgersLedger = LibStub("AceAddon-3.0"):NewAddon("TheArtfulDodgersLedger", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")

if UnitClass('player') ~= 'Rogue' then
	return
end

local SESSION_LOOTED_COPPER = 0
local SESSION_LOOTED_COUNT = 0

local LOOT_CLEARED_COUNT = 0
local LOOT_READY_ITEMS = {}

local CURRENCY_COLOR = "|cFFCC9900"
local CURRENCY_STRING = "Coin"
local CURRENCY_LINK = CURRENCY_COLOR.."["..CURRENCY_STRING.."]|r"
local CURRENCY_ICON_ID = 11966

local LOOT_TOTAL_STRING = "Pilfered coins:  %s"
local LOOT_MARKS_STRING = "Pockets picked:  %d"
local LOOT_AVERAGE_STRING = "Average per mark:  %s"

local DATE_FORMAT = "%b. %d \n%I:%M %p"

local EVENT_STATE = {
	ACTIVE = 1,
	INACTIVE = 2,
	ERROR = 3,
	LOOTED = 4
}

local JUNKBOX = {
	BATTERED = 16882,
	WORN = 16883,
	STURDY = 16884,
	HEAVY = 16885
}

PickPocketEvent = {}
PickPocketEvent.__index = PickPocketEvent
function PickPocketEvent:New(eventTime, eventState, eventMark, eventZone, eventSubZone)
	local this = {
		timestamp = eventTime or 0,
		state = eventState or EVENT_STATE.INACTIVE,
		mark = eventMark or "",
		zone = eventZone or "",
		subZone = eventSubZone or ""
	}
	setmetatable(this, self)
	return this
end
function PickPocketEvent:CreateRow()
	return {timestamp=self.timestamp, mark=self.mark, zone=self.zone, subZone=self.subZone}
end
function PickPocketEvent:ToString()
	return string.format("PickPocketEvent: timestamp=%d, state=%s, mark=%s, zone=%s, subZone=%s", self.timestamp, self.state, self.mark, self.zone, self.subZone)
end

local CURRENT_EVENT = {}

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
			CURRENT_EVENT = PickPocketEvent:New(time(), EVENT_STATE.ACTIVE, itemLink)
		end
	end
end

function TheArtfulDodgersLedger:InTable(tbl, item)
    for key, value in pairs(tbl) do
        if value == item then return true end
    end
    return false
end

function TheArtfulDodgersLedger:ShowFrame()
	local frame = AceGUI:Create("Frame")
	frame:SetTitle("The Artful Dodger's Ledger")
	frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
	frame:SetLayout("Flow")
    frame:SetHeight(600)

	local header = AceGUI:Create("Heading")
	header:SetText("Recent Victims")
	header:SetRelativeWidth(1)
	frame:AddChild(header)
    
    local tableHeader = AceGUI:Create("SimpleGroup")
	tableHeader:SetFullWidth(true)
	tableHeader:SetLayout("Flow")

	local timeHeader = AceGUI:Create("Label")
	timeHeader:SetText("Time")
	timeHeader:SetRelativeWidth(0.1)
    timeHeader:SetFontObject(GameFontRedLarge)
	local zoneHeader = AceGUI:Create("Label")
	zoneHeader:SetText("Zone")
	zoneHeader:SetRelativeWidth(0.1)
    zoneHeader:SetFontObject(GameFontRedLarge)
	local subZoneHeader = AceGUI:Create("Label")
	subZoneHeader:SetText("Sub-Zone")
	subZoneHeader:SetRelativeWidth(0.15)
    subZoneHeader:SetFontObject(GameFontRedLarge)
	local markHeader = AceGUI:Create("Label")
	markHeader:SetText("Mark")
	markHeader:SetRelativeWidth(0.25)
    markHeader:SetFontObject(GameFontRedLarge)
	local linkHeader = AceGUI:Create("Label")
	linkHeader:SetText("Item")
	linkHeader:SetRelativeWidth(0.10)
    linkHeader:SetFontObject(GameFontRedLarge)
	local quantityHeader = AceGUI:Create("Label")
	quantityHeader:SetText("Qty")
	quantityHeader:SetRelativeWidth(0.1)
    quantityHeader:SetFontObject(GameFontRedLarge)
	local priceHeader = AceGUI:Create("Label")
	priceHeader:SetText("Value")
	priceHeader:SetRelativeWidth(0.1)
    priceHeader:SetFontObject(GameFontRedLarge)

	tableHeader:AddChild(timeHeader)
	tableHeader:AddChild(zoneHeader)
	tableHeader:AddChild(subZoneHeader)
	tableHeader:AddChild(markHeader)
	tableHeader:AddChild(linkHeader)
	tableHeader:AddChild(quantityHeader)
	tableHeader:AddChild(priceHeader)

	frame:AddChild(tableHeader)
	
	scrollcontainer = AceGUI:Create("SimpleGroup")
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetLayout("Fill")
	scrollcontainer:SetPoint("TOP")
    scrollcontainer:SetHeight(400)

	frame:AddChild(scrollcontainer)

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	scrollcontainer:AddChild(scroll)
	
	for event = 1, 10 do
		local eventTime, mark, zone, subZone, loot = self:GetLootedHistoryEvent(event)
		local row = AceGUI:Create("SimpleGroup")
		row:SetFullWidth(true)
		row:SetLayout("Flow")
		for item = 1, table.getn(loot) do
			local _, icon, name, link, quantity, _, price = self:GetLootedHistoryEventItem(loot, item)
			local timeLabel = AceGUI:Create("Label")
			local zoneLabel = AceGUI:Create("Label")
			local subZoneLabel = AceGUI:Create("Label")
			local markLabel = AceGUI:Create("Label")
			local itemIcon = AceGUI:Create("Icon")
			local linkLabel = AceGUI:Create("InteractiveLabel")
			local quantityLabel = AceGUI:Create("Label")
			local priceLabel = AceGUI:Create("Label")
			if icon ~= nil then
				itemIcon:SetImage(icon)
			end
            if name == CURRENCY_STRING then
               itemIcon:SetImage(GetItemIcon(icon)) 
            end
			local priceString = price
			if priceString ~= nil then
				priceString = GetCoinTextureString(price)
			end
			timeLabel:SetText(date(DATE_FORMAT, eventTime))
			timeLabel:SetRelativeWidth(0.1)
			zoneLabel:SetText(zone)
			zoneLabel:SetRelativeWidth(0.1)
			subZoneLabel:SetText(subZone)
			subZoneLabel:SetRelativeWidth(0.15)
			markLabel:SetText(mark)
			markLabel:SetRelativeWidth(0.2)
            markLabel:SetPoint("CENTER")
			itemIcon:SetImageSize(20,20)
            itemIcon:SetLabel(link)
            itemIcon:SetRelativeWidth(0.2)
			quantityLabel:SetText(quantity)
			quantityLabel:SetRelativeWidth(0.08)
			priceLabel:SetText(priceString)
			priceLabel:SetRelativeWidth(0.08)
			row:AddChild(timeLabel)
			row:AddChild(zoneLabel)
			row:AddChild(subZoneLabel)
			row:AddChild(markLabel)
			row:AddChild(itemIcon)
			row:AddChild(quantityLabel)
			row:AddChild(priceLabel)
		end
		scroll:AddChild(row)
	end
    
    local header = AceGUI:Create("Heading")
	header:SetText("Total Stolen")
	header:SetRelativeWidth(1)
	frame:AddChild(header)
	
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
	
	local resetButton = AceGUI:Create("Button")
	resetButton:SetText("Reset All Stats")
	resetButton:SetWidth(200)
	totalContainer:AddChild(resetButton)
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
	LOOT_READY_ITEMS = {}
	LOOT_CLEARED_COUNT = 0
	CURRENT_EVENT = PickPocketEvent:New()
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
	if self:IsPickPocketEvent(sourceName, subEvent, spellName) then
		self:Reset()
		CURRENT_EVENT = PickPocketEvent:New(time(), EVENT_STATE.ACTIVE, destName, GetRealZoneText(), GetSubZoneText())
	end
end

function TheArtfulDodgersLedger:IsPickPocketEvent(sourceName, subEvent, spellName)
	if sourceName == UnitName("player") and subEvent == "SPELL_CAST_SUCCESS" and spellName == "Pick Pocket" then
		return true
	end
	return false
end

function TheArtfulDodgersLedger:UI_ERROR_MESSAGE(event, errorType, message)
	if message == ERR_ALREADY_PICKPOCKETED or message == SPELL_FAILED_TARGET_NO_POCKETS or message == RESIST then
		CURRENT_EVENT.state = EVENT_STATE.ERROR
		print(CURRENT_EVENT.timestamp, CURRENT_EVENT.state, event, errorType, message)
	end
end

function TheArtfulDodgersLedger:LOOT_READY(autoloot)
	if CURRENT_EVENT and (CURRENT_EVENT.state == EVENT_STATE.ACTIVE) then
		for i = 1, GetNumLootItems() do
			local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i)
			if i > 1 then
                local lootLink = GetLootSlotLink(i)
                local newItem = Item:CreateFromItemLink(lootLink)
                newItem:ContinueOnItemLoad(function()
                    local itemName, itemLink, _, _, _, itemType, itemSubType, _, _, itemIcon, itemSellPrice, itemClassID, itemSubClassID, bindType, _, _, isCraftingReagent = GetItemInfo(lootLink)
                    print("Inserting: ", itemName, itemLink, itemSellPrice, itemIcon)
					table.insert(LOOT_READY_ITEMS, {name=lootName, link=lootLink, quantity=lootQuantity, quality=lootQuality, icon=itemIcon, price=itemSellPrice})
				end)
			else
                print("Inserting: ", CURRENCY_STRING, CURRENCY_LINK, self:GetCopperFromLootName(lootName))
                table.insert(LOOT_READY_ITEMS, {name=CURRENCY_STRING, link=CURRENCY_LINK, quantity=1, quality=1, icon=CURRENCY_ICON_ID, price=self:GetCopperFromLootName(lootName)})
			end
		end
		CURRENT_EVENT.state = EVENT_STATE.LOOTED
		self:EndPickpocketEvent()
	end
end

function TheArtfulDodgersLedger:CHAT_MSG_MONEY(event, message)
	if CURRENT_EVENT.state == EVENT_STATE.ACTIVE then
		self:EndPickpocketEvent()
	end
end

function TheArtfulDodgersLedger:EndPickpocketEvent()
	local itemCopper = self:GetItemSellValueTotal()
	print(CURRENT_EVENT:ToString())
	table.insert(GLOBAL_LOOTED_HISTORY, {timestamp=CURRENT_EVENT.timestamp, mark=CURRENT_EVENT.mark, zone=CURRENT_EVENT.zone, subZone=CURRENT_EVENT.subZone, loot=LOOT_READY_ITEMS})
	self:SortGlobalLootedHistoryTable()
	self:AddToLootedCopper(itemCopper)
	self:AddToLootedCounts(1)
	self:Reset()
end

function TheArtfulDodgersLedger:GetItemSellValueTotal()
	local totalCopper = 0
	for i = 1, table.getn(LOOT_READY_ITEMS) do
		print("Adding: item=", LOOT_READY_ITEMS[i].name, ", price=", LOOT_READY_ITEMS[i].price)
		totalCopper = totalCopper + LOOT_READY_ITEMS[i].price
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