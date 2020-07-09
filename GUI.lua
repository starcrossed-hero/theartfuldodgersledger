local addon = LibStub("AceAddon-3.0"):GetAddon("TheArtfulDodgersLedger")
local gui = addon:NewModule("GUI")
local AceGUI = LibStub("AceGUI-3.0")

local LOOT_TOTAL_STRING = "Pilfered coins:  %s"
local LOOT_MARKS_STRING = "Pockets picked:  %d"
local LOOT_AVERAGE_STRING = "Average per mark:  %s"

local DATE_FORMAT = "%b. %d \n%I:%M %p"

local columns = {
	timestamp = {
		header = {
			title = "Time", 
			width = 0.1
		},
		column = {
			type="Label",
			width = 0.1
		}
	},
	zone = {
		header = {
			title = "Zone", 
			width = 0.1
		},
		column = {
			type = "Label",
			width = 0.1
		}
	},
	subZone = {
		header = {
			title = "Sub-Zone", 
			width = 0.15
		},
		column = {
			type = "Label",
			width = 0.15
		}
	},
	mark = {
		header = {
			title = "Mark", 
			width = 0.25
		},
		column = {
			type = "Label",
			width = 0.2
		}
	},
	item = {
		header = {
			title = "Loot",
			width = 0.1
		},
		column = {
			type = "Icon",
			width = 0.2
		}
	},
	quantity = {
		header = {
			title = "Qty",
			width = 0.1
		},
		column = {
			type = "Label",
			width = 0.08
		}
	},
	price = {
		header = {
			title = "Price",
			width = 0.1
		},
		column = {
			type = "Label",
			width = 0.08
		}
	}
}

function gui:OnEnable()
    gui.db = addon.db
end

function gui:ShowFrame()   
	if gui.db.settings.gui.visible == false then
        
        print("visible: ", gui.db.settings.gui.visible)

		gui.db.settings.gui.visible = true

		local frame = gui:CreateHistoryStatsFrame()
		-- Create the TabGroup
		local tab =  AceGUI:Create("TabGroup")
		tab:SetLayout("Flow")
		-- Setup which tabs to show
		tab:SetTabs({{text="Picked Pockets", value="tab1"}, {text="Plunder Tallied", value="tab2"}, {text="Settings", value="tab3"}})
		-- Register callback
		tab:SetCallback("OnGroupSelected", function(container, event, group)
			container:ReleaseChildren()
			if group == "tab1" then
				container:AddChild(gui:CreateTableSectionHeading())
				container:AddChild(gui:CreateTableHeaders())
				container:AddChild(gui:CreateHistoryTable())
			elseif group == "tab2" then
				container:AddChild(gui:CreateStatsSectionHeading())
				container:AddChild(gui:CreateStatsDisplay())
			elseif group == "tab3" then
				container:AddChild(gui:CreateSettingsDisplay())
			end
		end)

		frame:AddChild(tab)

		-- Set initial Tab (this will fire the OnGroupSelected callback)
		tab:SelectTab("tab1")

		--frame:AddChild(gui:CreateTableSectionHeading())
		--frame:AddChild(gui:CreateTableHeaders())
		--frame:AddChild(gui:CreateHistoryTable())
		--frame:AddChild(gui:CreateStatsSectionHeading())
		--frame:AddChild(gui:CreateStatsDisplay())
	end
end

function gui:CreateHistoryTable()
	local container = gui:CreateScrollContainer()
	local table = gui:CreateScrollFrame()
	gui:FillHistoryTable(table)
	container:AddChild(table)
	return container
end

