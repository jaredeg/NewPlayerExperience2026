
require( "npx_scenario" )
require( "tasks/task_parallel" )
require( "tasks/task_sequence" )
require( "tasks/task_kill_units" )
require( "tasks/task_move_to_location" )
require( "tasks/task_move_to_trigger" )
require( "tasks/task_protect_units" )

--------------------------------------------------------------------------------

if CDotaNPXScenario_LockdownSingleTarget == nil then
	CDotaNPXScenario_LockdownSingleTarget = class( {}, {}, CDotaNPXScenario )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:InitScenarioKeys()
	self.hScenario =
	{
		PreGameTime 		= 0.0,
		HeroSelectionTime 	= 0.0,
		StrategyTime 		= 0.0,
		ForceHero 			= "npc_dota_hero_shadow_shaman",
		StartingHeroLevel	= 5,
		Team 				= DOTA_TEAM_GOODGUYS,
		StartingGold		= 0,
		StartingItems 		=
		{
			"item_boots",
			"item_point_booster",
		},

		ScenarioTimeLimit = 0,
	}

	self.nCheckpoint = 0
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:SetupScenario()
	if not CDotaNPXScenario.SetupScenario( self ) then
		return false
	end

	GameRules:SetHeroRespawnEnabled( false )
	GameRules:GetGameModeEntity():SetDaynightCycleDisabled( true )
	GameRules:SetTimeOfDay( 0.251 )

	if self.nCheckpoint == 0 and not self.hLinaSpawner then
		-- Create Lina
		CDotaSpawner( "lina_spawner", 
		{
			{
				EntityName = "npc_dota_hero_lina",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Lina",
					EntityScript = "ai/lockdown_single_target/lina.lua",
					StartingHeroLevel = 6,
					StartingItems = 
					{
						"item_power_treads",
					},
					StartingAbilities	= 
					{
						"lina_laguna_blade",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "lina_laguna_blade" },
					},
				},
			}
		}, self, true )
	end

	-- Pre-spawn wave 2+ heroes frozen; revealed when player reaches them.
	-- NOTE: Do NOT call FreezeSpawnedUnit here — OnSpawnerFinished handles it.
	-- On restart, spawners persist — skip creating if they already exist.

	if self.nCheckpoint == 0 and not self.hBaneSpawner then
		CDotaSpawner( "bane_spawner", 
		{
			{
				EntityName = "npc_dota_hero_bane",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Bane",
					EntityScript = "ai/lockdown_single_target/bane.lua",
					StartingHeroLevel = 6,
					StartingItems = 
					{
						"item_power_treads",
					},
					StartingAbilities	= 
					{
						"bane_brain_sap",
						"bane_fiends_grip",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "bane_brain_sap", "bane_fiends_grip" },
					},
				},
			}
		}, self, true )
	end

	if not self.hDrowSpawner then
		CDotaSpawner( "drow_spawner", 
		{
			{
				EntityName = "npc_dota_hero_drow_ranger",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Drow Ranger",
					EntityScript = "ai/lockdown_single_target/drow_ranger.lua",
					StartingHeroLevel = 5,
					StartingItems = 
					{
						"item_boots",
						"item_gloves",
						"item_wraith_band",
						"item_wraith_band",
						"item_yasha",
					},
					StartingAbilities	= 
					{
						"drow_ranger_trueshot",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "drow_ranger_trueshot" },
					},
				},
			},
		}, self, true )
	else
		-- Re-freeze existing Drow for reuse
		local hDrow = self.hDrowSpawner:GetSpawnedUnits()[ 1 ]
		if hDrow and not hDrow:IsNull() then
			local hDrowSpawnEnt = Entities:FindByName( nil, "drow_spawner" )
			if hDrowSpawnEnt then
				hDrow.vSpawnOrigin = hDrowSpawnEnt:GetAbsOrigin()
			end
			if not hDrow.bFrozen then
				hDrow.bFrozen = true
				hDrow:AddNewModifier( nil, nil, "modifier_invulnerable", {} )
				hDrow:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
			end
			if not hDrow:IsAlive() then
				hDrow:RespawnHero( false, false )
				hDrow:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
			end
		end
	end

	if not self.hQueenOfPainSpawner then
		CDotaSpawner( "queenofpain_spawner", 
		{
			{
				EntityName = "npc_dota_hero_queenofpain",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Queen of Pain",
					EntityScript = "ai/lockdown_single_target/queenofpain.lua",
					StartingHeroLevel = 5,
					StartingItems = 
					{
						"item_power_treads",
					},
					StartingAbilities	= 
					{
						"queenofpain_blink",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "queenofpain_blink" },
					},
				},
			}
		}, self, true )
	else
		-- Re-freeze existing QoP for reuse
		local hQoP = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
		if hQoP and not hQoP:IsNull() then
			local hQoPSpawnEnt = Entities:FindByName( nil, "queenofpain_spawner" )
			if hQoPSpawnEnt then
				hQoP.vSpawnOrigin = hQoPSpawnEnt:GetAbsOrigin()
			end
			if not hQoP.bFrozen then
				hQoP.bFrozen = true
				hQoP:AddNewModifier( nil, nil, "modifier_invulnerable", {} )
				hQoP:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
			end
			if not hQoP:IsAlive() then
				hQoP:RespawnHero( false, false )
				hQoP:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
			end
			-- Reset QoP AI state for the new attempt
			hQoP:Stop()
			if hQoP.Bot then
				hQoP.Bot.nBotState = 0  -- QUEENOFPAIN_BOT_STATE_IDLE
				hQoP.Bot.bRuneCommandGiven = nil
				hQoP.Bot.bHealthInitialized = nil
				hQoP.Bot.bWasKilled = nil
				hQoP.Bot.fTimeSectionStarted = nil
			end
		end
	end

	self.nTaskListener = ListenToGameEvent( "trigger_start_touch", Dynamic_Wrap( CDotaNPXScenario_LockdownSingleTarget, "OnTriggerStartTouch" ), self )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:SetupTasks()
	if not CDotaNPXScenario.SetupTasks( self ) then
		return false
	end

	if self.Tasks == nil then
		self.Tasks = {}
	end

	local szPlayerToDrowMoveLoc = "player_to_drow_move_loc"
	self.hPlayerToDrowMoveLoc = Entities:FindByName( nil, szPlayerToDrowMoveLoc )
	ScriptAssert( self.hPlayerToDrowMoveLoc ~= nil, "Could not find entity named %s!", szPlayerToDrowMoveLoc )

	local szPlayerToLinaMoveLoc = "player_to_lina_move_loc"
	self.hPlayerToLinaMoveLoc = Entities:FindByName( nil, szPlayerToLinaMoveLoc )
	ScriptAssert( self.hPlayerToLinaMoveLoc ~= nil, "Could not find entity named %s!", szPlayerToLinaMoveLoc )

	local rootTask = CDotaNPXTask_Sequence( {
		TaskName = "root",
		Hidden = true,
	}, self )
	table.insert( self.Tasks, rootTask )
	rootTask.CheckTaskStart = function() return true end

	local MoveToLina = rootTask:AddTask( CDotaNPXTask_MoveToLocation( {
		TaskName = "move_to_lina",
		TaskType = "task_move_to_location",
		TaskParams = 
		{				
			GoalLocation = self.hPlayerToLinaMoveLoc:GetAbsOrigin(),
			GoalDistance = 64,
		},
		UseHints = true,
	}, self ), 1.0 )

	local ProtectLinaParallelTask = rootTask:AddTask( CDotaNPXTask_Parallel( {
		TaskName = "protect_lina_parallel",
		Hidden = true,
	}, self ), 0.25 )

	local ProtectLinaTask = ProtectLinaParallelTask:AddTask( CDotaNPXTask_ProtectUnits( {
		TaskName = "protect_lina",
		TaskParams =
		{
			FailureString = "lockdown_single_target_failure_protect_units",
		},
	}, self ), 0.25 )

	local MovingPastLinaTrigger = ProtectLinaParallelTask:AddTask( CDotaNPXTask_MoveToTrigger( {
		TaskName = "moving_past_lina_trigger",
		TaskType = "task_move_to_trigger",
		Hidden = true,
		TaskParams =
		{
			TriggerName = "player_moving_past_lina_trigger",
		},
		UseHints = false,
	}, self ), 0.25 )

	local GroupUpWithDrow = rootTask:AddTask( CDotaNPXTask_MoveToLocation( {
		TaskName = "move_to_drow_ranger",
		TaskType = "task_move_to_location",
		UseHints = true,
		TaskParams =
		{
			GoalLocation = self.hPlayerToDrowMoveLoc:GetAbsOrigin(),
			GoalDistance = 64,
		},
	}, self ), 3.0 )

	local KillQueenOfPainParallel = rootTask:AddTask( CDotaNPXTask_Parallel( {
		TaskName = "kill_queenofpain_parallel",
		Hidden = true,
	}, self ), 0.5 )

	local MovingPastDrowTrigger = KillQueenOfPainParallel:AddTask( CDotaNPXTask_MoveToTrigger( {
		TaskName = "moving_past_drow",
		TaskType = "task_move_to_trigger",
		Hidden = true,
		TaskParams =
		{
			TriggerName = "player_moving_past_drow_trigger",
		},
		UseHints = false,
	}, self ), 1.0 )

	local KillQueenOfPain = KillQueenOfPainParallel:AddTask( CDotaNPXTask_KillUnits( {
		TaskName = "kill_queenofpain",
		TaskType = "task_kill_units",
		TaskParams =
		{
		},
	}, self ), 1.0 )

	return true
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnTriggerStartTouch( event )
	--printf( "OnTriggerStartTouch" )

	--[[
	local hPlayerHero = PlayerResource:GetSelectedHeroEntity( 0 )
	if hPlayerHero and event.trigger_name == "start_trigger" and event.activator_entindex == hPlayerHero:GetEntityIndex() then
		--
	end
	]]
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnSetupComplete()
	CDotaNPXScenario.OnSetupComplete( self )

	self.hPlayerHero = PlayerResource:GetSelectedHeroEntity( 0 )

	-- Disable unwanted abilities (Fowl Play innate, Chicken Fingers facet, etc.)
	-- Keep only: ether_shock, voodoo (hex), shackles, mass_serpent_ward
	local rgAllowedAbilities = {
		["shadow_shaman_ether_shock"] = true,
		["shadow_shaman_voodoo"] = true,
		["shadow_shaman_shackles"] = true,
		["shadow_shaman_mass_serpent_ward"] = true,
	}
	for i = 0, self.hPlayerHero:GetAbilityCount() - 1 do
		local hAbility = self.hPlayerHero:GetAbilityByIndex( i )
		if hAbility then
			local szName = hAbility:GetAbilityName()
			-- Skip generic/internal abilities
			if szName and szName ~= "" and not string.find( szName, "generic_hidden" ) and not string.find( szName, "attribute_bonus" ) then
				if not rgAllowedAbilities[ szName ] then
					hAbility:SetLevel( 0 )
					hAbility:SetActivated( false )
					hAbility:SetHidden( true )
					-- For passive/innate abilities that proc on attack (Chicken Fingers / Fowl Play),
					-- also remove the ability entirely to prevent the passive from triggering
					if szName == "shadow_shaman_fowl_play" or szName == "shadow_shaman_voodoo_hands" then
						self.hPlayerHero:RemoveAbility( szName )
						printf( "Removed Shadow Shaman ability: %s", szName )
					else
						printf( "Disabled unwanted Shadow Shaman ability: %s", szName )
					end
				end
			end
		end
	end

	-- Level up Shadow Shaman's abilities
	for i = 1, 3 do
		if self.hPlayerHero:GetAbilityPoints() > 0 then
			local hShacklesAbility = self.hPlayerHero:FindAbilityByName( "shadow_shaman_shackles" )
			if hShacklesAbility ~= nil then
				self.hPlayerHero:UpgradeAbility( hShacklesAbility )
			else
				print( "WARNING: shadow_shaman_shackles not found - facet may have renamed it" )
			end
		end
	end

	self.hPlayerHero:SetAbilityPoints( 0 )

	if self.nCheckpoint == 1 then
		printf( "CHECKPOINT 1" )
		local bForceStart = true
		self:CheckpointSkipCompleteTask( "move_to_lina", true, bForceStart )
		self:CheckpointSkipCompleteTask( "protect_lina_parallel", true )
		self:CheckpointSkipCompleteTask( "protect_lina", true )
		self:CheckpointSkipCompleteTask( "moving_past_lina_trigger", true )
		self:CheckpointSkipCompleteTask( "move_to_drow_ranger", true )

		if self:GetPlayerHero() ~= nil then
			LearnHeroAbilities( self:GetPlayerHero(), {} )

			self:GetPlayerHero():SetGold( 0, true ) 
			self:GetPlayerHero():SetGold( 0, false ) 

			local hCheckpoints = Entities:FindAllByName( "checkpoint_1" )
			if hCheckpoints[ 1 ] ~= nil then
				FindClearSpaceForUnit( self:GetPlayerHero(), hCheckpoints[ 1 ]:GetAbsOrigin(), true )
				SendToConsole( "+dota_camera_center_on_hero" )
				SendToConsole( "-dota_camera_center_on_hero" )
			end
		end
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnTaskStarted( event )
	CDotaNPXScenario.OnTaskStarted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	if Task:GetTaskName() == "move_to_lina" then
		self:ShowWizardTip( "lockdown_single_target_tip_channeled_spells", 8.0 )
		self:ShowUIHint( "Ability2 AbilityButton" )
	end

	if Task:GetTaskName() == "move_to_drow_ranger" then
		if self.hLinaSpawner then
			self.hLinaSpawner:RemoveSpawnedUnits()
		end

		self:ShowWizardTip( "lockdown_single_target_tip_hex_gained", 8.0 )
		self:ShowUIHint( "Ability1 AbilityButton" )
	end

	if Task:GetTaskName() == "kill_queenofpain" then
		local hBountyLoc = Entities:FindByName( nil, "bounty_rune_location" )
		self.hRune = CreateRune( hBountyLoc:GetAbsOrigin(), DOTA_RUNE_BOUNTY )

		self:ShowWizardTip( "lockdown_single_target_tip_queenofpain_blink", 8.0 )
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnTaskCompleted( event )
	CDotaNPXScenario.OnTaskCompleted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	if Task:GetTaskName() == "protect_lina" then
		-- Only proceed if task succeeded (Lina survived)
		if event.success == 0 then
			return
		end

		local hPlayerHero = self:GetPlayerHero()
		if hPlayerHero then
			self.hPlayerHero:SetAbilityPoints( 2 )

			for i = 1, 2 do
				if self.hPlayerHero:GetAbilityPoints() > 0 then
					local hVoodooAbility = self.hPlayerHero:FindAbilityByName( "shadow_shaman_voodoo" )
					if hVoodooAbility ~= nil then
						self.hPlayerHero:UpgradeAbility( hVoodooAbility )
					else
						print( "WARNING: shadow_shaman_voodoo not found - hex facet may have renamed it" )
					end
				end
			end

			RefreshHero( hPlayerHero )
		end

		-- Remove Bane once Lina is safe
		if self.hBaneSpawner then
			self.hBaneSpawner:RemoveSpawnedUnits()
		end

		-- Reveal Drow (pre-spawned frozen in SetupScenario)
		if self.hDrowSpawner then self:RevealSpawnedUnit( self.hDrowSpawner ) end
	elseif Task:GetTaskName() == "move_to_drow_ranger" then
		self:HideUIHint()

		self.nCheckpoint = 1

		-- Make QoP visible (pre-spawned frozen in SetupScenario)
		if self.hQueenOfPainSpawner then
			self:RevealSpawnedUnit( self.hQueenOfPainSpawner )
			-- Wire up kill task now that tasks exist
			local hQoP = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
			if hQoP then
				local killTask = self:GetTask( "kill_queenofpain" )
				if killTask then
					killTask:SetUnitsToKill( { hQoP } )
				end
			end
		end
	elseif Task:GetTaskName() == "kill_queenofpain" then
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 2.0, function()
			self:OnScenarioComplete( true )
		end )
	end	



	if event.checkpoint_skip == 1 then
		printf( "Checkpoint Skipping past the task completed logic for \"%s\"", Task:GetTaskName() )
		return
	end



	if Task:GetTaskName() == "move_to_lina" then
		-- Reveal Bane (freshly spawned frozen in SetupScenario)
		if self.hBaneSpawner then self:RevealSpawnedUnit( self.hBaneSpawner ) end
	elseif Task:GetTaskName() == "moving_past_lina_trigger" then
		self:HideUIHint()
	end
