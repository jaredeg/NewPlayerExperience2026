require( "npx_scenario" )
require( "spawner" )

--------------------------------------------------------------------

if CDotaNPXScenario_Roshan == nil then
	CDotaNPXScenario_Roshan = class( {}, {}, CDotaNPXScenario )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:InitScenarioKeys()
	self.fSurviveForTime1 = 20
	self.fSurviveForTime2 = 20
	self.fSurviveForTime3 = 20

	self.hScenario =
	{
		DaynightCycleDisabled = true,
		PreGameTime 		= 0.0,
		HeroSelectionTime 	= 0.0,
		StrategyTime 		= 0.0,
		ForceHero 			= "npc_dota_hero_ursa",
		Team 				= DOTA_TEAM_GOODGUYS,
		StartingHeroLevel	= 12,
		StartingGold		= 0,
		bLetGoldThrough		= false,
		bLetXPThrough		= false,

		StartingItems 		=
		{
			"item_power_treads",
			"item_lifesteal",
			"item_basher",
			"item_bracer"
		},

		StartingAbilities =
		{
			"ursa_overpower",
			"ursa_overpower",
			"ursa_overpower",
			"ursa_overpower",

			"ursa_fury_swipes",
			"ursa_fury_swipes",
			"ursa_fury_swipes",
			"ursa_fury_swipes",
		},

		ScenarioTimeLimit = 600.0,

		Tasks =
		{
			{
				TaskName = "intro_delay",
				TaskType = "task_delay",
				Hidden = true,
				TaskParams =
				{
					Delay = 2.0,
				},
				CheckTaskStart =
				function() 
					if GameRules:GetDOTATime( false, false ) >= 0.0 then 
						return true 
					else 
						return false 
					end
				end,
			},

			{
				TaskName = "move_to_location_1",
				TaskType = "task_move_to_trigger",
				UseHints = true,
				TaskParams =
				{
					TriggerName = "move_to_location_1",
				},
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "intro_delay" )
				end,
			},
			{
				TaskName = "do_not_die",
				TaskType = "task_fail_player_hero_death",
				Hidden = true,
				TaskParams = 
				{
					Count = 1,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_1" )
				end,
			},
			{
				TaskName = "kill_roshan",
				TaskType = "task_kill_units",
				TaskParams = 
				{
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_1" )
				end,
			},
			{
				TaskName = "pick_up_aegis",
				TaskType = "task_pick_up_item",
				TaskParams =
				{
					ItemName = "item_aegis",
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "kill_roshan" )
				end,
				OnCheckpoint =
				function()
					print( 'CHECKPOINT 1' )

					local Task
					Task = self:GetTask( "move_to_location_1" )
					if Task then Task:SetTaskHidden( true ) end
					Task = self:GetTask( "kill_roshan" )
					if Task then Task:SetTaskHidden( true ) end
					Task = self:GetTask( "pick_up_aegis" )
					if Task then Task:SetTaskHidden( true ) end

					local bForceStart = true
					self:CheckpointSkipCompleteTask( "intro_delay", true, bForceStart )
					self:CheckpointSkipCompleteTask( "move_to_location_1", true )
					self:CheckpointSkipCompleteTask( "kill_roshan", true )
					self:CheckpointSkipCompleteTask( "pick_up_aegis", true )

					if self:GetPlayerHero() ~= nil then
						self:GetPlayerHero():AddItemByName( "item_aegis" )

						local hCheckpoint = Entities:FindByName( nil, "checkpoint_1" )
						if hCheckpoint ~= nil then
							FindClearSpaceForUnit( self:GetPlayerHero(), hCheckpoint:GetAbsOrigin(), true )
							SendToConsole( "+dota_camera_center_on_hero" )
							SendToConsole( "-dota_camera_center_on_hero" )
						end
					end
				end,
			},
			{
				TaskName = "exit_pit",
				TaskType = "task_move_to_trigger",
				UseHints = true,
				TaskParams =
				{
					TriggerName = "exit_pit",
				},
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "pick_up_aegis" )
				end,
			},
			{
				TaskName = "kill_juggernaut",
				TaskType = "task_kill_units",
				TaskParams = 
				{
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "exit_pit" )
				end,
			},
			{
				TaskName = "do_not_die_twice",
				TaskType = "task_fail_player_hero_death",
				Hidden = true,
				TaskParams = 
				{
					Count = 2,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "do_not_die" )
				end,
			},

		},

		Queries =
		{
		},
	}
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:SetupScenario()
	if not CDotaNPXScenario.SetupScenario( self ) then
		return false
	end

	GameRules:SetHeroRespawnEnabled( false )

	-- Determine ally start positions based on checkpoint
	local szSnapfireStartPos = "snapfire_start_pos"
	local szLichStartPos = "lich_start_pos"

	local checkpointTask = self:GetTask( self.szCheckpointTaskName )
	if checkpointTask ~= nil then
		szSnapfireStartPos = "snapfire_tp_pos"
		szLichStartPos = "lich_tp_pos"
	end

	-- Pre-spawn all bot heroes.  On restart, spawners persist — skip re-creation.
	-- Snapfire and Lich are active allies (not frozen).
	-- Juggernaut is frozen until player exits the pit.

	if not self.hSnapfireSpawner then
		CDotaSpawner( szSnapfireStartPos, 
		{
			{
				EntityName = "npc_dota_hero_snapfire",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Snapfire",
					EntityScript = "ai/roshan/ai_snapfire.lua",
					StartingHeroLevel = 9,
					StartingItems = 
					{
						"item_tranquil_boots",
						"item_aether_lens",
					},
					StartingAbilities	= 
					{
					}, 
					AbilityBuild = 
					{
					},
				},
			},
		}, self, true )
	end

	if not self.hLichSpawner then
		CDotaSpawner( szLichStartPos, 
		{
			{
				EntityName = "npc_dota_hero_lich",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Lich",
					EntityScript = "ai/roshan/ai_lich.lua",
					StartingHeroLevel = 8,
					StartingItems = 
					{
						"item_tranquil_boots",
						"item_aether_lens",
					},
					StartingAbilities	= 
					{
					}, 
					AbilityBuild = 
					{
					},
				},
			},
		}, self, true )
	end

	if not self.hJuggernautSpawner then
		CDotaSpawner( "juggernaut_start_pos", 
		{
			{
				EntityName = "npc_dota_hero_juggernaut",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					PlayerID = 1,
					BotName = "Juggernaut",
					EntityScript = "ai/roshan/ai_juggernaut.lua",
					StartingHeroLevel = 12,
					StartingItems = 
					{
						"item_phase_boots",
						"item_bfury",
						"item_wraith_band",
						"item_maelstrom"
					},
					StartingAbilities =
					{
						"juggernaut_omni_slash",
						"juggernaut_blade_fury",
						"juggernaut_healing_ward",
						"juggernaut_blade_dance",
						"special_bonus_all_stats_5",
					},
					AbilityBuild = 
					{
						AbilityPriority =
						{
							"juggernaut_omni_slash",
							"juggernaut_blade_fury",
							"juggernaut_healing_ward",
							"juggernaut_blade_dance",
							"special_bonus_all_stats_5",
						},
					},
				},
			},
		}, self, true )
		-- NOTE: Do NOT FreezeSpawnedUnit here — OnSpawnerFinished handles it.
	end

	return true
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnSpawnerFinished( event )
	CDotaNPXScenario.OnSpawnerFinished( self, event )

	-- Identify spawners by unit name (multiple spawners may share entity names).
	for _, spawner in pairs( self.rgSpawners ) do
		local hUnit = spawner:GetSpawnedUnits()[ 1 ]
		if hUnit then
			local szName = hUnit:GetUnitName()

			if szName == "npc_dota_hero_snapfire" and not self.hSnapfireSpawner then
				self.hSnapfireSpawner = spawner
				self.hSnapfire = hUnit
				printf( "Stored Snapfire spawner" )

			elseif szName == "npc_dota_hero_lich" and not self.hLichSpawner then
				self.hLichSpawner = spawner
				self.hLich = hUnit
				printf( "Stored Lich spawner" )

			elseif szName == "npc_dota_hero_juggernaut" and not hUnit.bFrozen then
				self.hJuggernautSpawner = spawner
				self:FreezeSpawnedUnit( spawner )
				printf( "Froze Juggernaut" )
			end
		end
	end
