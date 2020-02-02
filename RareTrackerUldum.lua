-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local InterfaceOptionsFrame_Show = InterfaceOptionsFrame_Show
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local LibStub = LibStub
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

-- Redefine global variables locally.
local UIParent = UIParent
local C_ChatInfo = C_ChatInfo

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerUldum", true)

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

local RTU = CreateFrame("Frame", "RTU", UIParent);
RT:RegisterZoneModule(RTU)

-- The current data we have of the rares.
RTU.is_alive = {}
RTU.current_health = {}
RTU.last_recorded_death = {}
RTU.current_coordinates = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RTU.current_shard_id = nil

-- A table containing all UID deaths reported by the player.
RTU.recorded_entity_death_ids = {}

-- A table containing all vignette UIDs reported by the player.
RTU.reported_vignettes = {}

-- A table containing all spawn UIDs that have been reported through a sound warning.
RTU.reported_spawn_uids = {}

-- The version of the addon.
RTU.version = 8
-- Version 2: changed the order of the rares.
-- Version 3: death messages now send the spawn id.
-- Version 4: changed the interface of the alive message to include coordinates.
-- Version 6: the time stamp that was used to generate the compressed table is now included in group messages.
-- Version 7: Added Champion Sen-mat.
-- Version 8: Added more rares.

-- Check whether the addon has loaded.
RTU.is_loaded = false

-- Check which assault is currently active.
RTU.assault_id = 0

-- The code of the addon.
RTU.addon_code = "RTU"


-- ####################################################################
-- ##                         Saved Variables                        ##
-- ####################################################################

-- Setting saved in the saved variables.
RTUDB = {}

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Open and start the RTU interface and subscribe to all the required events.
function RTU:StartInterface()
	-- Reset the data, since we cannot guarantee its correctness.
	self.is_alive = {}
	self.current_health = {}
	self.last_recorded_death = {}
	self.current_coordinates = {}
	self.reported_spawn_uids = {}
	self.reported_vignettes = {}
	self.waypoints = {}
	self.current_shard_id = nil
	self:UpdateShardNumber(nil)
	self:UpdateAllDailyKillMarks()
	self:RegisterEvents()
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTU") ~= true then
		print(L["<RTU> Failed to register AddonPrefix 'RTU'. RTU will not function properly."])
	end
	
	if not RT.db.global.window.hide then
		self:Show()
	end
end

-- Open and start the RTU interface and unsubscribe to all the required events.
function RTU:CloseInterface()
	-- Reset the data.
	self.is_alive = {}
	self.current_health = {}
	self.last_recorded_death = {}
	self.current_coordinates = {}
	self.reported_spawn_uids = {}
	self.reported_vignettes = {}
	self.current_shard_id = nil
	self:UpdateShardNumber(nil)
	
	-- Register the user's departure and disable event listeners.
	self:RegisterDeparture(self.current_shard_id)
	self:UnregisterEvents()
	
	-- Hide the interface.
	self:Hide()
end