function gui:FillHistoryTable(table)
	if gui.db.history ~= nil then 
		for event = 1, #gui.db.history do
			local eventTime, mark, zone, subZone, loot = addon:GetLootedHistoryEvent(event)
			local row = gui:CreateRow()
			for item = 1, #loot do
				local _, icon, name, link, quantity, _, price = addon:GetLootedHistoryEventItem(loot, item)
				row:AddChild(gui:CreateCell(date(DATE_FORMAT, eventTime), columns.timestamp))
				row:AddChild(gui:CreateCell(zone, columns.zone))
				row:AddChild(gui:CreateCell(subZone, columns.subZone))
				row:AddChild(gui:CreateCell(mark.name, columns.mark))
				row:AddChild(gui:CreateCell(link, columns.item, icon))
				row:AddChild(gui:CreateCell(quantity, columns.quantity))
				row:AddChild(gui:CreateCell(GetCoinTextureString(price), columns.price))
			end
			table:AddChild(row)
		end
	end
end

function gui:CreateRow()
	local row = AceGUI:Create("SimpleGroup")
	row:SetFullWidth(true)
	row:SetLayout("Flow")
	return row
end

function gui:CreateScrollFrame()
	local frame = AceGUI:Create("ScrollFrame")
	frame:SetLayout("Flow")
	return frame
end

function gui:CreateScrollContainer()
	local scrollcontainer = AceGUI:Create("SimpleGroup")
	scrollcontainer:SetFullWidth(true)
	scrollcontainer:SetLayout("Fill")
	scrollcontainer:SetPoint("TOP")
	scrollcontainer:SetHeight(400)
    scrollcontainer:SetCallback("MoveScroll", function(widget)
        print("scroll")
    end)
	return scrollcontainer
end

function gui:CreateTableSectionHeading()
	return gui:CreateHeading("Recent Victims", 1)
end

function gui:CreateStatsSectionHeading()
	return gui:CreateHeading("Totals", 1)
end

function gui:CreateSettingsDisplay()
	local settingsContainer = AceGUI:Create("SimpleGroup")
	settingsContainer:SetFullWidth(true)
	settingsContainer:SetLayout("Flow")

	local resetSessionButton = AceGUI:Create("Button")
	resetSessionButton:SetText("Reset Session")
	resetSessionButton:SetWidth(200)
	resetSessionButton:SetCallback("OnClick", function() addon:ResetSessionStats() end)
	settingsContainer:AddChild(resetSessionButton)

	local resetAllButton = AceGUI:Create("Button")
	resetAllButton:SetText("Reset All Stats")
	resetAllButton:SetWidth(200)
	resetAllButton:SetCallback("OnClick", function() addon:ResetAll() end)
	settingsContainer:AddChild(resetAllButton)
    
    settingsContainer:AddChild(gui:CreateUpdateIntervalSlider())
    
    local worldMapCheckbox = AceGUI:Create("CheckBox")
    worldMapCheckbox:SetType("checkbox")
    worldMapCheckbox:SetLabel("World Map Display")
    worldMapCheckbox:SetDescription("Shows zone loot stats on world map")
    if gui.db.settings.gui.worldMapDisplay then
        worldMapCheckbox:SetValue(1)
    else
       worldMapCheckbox:SetValue(0) 
    end
    worldMapCheckbox:SetCallback("OnValueChanged", function(_, event, value)
        gui.db.settings.gui.worldMapDisplay = value
    end)
    
    settingsContainer:AddChild(worldMapCheckbox)

	return settingsContainer
end

function gui:CreateUpdateIntervalSlider()
    local container = AceGUI:Create("InlineGroup")
    container:SetTitle("Update Interval")
	container:SetFullWidth(false)
	container:SetLayout("Flow")
    
    --local label = AceGUI:Create("Label")
	--:SetText("Update Interval (in seconds)")
	--container:AddChild(label)
    
    local updateIntervalSlider = AceGUI:Create("Slider")
    updateIntervalSlider:SetValue(gui.db.settings.stats.updateInterval)
    updateIntervalSlider:SetSliderValues(5, 300, 5)
    updateIntervalSlider:SetLabel("Seconds")
    updateIntervalSlider:SetCallback("OnMouseUp", function(event, value) 
        gui.db.settings.stats.updateInterval = updateIntervalSlider:GetValue()
    end)
    container:AddChild(updateIntervalSlider)
    
    return container
end

