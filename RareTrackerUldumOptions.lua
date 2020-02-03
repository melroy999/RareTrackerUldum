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
    self.db = LibStub("AceDB-3.0"):New("RareTrackerUldumDB", self.defaults, true)
end

function RTU:AddModuleOptions(options)
    options[self.addon_code] = {
        type = "group",
        name = "Uldum",
        order = RT:GetOrder(),
        childGroups = "tab",
        args = {
            description = {
                type = "description",
                name = "RareTrackerUldum (v"..GetAddOnMetadata("RareTrackerUldum", "Version")..")",
                order = RT:GetOrder(),
                fontSize = "large",
                width = "full",
            },
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
                            self:ReorganizeRareTableFrame(self.entities_frame)
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
            name = self.rare_names[npc_id],
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
