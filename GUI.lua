local addon = LibStub("AceAddon-3.0"):GetAddon("TheArtfulDodgersLedger")
local gui = addon:NewModule("GUI")
local AceGUI = LibStub("AceGUI-3.0")

local LOOT_TOTAL_STRING = "Pilfered coins:  %s"
local LOOT_MARKS_STRING = "Pockets picked:  %d"
local LOOT_AVERAGE_STRING = "Average per mark:  %s"

local DATE_FORMAT = "%b. %d \n%I:%M %p"

function gui:OnEnable()
    self.db = addon.db
end

function gui:ShowFrame()   
	if not self.db.settings.gui.visible then

		self.db.settings.gui.visible = true

		local frame = AceGUI:Create("Frame")
		frame:SetTitle("The Artful Dodger's Ledger")
		frame:SetCallback("OnClose", function(widget)
				self.db.settings.gui.visible = false
				AceGUI:Release(widget)
			end)
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
		
		if self.db.history ~= nil then 
			for event = 1, table.getn(self.db.history) do
				local eventTime, mark, zone, subZone, loot = addon:GetLootedHistoryEvent(event)
				local row = AceGUI:Create("SimpleGroup")
				row:SetFullWidth(true)
				row:SetLayout("Flow")
				for item = 1, table.getn(loot) do
					local _, icon, name, link, quantity, _, price = addon:GetLootedHistoryEventItem(loot, item)
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
		globalLabel:SetText(string.format(LOOT_TOTAL_STRING, GetCoinTextureString(self.db.stats.total.copper)))
		totalContainer:AddChild(globalLabel)
		
		local sessionLabel = AceGUI:Create("Label")
		sessionLabel:SetText(string.format(LOOT_MARKS_STRING, self.db.stats.total.marks))
		totalContainer:AddChild(sessionLabel)
		
		local averageLabel = AceGUI:Create("Label")
		averageLabel:SetText(string.format(LOOT_AVERAGE_STRING, GetCoinTextureString(addon:GetGlobalAverage())))
		totalContainer:AddChild(averageLabel)
		
		local controlContainer = AceGUI:Create("SimpleGroup")
		controlContainer:SetFullWidth(true)
		controlContainer:SetLayout("Flow")
		
		local resetButton = AceGUI:Create("Button")
		resetButton:SetText("Reset All Stats")
		resetButton:SetWidth(200)
		resetButton:SetCallback("OnClick", function() addon:ResetLoot() end)
		totalContainer:AddChild(resetButton)
	end
end