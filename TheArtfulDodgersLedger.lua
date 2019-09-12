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
							timestamp=0,
							mark=""
						 }

local LOOT_CLEARED_COUNT = 0
local LOOT_READY_ITEMS = {}

function TheArtfulDodgersLedger:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("UI_ERROR_MESSAGE")
	self:RegisterEvent("LOOT_READY")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("CHAT_MSG_MONEY")
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
	scrollcontainer:SetFullHeight(true)
	scrollcontainer:SetLayout("Fill")

	--frame:AddChild(scrollcontainer)

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("Flow")
	--scrollcontainer:AddChild(scroll)
	
	for i = 1, table.getn(GLOBAL_LOOTED_HISTORY) do
		for x = 1, table.getn(GLOBAL_LOOTED_HISTORY[i].loot) do
			local label = AceGUI:Create("Label")
			if GLOBAL_LOOTED_HISTORY[i].loot[x].icon ~= nil then
				print("setimage", GLOBAL_LOOTED_HISTORY[i].icon)
				label:SetImage(GetItemIcon(GLOBAL_LOOTED_HISTORY[i].loot[x].icon))
			else
				label:SetImage(GetItemIcon(11966))
			end
			label:SetText(GLOBAL_LOOTED_HISTORY[i].loot[x].name.." - "..GLOBAL_LOOTED_HISTORY[i].loot[x].quantity.." - "..GLOBAL_LOOTED_HISTORY[i].loot[x].price.." - "..GLOBAL_LOOTED_HISTORY[i].timestamp.." - "..GLOBAL_LOOTED_HISTORY[i].mark)
			frame:AddChild(label)
		end
	end
	
	local globalLabel = AceGUI:Create("Label")
	globalLabel:SetText(self:GetPrettyPrintGlobalLootedString())
	frame:AddChild(globalLabel)
	
	local sessionLabel = AceGUI:Create("Label")
	sessionLabel:SetText(self:GetPrettyPrintSessionLootedString())
	frame:AddChild(sessionLabel)
	
	local resetButton = AceGUI:Create("Button")
	resetButton:SetText("Reset All Stats")
	resetButton:SetWidth(200)
	frame:AddChild(resetButton)
	
	local icon = AceGUI:Create("Icon")
	icon:SetImage(GetItemIcon(4544))
	frame:AddChild(icon)
end

function TheArtfulDodgersLedger:ResetLoot()
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
							timestamp=0,
							mark=""
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
	end
end

function TheArtfulDodgersLedger:IsPickpocketEvent(sourceName, subEvent, spellName)
	if sourceName == UnitName("player") and subEvent == "SPELL_CAST_SUCCESS" and spellName == "Pick Pocket" then
		return true
	end
	return false
end

function TheArtfulDodgersLedger:UI_ERROR_MESSAGE(event, errorType, message)
	if message == ERR_ALREADY_PICKPOCKETED or message == SPELL_FAILED_TARGET_NO_POCKETS then
		self:Reset()
	end
end

function TheArtfulDodgersLedger:LOOT_READY(event, slot)
	local epochTime = time()
	if PICKPOCKET_ACTIVE == true then
		for i = 1, GetNumLootItems() do
			local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i)
			local currencyValue = self:GetCopperFromLootName(lootName)
			local lootPrice = select(11, GetItemInfo(lootName))
			local thing = select(2, GetItemInfo(lootName))
			if thing ~= nil then
				print(lootIcon, thing)
				lootIcon = tonumber(strmatch(thing, "item:(%d+)"))
			else
				lootIcon = 11966
			end
			print(lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive)
			if currencyValue > 0 then
				lootName = "Currency"
				lootPrice = currencyValue
			end
			if self:PickpocketLootItemsContains(lootName, epochTime) == false then
				table.insert(LOOT_READY_ITEMS, {timestamp=epochTime, icon=lootIcon, name=lootName, quantity=lootQuantity, quality=lootQuality, price=lootPrice})
			end
		end
		if UnitAffectingCombat('player')== true and (epochTime - PICKPOCKET_TIMESTAMP) < 3 then
			self:EndPickpocketEvent()
		end
	end
end

function TheArtfulDodgersLedger:LOOT_SLOT_CLEARED(event, slot)
	if PICKPOCKET_ACTIVE == true then
		LOOT_CLEARED_COUNT = LOOT_CLEARED_COUNT + 1
		if GetNumLootItems() == LOOT_CLEARED_COUNT then 
			PICKPOCKET_LOOTED = true
		end
	end
end

function TheArtfulDodgersLedger:CHAT_MSG_MONEY(event, message)
	if PICKPOCKET_ACTIVE == true and PICKPOCKET_LOOTED == true then
		self:EndPickpocketEvent()
	end
end

function TheArtfulDodgersLedger:EndPickpocketEvent()
	local itemCopper = self:GetItemSellValueTotal()
	table.insert(GLOBAL_LOOTED_HISTORY, {timestamp=PICKPOCKET_EVENT.timestamp, mark=PICKPOCKET_EVENT.mark, loot=LOOT_READY_ITEMS})
	self:AddToLootedCopper(itemCopper)
	self:AddToLootedCounts(1)
	self:Reset()
end

function TheArtfulDodgersLedger:GetItemSellValueTotal()
	local totalCopper = 0
	for i = 1, table.getn(LOOT_READY_ITEMS) do
		if LOOT_READY_ITEMS[i].timestamp == LOOT_READY_ITEMS[1].timestamp and LOOT_READY_ITEMS[i].price ~= nil then
			totalCopper = totalCopper + LOOT_READY_ITEMS[i].price
		end
	end
	
	return totalCopper
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

function TheArtfulDodgersLedger:PickpocketLootItemsContains(key, timestamp)
	for i = 1, table.getn(LOOT_READY_ITEMS) do
		if LOOT_READY_ITEMS[i].name == key and LOOT_READY_ITEMS[i].timestamp == timestamp then
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