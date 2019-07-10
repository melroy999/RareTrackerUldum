local _, data = ...

local RTM = data.RTM;

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RTM:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		self:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" then
		self:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		self:OnCombatLogEvent(...)
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
		self:OnZoneTransition()
	elseif event == "CHAT_MSG_CHANNEL" then
		self:OnChatMsgChannel(...)
	elseif event == "CHAT_MSG_ADDON" then
		self:OnChatMsgAddon(...)
	end
end

function RTM:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if self.current_shard_id ~= zone_uid and zone_uid ~= nil then
			print("Changing from shard", self.current_shard_id, "to", zone_uid..".")
			
			if self.current_shard_id == nil then
				-- Register yourself for the given shard.
				self:RegisterArrival(zone_uid)
			else
				-- Changed shard. Remove yourself from the original shard and register to new shard.
				self:RegisterDeparture(self.current_shard_id)
				self:RegisterArrival(zone_uid)
			end
			
			self.current_shard_id = zone_uid
		end
		
		if self.rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				self.is_alive[npc_id] = true
				local percentage = self:GetTargetHealthPercentage()
				self.current_health[npc_id] = percentage
				self.last_recorded_death[npc_id] = nil
				
				self:RegisterEntityHealth(self.current_shard_id, npc_id, percentage)
			else 
				self.is_alive[npc_id] = false
				self.current_health[npc_id] = nil
				
				print(self.last_recorded_death[npc_id])
				if self.last_recorded_death[npc_id] == nil then
					print("Registering death")
					self.last_recorded_death[npc_id] = time()
					self:RegisterEntityDeath(self.current_shard_id, npc_id)
				end
			end
		end
	end
end

function RTM:OnUnitHealth(unit)
	-- If the unit is not the target, skip.
	if unit ~= "target" then 
		return 
	end
	
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if self.rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			local percentage = self:GetTargetHealthPercentage()
			self.current_health[npc_id] = percentage
			
			if self.current_shard_id ~= nil then
				self:RegisterEntityHealth(self.current_shard_id, npc_id, percentage)
			end
		end
	end
end

function RTM:OnCombatLogEvent(...)
	-- The event itself does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
		
	if subevent == "UNIT_DIED" then
		if self.rare_ids_set[npc_id] then
			--self.last_recorded_death[npc_id] = timestamp
			self.is_alive[npc_id] = false
			self.current_health[npc_id] = nil
			
			print(self.last_recorded_death[npc_id])
			if self.current_shard_id ~= nil and self.last_recorded_death[npc_id] == nil then
				print("Registering death")
				self.last_recorded_death[npc_id] = time()
				self:RegisterEntityDeath(self.current_shard_id, npc_id)
			end
		end
	end
end	

RTM.last_zone_id = nil

function RTM:OnZoneTransition()
	-- The zone the player is in.
	local zone_id = C_Map.GetBestMapForUnit("player")
	--print("Entering zone", zone_id)
	
	-- 
	
		
	if (zone_id == 1462 or zone_id == 37) and not (self.last_zone_id == 1462 or self.last_zone_id == 37) then
		-- Enable the Mechagon rares.
		print("Enabling addon")
		self:StartInterface()
	elseif (self.last_zone_id == 1462 or self.last_zone_id == 37) and not (zone_id == 1462 or zone_id == 37) then
		-- Disable the addon.
		print("Disabling addon")
		
		-- If we do not have a shard ID, we are not subscribed to one of the channels.
		if self.current_shard_id ~= nil then
			self:RegisterDeparture(self.current_shard_id)
		end
		
		self:CloseInterface()
	end
	
	self.last_zone_id = zone_id
end	

function RTM:OnChatMsgChannel(...)
	text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
	
	--print(text)
end	

function RTM:OnChatMsgAddon(...)
	local addon_prefix, message, channel, sender = ...
	
	if addon_prefix == "RTM" then
		local header, payload = strsplit(":", message)
		local prefix, shard_id = strsplit("-", header)
		print(prefix, message, channel, sender)
	
		self:OnChatMessageReceived(sender, prefix, shard_id, payload)
	end
end	

RTM.last_display_update = 0

function RTM:OnUpdate()
	if (RTM.last_display_update + 0.5 < time()) then
		for i=1, #RTM.rare_ids do
			local npc_id = RTM.rare_ids[i]
			RTM:UpdateStatus(npc_id)
		end
		
		RTM.last_display_update = time();
	end
end	

function RTM:RegisterEvents()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("CHAT_MSG_CHANNEL")
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function RTM:UnregisterEvents()
	self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent("UNIT_HEALTH")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:UnregisterEvent("CHAT_MSG_CHANNEL")
	self:UnregisterEvent("CHAT_MSG_ADDON")
end

RTM.updateHandler = CreateFrame("Frame", "RTM.updateHandler", RTM)
RTM.updateHandler:SetScript("OnUpdate", RTM.OnUpdate)

-- Register the event handling of the frame.
RTM:SetScript("OnEvent", RTM.OnEvent)
RTM:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RTM:RegisterEvent("ZONE_CHANGED")
RTM:RegisterEvent("PLAYER_ENTERING_WORLD")