end	

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnSpawnerFinished( event )
	CDotaNPXScenario.OnSpawnerFinished( self, event )

	local hSpawner = self:GetSpawner( event.spawner_name )
	if hSpawner == nil then
		printf( "WARNING: OnSpawnerFinished could not find spawner '%s'", event.spawner_name )
		return
	end

	printf( "OnSpawnerFinished - event.spawner_name == %s", event.spawner_name )

	if event.spawner_name == "lina_spawner" then
		self.hLinaSpawner = hSpawner
		-- Lina is wave 1, no freeze needed

	elseif event.spawner_name == "bane_spawner" then
		self.hBaneSpawner = hSpawner
		self:FreezeSpawnedUnit( hSpawner )

	elseif event.spawner_name == "drow_spawner" then
		self.hDrowSpawner = hSpawner
		self:FreezeSpawnedUnit( hSpawner )

	elseif event.spawner_name == "queenofpain_spawner" then
		self.hQueenOfPainSpawner = hSpawner
		self:FreezeSpawnedUnit( hSpawner )
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnNPCSpawned( hEnt )
	CDotaNPXScenario.OnNPCSpawned( self, hEnt )	

	if hEnt ~= nil and hEnt:IsNull() == false and hEnt:GetUnitName() == "npc_dota_hero_lina" then
		local ProtectLinaTask = self:GetTask( "protect_lina" )
		if ProtectLinaTask and ProtectLinaTask.hUnitsToProtect == nil then
			printf( "Task protect_lina - Setting units to protect" )
			ProtectLinaTask.hUnitsToProtect = {}
			table.insert( ProtectLinaTask.hUnitsToProtect, self.hPlayerHero )
			table.insert( ProtectLinaTask.hUnitsToProtect, hEnt )

			ProtectLinaTask:SetUnitsToProtect( ProtectLinaTask.hUnitsToProtect )
		end
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnEntityKilled( hVictim, hKiller, hInflictor )
	CDotaNPXScenario.OnEntityKilled( self, hVictim )	
	--[[
	if hVictim:GetUnitName() == "npc_dota_hero_queenofpain" then
		-- empty
	end	
	]]
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:OnTriggerStartTouch( sTriggerName, hActivator, hCaller )
	printf( "CDotaNPXScenario_LockdownSingleTarget:OnTriggerStartTouch" )

	if self.hQueenOfPainSpawner then
		local hQueenOfPain = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
		if sTriggerName == "queenofpain_escape_trigger" and hActivator and hActivator == hQueenOfPain then
			-- This is probably a hack
			printf( "QoP touched escape trigger; scenario failed" )
			self:OnScenarioComplete( false, "lockdown_single_target_failure_queenofpain_escaped" )
		end
	end

	if self.hLinaSpawner then
		local hLina = self.hLinaSpawner:GetSpawnedUnits()[ 1 ]
		if sTriggerName == "home_trigger" and hActivator and hActivator == hLina then
			printf( "Lina touched home trigger; task completed" )
			local hTask = GameRules.DotaNPX:GetTask( "protect_lina" )
			if hTask ~= nil and hTask:IsCompleted() == false then
				hTask:CompleteTask( true )
			end
		end
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_LockdownSingleTarget:Restart()
	UTIL_RemoveImmediate( self.hRune )

	-- Respawn Lina if she died and move her back to her spawn point
	if self.hLinaSpawner then
		local hLina = self.hLinaSpawner:GetSpawnedUnits()[ 1 ]
		if hLina and not hLina:IsNull() then
			if not hLina:IsAlive() then
				hLina:RespawnHero( false, false )
			end
			hLina:SetHealth( hLina:GetMaxHealth() )
			hLina:SetMana( hLina:GetMaxMana() )
			hLina:RemoveModifierByName( "modifier_invulnerable" )
			-- Move Lina back to her spawn location
			local hSpawnEnt = Entities:FindByName( nil, "lina_spawner" )
			if hSpawnEnt then
				FindClearSpaceForUnit( hLina, hSpawnEnt:GetAbsOrigin(), true )
			end
			hLina:Stop()
			-- Reset Lina bot state
			if hLina.Bot then
				hLina.Bot.bActivated = false
				hLina.Bot.hTownPortalItem = nil
				hLina.Bot.hAttackTarget = nil
				hLina.Bot.nBotState = 0  -- IDLE
			end
		end
	end

	-- Refreeze Bane — he's still alive when protect_lina fails (Lina died, not Bane).
	if self.hBaneSpawner then
		local hBane = self.hBaneSpawner:GetSpawnedUnits()[ 1 ]
		if hBane and not hBane:IsNull() then
			-- Move Bane back to his map spawn point BEFORE freezing,
			-- so FreezeSpawnedUnit captures the correct vSpawnOrigin.
			local hSpawnEnt = Entities:FindByName( nil, "bane_spawner" )
			if hSpawnEnt then
				FindClearSpaceForUnit( hBane, hSpawnEnt:GetAbsOrigin(), true )
			end
			hBane:Stop()
			hBane:SetHealth( hBane:GetMaxHealth() )
			hBane:SetMana( hBane:GetMaxMana() )
			hBane.bFrozen = false  -- Clear frozen so FreezeSpawnedUnit can set it fresh
			hBane:RemoveModifierByName( "modifier_invulnerable" )
			-- End all cooldowns
			for i = 0, hBane:GetAbilityCount() - 1 do
				local hAbility = hBane:GetAbilityByIndex( i )
				if hAbility then hAbility:EndCooldown() end
			end
			-- Reset bot state — critical! Without this, Bane checks
			-- IsTaskComplete("protect_lina") which returns true from
			-- the previous failed round, causing him to UTIL_Remove himself.
			if hBane.Bot then
				hBane.Bot.nBotState = 0  -- BANE_BOT_STATE_IDLE
				hBane.Bot.bWasKilled = nil
			end
			-- Now freeze using the same function as initial spawn
			self:FreezeSpawnedUnit( self.hBaneSpawner )
			printf( "Restart: Refroze Bane at spawn point" )
		else
			printf( "Restart: Bane spawner has no valid unit, clearing for recreation" )
			self.hBaneSpawner = nil
		end
	end

	CDotaNPXScenario.Restart( self )

	-- After base Restart (which re-creates tasks), wire up protect_lina units.
	-- OnNPCSpawned won't fire for existing heroes, so we must do it here.
	if self.hLinaSpawner then
		local hLina = self.hLinaSpawner:GetSpawnedUnits()[ 1 ]
		local hPlayerHero = PlayerResource:GetSelectedHeroEntity( 0 )
		if hLina and not hLina:IsNull() and hPlayerHero and not hPlayerHero:IsNull() then
			local ProtectLinaTask = self:GetTask( "protect_lina" )
			if ProtectLinaTask then
				ProtectLinaTask.hUnitsToProtect = {}
				table.insert( ProtectLinaTask.hUnitsToProtect, hPlayerHero )
				table.insert( ProtectLinaTask.hUnitsToProtect, hLina )
				ProtectLinaTask:SetUnitsToProtect( ProtectLinaTask.hUnitsToProtect )
			end
		end
	end
end

--------------------------------------------------------------------------------

return CDotaNPXScenario_LockdownSingleTarget
