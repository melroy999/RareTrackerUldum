-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory

-- Redefine global variables locally.
local UIParent = UIParent

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerUldum", true)

-- ####################################################################
-- ##                             Options                            ##
-- ####################################################################

function RTU:InitializeRareTrackerDatabase()
    self.defaults = RT.GetDefaultModuleDatabaseValues()
    
    -- Load the database.
    self.db = LibStub("AceDB-3.0"):New("RareTrackerUldumDB", self.defaults)
end

function RTU:AddModuleOptions(options)
    options[self.addon_code] = {
        type = "group",
        name = "Uldum",
        order = RT:GetOrder(),
        childGroups = "tab",
        args = {
            general = {
                type = "group",
                name = "General Options",
                order = RT:GetOrder(),
                args = {
                    window_scale = {
                        type = "range",
                        name = "Rare window scale",
                        min = 0.5,
                        max = 2,
                        step = 0.05,
                        isPercent = true,
                        order = RT:GetOrder(),
                        get = function()
                            return self.db.global.window_scale
                        end,
                        set = function(_, val)
                            self.db.global.window_scale  = val
                            self:SetScale(val)
                        end
                    },
                    filter_list = {
                        type = "toggle",
                        name = "Enable filter fallback",
                        desc = "Show only rares that drop special loot (mounts/pets/toys) when no assault data is available.",
                        width = "full",
                        order = RT:GetOrder(),
                        get = function()
                            return self.db.global.enable_rare_filter
                        end,
                        set = function(_, val)
                            self.db.global.enable_rare_filter  = val
                        end
                    },
                    reset_favorites = {
                        type = "execute",
                        name = "Reset Favorites",
                        desc = "Reset the list of favorite rares.",
                        order = RT:GetOrder(),
                        func = function()
                            self.db.global.favorite_rares = {}
                            self:CorrectFavoriteMarks()
                        end
                    },
                }
            },
            ordering = {
                type = "group",
                name = "Rare List Options",
                order = RT:GetOrder(),
                args = {
                    enable_all = {
                        type = "execute",
                        name = "Enable All",
                        desc = "Enable all rares in the list.",
                        order = RT:GetOrder(),
                        width = 0.7,
                        func = function()
                            for _, npc_id in pairs(self.rare_ids) do
                                self.db.global.ignore_rares[npc_id] = nil
                            end
                            self:ReorganizeRareTableFrame(self.entities_frame)
                        end
                    },
                    disable_all = {
                        type = "execute",
                        name = "Disable All",
                        desc = "Disable all non-favorite rares in the list.",
                        order = RT:GetOrder(),
                        width = 0.7,
                        func = function(info)
                            for _, npc_id in pairs(self.rare_ids) do
                                if self.db.global.favorite_rares[npc_id] ~= true then
                                  self.db.global.ignore_rares[npc_id] = true
                                end
                            end
                            self:ReorganizeRareTableFrame(self.entities_frame)
                        end
                    },
                    ignore = {
                        type = "group",
                        name = "Active Rares",
                        order = RT:GetOrder(),
                        inline = true,
                        args = {
                            -- To be filled dynamically.
                        }
                    },
                }
            }
        }
    }
    
    -- Add checkboxes for all of the rares.
    for _, npc_id in pairs(self.rare_ids) do
        options[self.addon_code].args.ordering.args.ignore.args[""..npc_id] = {
            type = "toggle",
            name = self.rare_display_names[npc_id],
            width = "full",
            order = RT:GetOrder(),
            get = function()
                return not self.db.global.ignore_rares[npc_id]
            end,
            set = function(_, val)
                if not self.db.global.ignore_rares[npc_id] then
                    self.db.global.ignore_rares[npc_id] = true
                else
                    self.db.global.ignore_rares[npc_id] = nil
                end
                self:ReorganizeRareTableFrame(self.entities_frame)
            end,
            disabled = function()
                return self.db.global.favorite_rares[npc_id]
            end
        }
    end
end

-- ####################################################################
-- ##                       Options Interface                        ##
-- ####################################################################