end

--------------------------------------------------------------------
-- Helper: re-freeze Juggernaut for restart reuse.
--------------------------------------------------------------------
function CDotaNPXScenario_Roshan:RefreezeJuggernaut()
	if not self.hJuggernautSpawner then return end
	local hUnit = self.hJuggernautSpawner:GetSpawnedUnits()[ 1 ]
	if not hUnit or hUnit:IsNull() then return end

	local hEnt = Entities:FindByName( nil, "juggernaut_start_pos" )
	if hEnt then
		hUnit.vSpawnOrigin = hEnt:GetAbsOrigin()
	end

	if not hUnit:IsAlive() then
		hUnit:RespawnHero( false, false )
	end

	if not hUnit.bFrozen then
		hUnit.bFrozen = true
		hUnit:AddNewModifier( nil, nil, "modifier_invulnerable", {} )
	end
	hUnit:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
	hUnit:Stop()

	-- Reset bot AI state
	if hUnit.Bot then
		hUnit.Bot.bWasKilled = nil
		hUnit.Bot.nBotState = 0  -- JUGGERNAUT_BOT_STATE_INTRO
		hUnit.Bot.hAttackTarget = nil
	end

	-- Refresh abilities/items for next encounter
	RefreshHero( hUnit )
end

--------------------------------------------------------------------
-- Helper: reposition an ally hero (Snapfire or Lich) for restart.
--------------------------------------------------------------------
function CDotaNPXScenario_Roshan:ResetAlly( hSpawner, szPositionEntity )
	if not hSpawner then return end
	local hUnit = hSpawner:GetSpawnedUnits()[ 1 ]
	if not hUnit or hUnit:IsNull() then return end

	if not hUnit:IsAlive() then
		hUnit:RespawnHero( false, false )
	end

	-- Purge debuffs, refresh
	hUnit:Purge( false, true, false, true, true )
	RefreshHero( hUnit )
	hUnit:RemoveModifierByName( "modifier_invulnerable" )
	hUnit.bFrozen = nil

	-- Move to correct start position
	local hPos = Entities:FindByName( nil, szPositionEntity )
	if hPos then
		FindClearSpaceForUnit( hUnit, hPos:GetAbsOrigin(), true )
	end
	hUnit:Stop()

	-- Reset bot AI state
	if hUnit.Bot then
		hUnit.Bot.bWasKilled = nil
		hUnit.Bot.nBotState = 0  -- INTRO state
		hUnit.Bot.bMoveToPit = false
		hUnit.Bot.bTpOut = false
		hUnit.Bot.hAttackTarget = nil
		hUnit.Bot.hTpScroll = nil  -- re-find on next think
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:Restart()
	-- Re-freeze Juggernaut
	self:RefreezeJuggernaut()

	-- Determine ally positions based on checkpoint
	local szSnapPos = "snapfire_start_pos"
	local szLichPos = "lich_start_pos"
	local checkpointTask = self:GetTask( self.szCheckpointTaskName )
	if checkpointTask ~= nil then
		szSnapPos = "snapfire_tp_pos"
		szLichPos = "lich_tp_pos"
	end

	-- Reposition allies
	self:ResetAlly( self.hSnapfireSpawner, szSnapPos )
	self:ResetAlly( self.hLichSpawner, szLichPos )

	CDotaNPXScenario.Restart( self )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnHeroFinishSpawn( hHero, hPlayer )
	CDotaNPXScenario.OnHeroFinishSpawn( self, hHero, hPlayer )

	print( 'OnHeroFinishSpawn' )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnNPCSpawned( hEnt )
	CDotaNPXScenario.OnNPCSpawned( self, hEnt )	

	if hEnt == nil or hEnt:IsNull() == true or hEnt:IsIllusion() == true then
		return
	end

	if hEnt:GetUnitName() == "npc_dota_hero_snapfire" then
		self.hSnapfire = hEnt

	elseif hEnt:GetUnitName() == "npc_dota_hero_lich" then
		self.hLich = hEnt

	elseif hEnt:GetUnitName() == "npc_dota_roshan" then
		self.hRoshan = hEnt
		self.hRoshan:AddItemByName( "item_aegis" )

		local Task1 = self:GetTask( "kill_roshan" )
		if Task1 then
			printf( "found task kill_roshan, doing SetUnitsToKill" )
			local hUnitsToKill = {}
			table.insert( hUnitsToKill, hEnt )
			Task1:SetUnitsToKill( hUnitsToKill )
		end

	elseif hEnt:GetUnitName() == "npc_dota_hero_juggernaut" then
		local Task2 = self:GetTask( "kill_juggernaut" )
		if Task2 then
			printf( "found task kill_juggernaut, doing SetUnitsToKill" )
			local hUnitsToKill = {}
			table.insert( hUnitsToKill, hEnt )
			Task2:SetUnitsToKill( hUnitsToKill )
		end

	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnTaskCompleted( event )
	CDotaNPXScenario.OnTaskCompleted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	print( 'Task Completed - ' .. Task:GetTaskName() )	

	if 	Task:GetTaskName() == "kill_roshan" then
		if event.success == 1 then
			self:ShowWizardTip( "scenario_roshan_wizard_tip_rosh_killed", 10.0 )

			local hPlayerHero = self:GetPlayerHero()

			RefreshHero( hPlayerHero )

			LearnHeroAbilities( hPlayerHero, {} )

			return
		end

	elseif Task:GetTaskName() == "pick_up_aegis" then
		local hTask = self:GetTask( "do_not_die" )
		hTask:CompleteTask( true )

	elseif Task:GetTaskName() == "kill_juggernaut" then
		if event.success == 1 then
			self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 2, function()
				
				self:OnScenarioRankAchieved( 1 )

			end )
		end
		
	end

	if event.checkpoint_skip == 1 then
		print( 'Checkpoint Skipping past the task completed logic for - ' .. Task:GetTaskName() )
		return
	end

	if Task:GetTaskName() == "intro_delay" then
		self:ShowWizardTip( "scenario_roshan_wizard_tip_intro", 10.0 )

		self.hRoshanSpawner = CDotaSpawner( "roshan_spawn_location", 
		{
			{
				EntityName = "npc_dota_roshan",
				Team = DOTA_TEAM_NEUTRALS,
				Count = 1,
				PositionNoise = 0.0
			},
		}, self, true )	

		self:AddSpawner( self.hRoshanSpawner )

	elseif Task:GetTaskName() == "move_to_location_1" then
		local hRoshanHintPos = Entities:FindByName( nil, "roshan_spawn_location" )
		if hRoshanHintPos then
			self:HintLocation( hRoshanHintPos:GetAbsOrigin(), true )
			self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 5, function()
				local hRoshanHintPos = Entities:FindByName( nil, "roshan_spawn_location" )
				if hRoshanHintPos then
					self:HintLocation( hRoshanHintPos:GetAbsOrigin(), false )
				end
			end )
		end

		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 0.25, function()
			
			if self.hSnapfire and self.hSnapfire.Bot then
				self.hSnapfire.Bot:SetMoveToPit( true )
			end

		end )

		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 0.75, function()
			
			if self.hLich and self.hLich.Bot then
				self.hLich.Bot:SetMoveToPit( true )
			end		

		end )

		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 3.0, function()
			
			self:ShowWizardTip( "scenario_roshan_wizard_tip_fight", 15.0 )

		end )


	elseif Task:GetTaskName() == "pick_up_aegis" then
		self:ShowWizardTip( "scenario_roshan_wizard_tip_aegis_pickup", 10.0 )

		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 0.25, function()
			
			if self.hLich and self.hLich.Bot then
				self.hLich.Bot:SetTpOut( true )
			end		

		end )
	
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 1.00, function()
			
			if self.hSnapfire and self.hSnapfire.Bot then
				self.hSnapfire.Bot:SetTpOut( true )
			end

		end )


	elseif Task:GetTaskName() == "exit_pit" then
		-- Reveal Juggernaut
		if self.hJuggernautSpawner then
			self:RevealSpawnedUnit( self.hJuggernautSpawner )
			local hJugg = self.hJuggernautSpawner:GetSpawnedUnits()[ 1 ]
			if hJugg then
				local Task2 = self:GetTask( "kill_juggernaut" )
				if Task2 then
					Task2:SetUnitsToKill( { hJugg } )
				end
			end
		end

	end

end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnSetupComplete()
	CDotaNPXScenario.OnSetupComplete( self )

	self:GetPlayerHero():SetAbilityPoints( 0 )

	local hTpScroll = self:GetPlayerHero():GetItemInSlot( DOTA_ITEM_TP_SCROLL )
	if hTpScroll ~= nil then
		self:GetPlayerHero():RemoveItem( hTpScroll )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnTaskStarted( event )
	CDotaNPXScenario.OnTaskStarted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Roshan:OnThink()
	CDotaNPXScenario.OnThink( self )
end

--------------------------------------------------------------------

function CDotaNPXScenario:OnItemPhysicalDestroyed( szItemName )
	if szItemName == "item_aegis" then
		self:OnScenarioComplete( false, "scenario_roshan_failure_aegis_denied" )
	end
end

--------------------------------------------------------------------

return CDotaNPXScenario_Roshan