function gui:CreateStatsDisplay()
	local container = AceGUI:Create("SimpleGroup")
	container:SetFullWidth(true)
	container:SetLayout("Flow")
	local globalLabel = AceGUI:Create("Label")
	globalLabel:SetText(string.format(LOOT_TOTAL_STRING, GetCoinTextureString(addon:GetTotalCopperFromHistory())))
	container:AddChild(globalLabel)
	
	local sessionLabel = AceGUI:Create("Label")
	sessionLabel:SetText(string.format(LOOT_MARKS_STRING, #gui.db.history))
	container:AddChild(sessionLabel)
	
	local averageLabel = AceGUI:Create("Label")
	averageLabel:SetText(string.format(LOOT_AVERAGE_STRING, GetCoinTextureString(addon:GetTotalCopperPerMark())))
	container:AddChild(averageLabel)
	local zoneAverageLabel = AceGUI:Create("Label")
	zoneAverageLabel:SetText("Current Zone: "..GetRealZoneText().." Average Copper: "..GetCoinTextureString(TheArtfulDodgersLedger:GetZoneCopperPerMark(GetRealZoneText())))
	container:AddChild(zoneAverageLabel)

	return container
end

function gui:CreateHeading(text, relativeWidth)
	local heading = AceGUI:Create("Heading")
	heading:SetText(text)
	heading:SetRelativeWidth(relativeWidth)
	return heading
end

function gui:CreateHistoryStatsFrame()
	return gui:CreateFrame("The Artful Dodger's Ledger", "Fill", 600)
end

function gui:CreateFrame(title, layout, height)
	local frame = AceGUI:Create("Frame")
	frame:SetTitle(title)
	frame:SetCallback("OnClose", function(widget)
		gui.db.settings.gui.visible = false
		AceGUI:Release(widget)
	end)
	frame:SetLayout(layout)
	frame:SetHeight(height)
	return frame
end

function gui:CreateTableHeaders()
	local header = AceGUI:Create("SimpleGroup")
	header:SetFullWidth(true)
	header:SetLayout("Flow")
	gui:AddHeaders(header)
	return header
end

function gui:CreateCell(title, column, image)
	local cell
	if column.column.type == "Label" then
		cell = AceGUI:Create(column.column.type)
		cell:SetText(title)
	elseif column.column.type == "InteractiveLabel" then
		cell = AceGUI:Create(column.column.type)
		cell:SetText(title)
	elseif column.column.type == "Icon" then
		cell = AceGUI:Create(column.column.type)
		cell:SetLabel(title)
		cell:SetImage(image)
		cell:SetImageSize(20,20)
		cell:SetCallback("OnClick", function() print(title) end)
		cell:SetCallback("OnEnter", function(widget)
			GameTooltip:SetOwner(widget.frame, "ANCHOR_NONE")
			GameTooltip:SetPoint("TOPLEFT", widget.frame, "BOTTOMLEFT")
			GameTooltip:ClearLines()
			if string.match(title, "Coin") and string.match(title, "|cFFCC9900") then
				GameTooltip:AddLine(title)
			else 
				GameTooltip:SetHyperlink(title)
			end
			GameTooltip:Show()
		end)
		cell:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	cell:SetRelativeWidth(column.column.width)
	return cell
end

function gui:AddHeader(parent, column)
	local header = AceGUI:Create("InteractiveLabel")
	header:SetText(column.header.title)
	header:SetRelativeWidth(column.header.width)
	header:SetFontObject(GameFontNormalLarge)
	header:SetCallback("OnClick", function() 
		if column.header.title == "Mark" then
			addon:SortTable(gui.db.history, "mark")
		elseif column.header.title == "Loot" then
			addon:SortTable(gui.db.history, "mark")
		end
	end)
	parent:AddChild(header)
end

function gui:AddHeaders(parent)
	gui:AddHeader(parent, columns.timestamp)
	gui:AddHeader(parent, columns.zone)
	gui:AddHeader(parent, columns.subZone)
	gui:AddHeader(parent, columns.mark)
	gui:AddHeader(parent, columns.item)
	gui:AddHeader(parent, columns.quantity)
	gui:AddHeader(parent, columns.price)
end