function RTU:InitializeButtons(parent_frame)
	parent_frame.reset_blacklist_button = CreateFrame(
		"Button", "RTU.options_panel.reset_blacklist_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_blacklist_button:SetText(L["Reset Blacklist"])
	parent_frame.reset_blacklist_button:SetSize(150, 25)
	parent_frame.reset_blacklist_button:SetPoint("TOPRIGHT", parent_frame.reset_favorites_button, 155, 0)
	parent_frame.reset_blacklist_button:SetScript("OnClick",
		function()
			RTUDB.banned_NPC_ids = {}
		end
	)
end

function RTU:CreateRareSelectionEntry(npc_id, parent_frame, entry_data)
	local f = CreateFrame("Frame", "RTU.options_panel.rare_selection.frame.list["..npc_id.."]", parent_frame);
	f:SetSize(500, 12)
	
	f.enable = CreateFrame("Button", "RTU.options_panel.rare_selection.frame.list["..npc_id.."].enable", f);
	f.enable:SetSize(10, 10)
	local texture = f.enable:CreateTexture(nil, "BACKGROUND")
	
	if not self.db.global.ignore_rares[npc_id] then
		texture:SetColorTexture(0, 1, 0, 1)
	else
		texture:SetColorTexture(1, 0, 0, 1)
	end
	
	texture:SetAllPoints(f.enable)
	f.enable.texture = texture
	f.enable:SetPoint("TOPLEFT", f, 0, 0)
	f.enable:SetScript("OnClick",
		function()
			if not self.db.global.ignore_rares[npc_id] then
				if self.db.global.favorite_rares[npc_id] then
					print(L["<RTU> Favorites cannot be hidden."])
				else
					self.db.global.ignore_rares[npc_id] = true
					f.enable.texture:SetColorTexture(1, 0, 0, 1)
					RTU:ReorganizeRareTableFrame(RTU.entities_frame)
				end
			else
				self.db.global.ignore_rares[npc_id] = nil
				f.enable.texture:SetColorTexture(0, 1, 0, 1)
				RTU:ReorganizeRareTableFrame(RTU.entities_frame)
			end
		end
	)
	
	f.up = CreateFrame("Button", "RTU.options_panel.rare_selection.frame.list["..npc_id.."].up", f);
	f.up:SetSize(10, 10)
	texture = f.up:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\AddOns\\RareTrackerUldum\\Icons\\UpArrow.tga")
	texture:SetSize(10, 10)
	texture:SetPoint("CENTER", f.up)
	texture:SetAllPoints(f.up)
	
	f.up.texture = texture
	f.up:SetPoint("TOPLEFT", f, 13, 0)
	
	f.up:SetScript("OnClick",
		function()
      -- Here, we use the most up-to-date entry data, instead of the one passed as an argument.
      local previous_entry = self.db.global.rare_ordering.__raw_data_table[npc_id].__previous
			self.db.global.rare_ordering:SwapNeighbors(previous_entry, npc_id)
			self.ReorderRareSelectionEntryItems(parent_frame)
			self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
		
	if entry_data.__previous == nil then
		f.up:Hide()
	end
	
	f.down = CreateFrame("Button", "RTU.options_panel.rare_selection.frame.list["..npc_id.."].down", f);
	f.down:SetSize(10, 10)
	texture = f.down:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\AddOns\\RareTrackerUldum\\Icons\\DownArrow.tga")
	texture:SetSize(10, 10)
	texture:SetPoint("CENTER", f.down)
	texture:SetAllPoints(f.down)
	f.down.texture = texture
	f.down:SetPoint("TOPLEFT", f, 26, 0)
	
	f.down:SetScript("OnClick",
		function()
      -- Here, we use the most up-to-date entry data, instead of the one passed as an argument.
      local next_entry = self.db.global.rare_ordering.__raw_data_table[npc_id].__next
			self.db.global.rare_ordering:SwapNeighbors(npc_id, next_entry)
			self.ReorderRareSelectionEntryItems(parent_frame)
			self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)

	if entry_data.__next == nil then
		f.down:Hide()
	end
	
	f.text = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.text:SetJustifyH("LEFT")
	f.text:SetText(self.rare_display_names[npc_id])
	f.text:SetPoint("TOPLEFT", f, 42, 0)
	
	return f
end

function RTU.ReorderRareSelectionEntryItems(parent_frame)
	local i = 1
	self.db.global.rare_ordering:ForEach(
		function(npc_id, entry_data)
			local f = parent_frame.list_item[npc_id]
			if entry_data.__previous == nil then
				f.up:Hide()
			else
				f.up:Show()
			end
			
			if entry_data.__next == nil then
				f.down:Hide()
			else
				f.down:Show()
			end
				
			f:SetPoint("TOPLEFT", parent_frame, 1, -(i - 1) * 12 - 5)
			i = i + 1
		end
	)
end

function RTU:DisableAllRaresButton(parent_frame)
  parent_frame.reset_all_button = CreateFrame(
		"Button", "RTU.options_panel.rare_selection.reset_all_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_all_button:SetText(L["Disable All"])
	parent_frame.reset_all_button:SetSize(150, 25)
	parent_frame.reset_all_button:SetPoint("TOPRIGHT", parent_frame, 0, 0)
	parent_frame.reset_all_button:SetScript("OnClick",
		function()
			for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        if self.db.global.favorite_rares[npc_id] ~= true then
          self.db.global.ignore_rares[npc_id] = true
          parent_frame.list_item[npc_id].enable.texture:SetColorTexture(1, 0, 0, 1)
        end
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
end

function RTU:EnableAllRaresButton(parent_frame)
  parent_frame.enable_all_button = CreateFrame(
		"Button", "RTU.options_panel.rare_selection.enable_all_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.enable_all_button:SetText(L["Enable All"])
	parent_frame.enable_all_button:SetSize(150, 25)
	parent_frame.enable_all_button:SetPoint("TOPRIGHT", parent_frame, 0, -25)
	parent_frame.enable_all_button:SetScript("OnClick",
		function()
      for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        self.db.global.ignore_rares[npc_id] = nil
        parent_frame.list_item[npc_id].enable.texture:SetColorTexture(0, 1, 0, 1)
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
end

function RTU:ResetRareOrderButton(parent_frame)
  parent_frame.reset_order_button = CreateFrame(
		"Button", "RTU.options_panel.rare_selection.reset_order_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_order_button:SetText(L["Reset Order"])
	parent_frame.reset_order_button:SetSize(150, 25)
	parent_frame.reset_order_button:SetPoint("TOPRIGHT", parent_frame, 0, -50)
	parent_frame.reset_order_button:SetScript("OnClick",
		function()
			self.db.global.rare_ordering:Clear()
      for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        self.db.global.rare_ordering:AddBack(npc_id)
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
      self.ReorderRareSelectionEntryItems(parent_frame)
		end
	)
end

function RTU:InitializeRareSelectionChildMenu(parent_frame)
	parent_frame.rare_selection = CreateFrame("Frame", "RTU.options_panel.rare_selection", parent_frame)
	parent_frame.rare_selection.name = L["Rare ordering/selection"]
	parent_frame.rare_selection.parent = parent_frame.name
	InterfaceOptions_AddCategory(parent_frame.rare_selection)
	
	parent_frame.rare_selection.frame = CreateFrame(
      "Frame",
      "RTU.options_panel.rare_selection.frame",
      parent_frame.rare_selection
  )
  
	parent_frame.rare_selection.frame:SetPoint("LEFT", parent_frame.rare_selection, 101, 0)
	parent_frame.rare_selection.frame:SetSize(400, 500)
	
	local f = parent_frame.rare_selection.frame
	local i = 1
	f.list_item = {}
	
	self.db.global.rare_ordering:ForEach(
		function(npc_id, entry_data)
			f.list_item[npc_id] = self:CreateRareSelectionEntry(npc_id, f, entry_data)
			f.list_item[npc_id]:SetPoint("TOPLEFT", f, 1, -(i - 1) * 12 - 5)
			i = i + 1
		end
	)
  
  -- Add utility buttons.
  RTU:DisableAllRaresButton(f)
  RTU:EnableAllRaresButton(f)
  RTU:ResetRareOrderButton(f)
end

function RTU:InitializeConfigMenu()
	self.options_panel = CreateFrame("Frame", "RTU.options_panel", UIParent)
	self.options_panel.name = "RareTrackerUldum"
	InterfaceOptions_AddCategory(self.options_panel)
	
	self.options_panel.frame = CreateFrame("Frame", "RTU.options_panel.frame", self.options_panel)
	self.options_panel.frame:SetPoint("TOPLEFT", self.options_panel, 11, -14)
	self.options_panel.frame:SetSize(500, 500)

	self:InitializeButtons(self.options_panel.frame)
	self:InitializeRareSelectionChildMenu(self.options_panel)
end
