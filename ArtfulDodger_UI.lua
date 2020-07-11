local addon = LibStub("AceAddon-3.0"):GetAddon("ArtfulDodger")
local map = addon:GetModule("ArtfulDodger_Map")
local ui = addon:NewModule("ArtfulDodger_UI")
local AceGUI = LibStub("AceGUI-3.0")

local LOOT_TOTAL_STRING = "|cffeec300  Pilfered coin:  |cffFFFFFF%s  |r"
local LOOT_MARKS_STRING = "|cffeec300     Picked pockets:  |cffFFFFFF%d  |r"
local LOOT_AVERAGE_STRING = "|cffeec300  Coin per mark:  |cffFFFFFF%s  |r"

local DATE_FORMAT = "%b. %d \n%I:%M %p"

local table

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
			width = 0.2
		},
		column = {
			type = "Label",
			width = 0.2
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
			width = 0.3
		},
		column = {
			type = "Label",
			width = 0.25
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

function ui:OnEnable()
    ui.db = addon.db
end

function ui:ShowFrame()
	if ui.db.settings.ui.visible == false then
		ui.db.settings.ui.visible = true

		local frame = ui:CreateHistoryStatsFrame()

		local tab =  AceGUI:Create("TabGroup")
		tab:SetLayout("Flow")
		tab:SetTabs({{text="Picked Pockets", value="tab1"}, {text="Settings", value="tab2"}})
		tab:SetCallback("OnGroupSelected", function(container, event, group)
			container:ReleaseChildren()
			if group == "tab1" then
                container:AddChild(ui:CreateStatsDisplay())
				container:AddChild(ui:CreateTableSectionHeading())
				container:AddChild(ui:CreateTableHeaders())
				container:AddChild(ui:CreateHistoryTable())
			elseif group == "tab2" then
				container:AddChild(ui:CreateSettingsDisplay())
			end
		end)
        tab:SelectTab("tab1")
		frame:AddChild(tab)
	end
end

function ui:CreateHistoryTable()
	local container = ui:CreateScrollContainer()
	table = ui:CreateScrollFrame()
	ui:FillHistoryTable(table, ui.db.history)
	container:AddChild(table)
	return container
end

function ui:FillHistoryTable(table, data)
    table:ReleaseChildren()
    local event, item
	if data then 
		for event = 1, #data do
            event = data[event]
			local row = ui:CreateRow()
			for item = 1, #event.loot do
                item = event.loot[item]
				row:AddChild(ui:CreateCell(date(DATE_FORMAT, event.timestamp), columns.timestamp))
				row:AddChild(ui:CreateCell(event.zone, columns.zone))
				--row:AddChild(ui:CreateCell(event.subZone, columns.subZone))
				row:AddChild(ui:CreateCell(event.mark.name, columns.mark))
				row:AddChild(ui:CreateCell(item.link, columns.item, item.icon))
				row:AddChild(ui:CreateCell(item.quantity, columns.quantity))
				row:AddChild(ui:CreateCell(GetCoinTextureString(item.price), columns.price))
			end
			table:AddChild(row)
		end
	end
end

function ui:CreateRow()
	local row = AceGUI:Create("SimpleGroup")
	row:SetFullWidth(true)
	row:SetLayout("Flow")
	return row
end

function ui:CreateScrollFrame()
	local frame = AceGUI:Create("ScrollFrame")
	frame:SetLayout("List")
	return frame
end

function ui:CreateScrollContainer()
	local scrollContainer = AceGUI:Create("SimpleGroup")
	scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
	scrollContainer:SetLayout("Fill")
	scrollContainer:SetPoint("TOP")
	return scrollContainer
end

function ui:CreateTableSectionHeading()
	return ui:CreateHeading("Victims", 1)
end

function ui:CreateStatsSectionHeading()
	return ui:CreateHeading("Totals", 1)
end

function ui:CreateSettingsDisplay()
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
    
    settingsContainer:AddChild(ui:CreateUpdateIntervalSlider())
    
    local mapCheckbox = AceGUI:Create("CheckBox")
    mapCheckbox:SetType("checkbox")
    mapCheckbox:SetLabel("World Map Display")
    mapCheckbox:SetDescription("Shows zone loot stats on world map")
    mapCheckbox:SetValue(ui.db.settings.map.visible)
    mapCheckbox:SetCallback("OnValueChanged", function(_, event, value)
        ui.db.settings.map.visible = value
        map:ToggleMap()
    end)
    
    settingsContainer:AddChild(mapCheckbox)

	return settingsContainer
end

function ui:CreateUpdateIntervalSlider()
    local container = AceGUI:Create("InlineGroup")
    container:SetTitle("Update Interval")
	container:SetFullWidth(false)
	container:SetLayout("Flow")

    local updateIntervalSlider = AceGUI:Create("Slider")
    updateIntervalSlider:SetValue(ui.db.settings.stats.updateInterval)
    updateIntervalSlider:SetSliderValues(5, 300, 5)
    updateIntervalSlider:SetLabel("Seconds")
    updateIntervalSlider:SetCallback("OnMouseUp", function(event, value) 
        ui.db.settings.stats.updateInterval = updateIntervalSlider:GetValue()
    end)
    container:AddChild(updateIntervalSlider)
    
    return container
end

function ui:CreateStatsDisplay()
	local container = AceGUI:Create("SimpleGroup")
	container:SetFullWidth(true)
	container:SetLayout("Flow")
    container:SetHeight(100)
    
    local zones = addon:GetZones()
    
    local zoneTotalLabel = AceGUI:Create("Label")
    zoneTotalLabel:SetRelativeWidth(0.2)
    local zoneAverageLabel = AceGUI:Create("Label")
    zoneAverageLabel:SetRelativeWidth(0.2)
    local zoneMarksLabel = AceGUI:Create("Label")
    zoneMarksLabel:SetRelativeWidth(0.2)
    
    local zoneDropdown = AceGUI:Create("Dropdown")
    zoneDropdown:SetLabel("Zones")
    zoneDropdown:SetRelativeWidth(0.3)
    zoneDropdown:SetList(addon:GetZones())
    zoneDropdown:AddItem("All", "All Zones")
    zoneDropdown:SetCallback("OnValueChanged", function(key)
        local zone = key.value
        if zone == "All" then
            zoneMarksLabel:SetText(ui:GetMarksString(ui.db.stats.total.marks))
            zoneAverageLabel:SetText(ui:GetAverageString(addon:GetTotalCopperPerMark()))
            zoneTotalLabel:SetText(ui:GetTotalString(ui.db.stats.total.copper))
            ui:FillHistoryTable(table, ui.db.history)
        else
            zoneMarksLabel:SetText(ui:GetMarksString(addon:GetZoneMarks(zone)))
            zoneAverageLabel:SetText(ui:GetAverageString(addon:GetZoneCopperPerMark(zone)))
            zoneTotalLabel:SetText(ui:GetTotalString(addon:GetZoneTotalCopper(zone)))
            ui:FillHistoryTable(table, addon:GetZoneHistory(zone))
        end
    end)
    
    zoneAverageLabel:SetText(ui:GetAverageString(addon:GetTotalCopperPerMark()))
    zoneTotalLabel:SetText(ui:GetTotalString(ui.db.stats.total.copper))
    zoneMarksLabel:SetText(ui:GetMarksString(ui.db.stats.total.marks))
    zoneDropdown:SetValue("All")
    
    container:AddChild(zoneDropdown)
    container:AddChild(zoneMarksLabel)
    container:AddChild(zoneTotalLabel)
    container:AddChild(zoneAverageLabel)

	return container
end

function ui:GetMarksString(marks)
    return string.format(LOOT_MARKS_STRING, marks)
end

function ui:GetTotalString(copper)
    return string.format(LOOT_TOTAL_STRING, GetCoinTextureString(copper))
end

function ui:GetAverageString(copper)
    return string.format(LOOT_AVERAGE_STRING, GetCoinTextureString(copper))
end

function ui:CreateHeading(text, relativeWidth)
	local heading = AceGUI:Create("Heading")
	heading:SetText(text)
	heading:SetRelativeWidth(relativeWidth)
	return heading
end

function ui:CreateHistoryStatsFrame()
    local frame = ui:CreateFrame("The Artful Dodger's Ledger", "Fill", 600)
    frame:SetPoint("CENTER")
	return frame
end

function ui:CreateFrame(title, layout, height)
	local frame = AceGUI:Create("Frame")
	frame:SetTitle(title)
	frame:SetCallback("OnClose", function(widget)
		ui.db.settings.ui.visible = false
		AceGUI:Release(widget)
	end)
	frame:SetLayout(layout)
	frame:SetHeight(height)
	return frame
end

function ui:CreateTableHeaders()
	local header = AceGUI:Create("SimpleGroup")
	header:SetFullWidth(true)
	header:SetLayout("Flow")
	ui:AddHeaders(header)
	return header
end

function ui:CreateCell(title, column, image)
	local cell
	if column.column.type == "Label" then
		cell = AceGUI:Create(column.column.type)
		cell:SetText(title)
	elseif column.column.type == "InteractiveLabel" then
		cell = AceGUI:Create(column.column.type)
		cell:SetText(title)
	elseif column.column.type == "Icon" then
		cell = AceGUI:Create(column.column.type)
		--cell:SetLabel(title)
		cell:SetImage(image)
		cell:SetImageSize(20,20)
		cell:SetCallback("OnEnter", function(widget)
			if not string.match(title, "Coin") then
                GameTooltip:SetOwner(widget.frame, "ANCHOR_NONE")
                GameTooltip:SetPoint("TOPLEFT", widget.frame, "BOTTOMLEFT")
                GameTooltip:ClearLines()
				GameTooltip:SetHyperlink(title)
                GameTooltip:Show()
			end
		end)
		cell:SetCallback("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	cell:SetRelativeWidth(column.column.width)
	return cell
end

function ui:AddHeader(parent, column)
	local header = AceGUI:Create("InteractiveLabel")
	header:SetText(column.header.title)
	header:SetRelativeWidth(column.header.width)
	header:SetFontObject(GameFontNormalLarge)
	parent:AddChild(header)
end

function ui:AddHeaders(parent)
	ui:AddHeader(parent, columns.timestamp)
	ui:AddHeader(parent, columns.zone)
	--ui:AddHeader(parent, columns.subZone)
	ui:AddHeader(parent, columns.mark)
	ui:AddHeader(parent, columns.item)
	ui:AddHeader(parent, columns.quantity)
	ui:AddHeader(parent, columns.price)
end