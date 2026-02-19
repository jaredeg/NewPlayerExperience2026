
require( "npx_scenario" )
require( "tasks/task_parallel" )
require( "tasks/task_sequence" )
require( "tasks/task_kill_units" )
require( "tasks/task_move_to_location" )
require( "tasks/task_move_to_trigger" )
require( "tasks/task_protect_units" )
require( "hero_ability_utils" )

--------------------------------------------------------------------------------

if CDotaNPXScenario_InitiationTeamfight == nil then
	CDotaNPXScenario_InitiationTeamfight = class( {}, {}, CDotaNPXScenario )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:InitScenarioKeys()
	self.hScenario =
	{
		PreGameTime 		= 0.0,
		HeroSelectionTime 	= 0.0,
		StrategyTime 		= 0.0,
		ForceHero 			= "npc_dota_hero_tidehunter",
		StartingHeroLevel	= 6,
		Team 				= DOTA_TEAM_GOODGUYS,
		StartingGold		= 0,
		StartingItems 		=
		{
			"item_boots",
			"item_point_booster",
			"item_chainmail",
			--"item_blink",
		},
		StartingAbilities	= 
		{
			"tidehunter_ravage",
		}, 
		AbilityBuild = 
		{
			AbilityPriority = { "tidehunter_ravage" },
		},

		StartingHealthPct	= 0.6,
		ScenarioTimeLimit = 0,
	}

	self.nCheckpoint = 0
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:SetupScenario()
	if not CDotaNPXScenario.SetupScenario( self ) then
		return false
	end

	GameRules:SetHeroRespawnEnabled( false )
	GameRules:GetGameModeEntity():SetDaynightCycleDisabled( true )
	GameRules:SetTimeOfDay( 0.251 )

	self.bPartTwoEarlyTriggerActivated = false
	self.bP2Active = false  -- Set true when move_to_p2_loc completes

	-- Tower references are always needed
	self.hRadiantMidTower = Entities:FindByName( nil, "dota_goodguys_tower1_mid" )
	ScriptAssert( self.hRadiantMidTower ~= nil, "self.hRadiantMidTower is nil!" )

	self.hDireMidTower = Entities:FindByName( nil, "dota_badguys_tower1_mid" )
	ScriptAssert( self.hDireMidTower ~= nil, "self.hDireMidTower is nil!" )

	if self.nCheckpoint == 0 then
		self.hRadiantMidTower:SetHealth( self.hRadiantMidTower:GetMaxHealth() * 0.2 )
		self.hDireMidTower:SetHealth( self.hDireMidTower:GetMaxHealth() * 0.5 )
	end

	-- On the first play, create all bot heroes via spawners (async precache
	-- loads cosmetic resources).  On restart, the bots already exist —
	-- just reset and reposition them.
	local bRestart = ( self.hQueenOfPainSpawner ~= nil )

	if not bRestart then
		-- FIRST RUN: create all 8 spawners.  OnSpawnerFinished handles
		-- freeze/disable after async precache completes.
		if self.nCheckpoint == 0 then
		self.hQueenOfPainSpawner = CDotaSpawner( "queenofpain_spawner", 
	{
		{
			EntityName = "npc_dota_hero_queenofpain",
			Team = DOTA_TEAM_GOODGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Queen of Pain",
				EntityScript = "ai/initiation_teamfight/queenofpain.lua",
				StartingHeroLevel = 7,
				StartingItems = 
				{
					"item_power_treads",
					"item_null_talisman",
					"item_null_talisman",
				},
				StartingAbilities	= 
				{
					"queenofpain_scream_of_pain",
					"queenofpain_sonic_wave",
					"queenofpain_shadow_strike",
					"queenofpain_blink",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "queenofpain_scream_of_pain", "queenofpain_sonic_wave", "queenofpain_shadow_strike", "queenofpain_blink" },
				},
			},
		},
	}, self, true )

	-- Phase 1 enemies
	self.hWraithKingSpawner = CDotaSpawner( "wraith_king_spawner", 
	{
		{
			EntityName = "npc_dota_hero_skeleton_king",
			Team = DOTA_TEAM_BADGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Wraith King",
				EntityScript = "ai/initiation_teamfight/wraith_king.lua",
				StartingHeroLevel = 5,
				StartingItems = 
				{
					"item_power_treads",
					"item_platemail",
					"item_desolator",
				},
				StartingAbilities	= 
				{
					"skeleton_king_hellfire_blast",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "skeleton_king_hellfire_blast" },
				},
			},
		},
	}, self, true )

	self.hSniperSpawner = CDotaSpawner( "sniper_spawner", 
	{
		{
			EntityName = "npc_dota_hero_sniper",
			Team = DOTA_TEAM_BADGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Sniper",
				EntityScript = "ai/initiation_teamfight/sniper.lua",
				StartingHeroLevel = 6,
				StartingItems =
				{
					"item_power_treads",
					"item_wraith_band",
				},
				StartingAbilities	= 
				{
					"sniper_assassinate",
					"sniper_take_aim",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "sniper_take_aim", "sniper_assassinate" },
				},
			},
		},
	}, self, true )

	-- Phase 2 allies
	self.hLionP2Spawner = CDotaSpawner( "p2_lion_spawner", 
	{
		{
			EntityName = "npc_dota_hero_lion",
			Team = DOTA_TEAM_GOODGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Lion",
				EntityScript = "ai/initiation_teamfight/lion_p2.lua",
				StartingHeroLevel = 7,
				StartingItems = 
				{
					"item_arcane_boots",
					"item_null_talisman",
					"item_blink",
				},
				StartingAbilities = 
				{
					"lion_finger_of_death",
					"lion_impale",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "lion_finger_of_death", "lion_impale" },
				},
			},
		},
	}, self, true )

	self.hDragonKnightP2Spawner = CDotaSpawner( "p2_dragon_knight_spawner", 
	{
		{
			EntityName = "npc_dota_hero_dragon_knight",
			Team = DOTA_TEAM_GOODGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Dragon Knight",
				EntityScript = "ai/initiation_teamfight/dragon_knight_p2.lua",
				StartingHeroLevel = 6,
				StartingItems =
				{
					"item_power_treads",
					"item_hyperstone",
					"item_lesser_crit",
					"item_blink",
				},
				StartingAbilities	=
				{
					"dragon_knight_elder_dragon_form",
				},
				AbilityBuild =
				{
					AbilityPriority = { "dragon_knight_elder_dragon_form" },
				},
			},
		},
	}, self, true )

	-- Phase 2 enemies
	self.hWraithKingP2Spawner = CDotaSpawner( "p2_wraith_king_spawner", 
	{
		{
			EntityName = "npc_dota_hero_skeleton_king",
			Team = DOTA_TEAM_BADGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Wraith King",
				EntityScript = "ai/initiation_teamfight/wraith_king_p2.lua",
				StartingHeroLevel = 5,
				StartingItems = 
				{
					"item_power_treads",
					"item_hyperstone",
					"item_desolator",
				},
				StartingAbilities	= 
				{
					"skeleton_king_hellfire_blast",
					"skeleton_king_vampiric_aura",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "skeleton_king_hellfire_blast", "skeleton_king_vampiric_aura" },
				},
			},
		},
	}, self, true )

	self.hSniperP2Spawner = CDotaSpawner( "p2_sniper_spawner", 
	{
		{
			EntityName = "npc_dota_hero_sniper",
			Team = DOTA_TEAM_BADGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Sniper",
				EntityScript = "ai/initiation_teamfight/sniper_p2.lua",
				StartingHeroLevel = 6,
				StartingItems =
				{
					"item_power_treads",
					"item_wraith_band",
					"item_wraith_band",
					"item_desolator",
				},
				StartingAbilities	= 
				{
					"sniper_assassinate",
					"sniper_take_aim",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "sniper_take_aim", "sniper_assassinate" },
				},
			},
		},
	}, self, true )

	self.hEnigmaP2Spawner = CDotaSpawner( "p2_enigma_spawner", 
	{
		{
			EntityName = "npc_dota_hero_enigma",
			Team = DOTA_TEAM_BADGUYS,
			Count = 1,
			PositionNoise = 0,
			BotPlayer =
			{
				BotName = "Enigma",
				EntityScript = "ai/initiation_teamfight/enigma_p2.lua",
				StartingHeroLevel = 7,
				StartingItems = 
				{
					"item_arcane_boots",
					"item_null_talisman",
					"item_black_king_bar",
					"item_blink",
				},
				StartingAbilities	= 
				{
					"enigma_black_hole",
					"enigma_midnight_pulse",
				}, 
				AbilityBuild = 
				{
					AbilityPriority = { "enigma_black_hole", "enigma_midnight_pulse" },
				},
			},
		},
	}, self, true )

		-- Freeze and WK disable are handled in OnSpawnerFinished since
		-- spawners use async precache and units may not exist yet.
	elseif self.nCheckpoint == 1 then
		-- Checkpoint 1: create all 8 bots (for cosmetics), then remove P1,
		-- freeze P2 until move_to_p2_loc completes via CheckpointSkip.
		self.hQueenOfPainSpawner = CDotaSpawner( "queenofpain_spawner", 
		{
			{
				EntityName = "npc_dota_hero_queenofpain",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Queen of Pain",
					EntityScript = "ai/initiation_teamfight/queenofpain.lua",
					StartingHeroLevel = 7,
					StartingItems = 
					{
						"item_power_treads",
						"item_null_talisman",
						"item_null_talisman",
					},
					StartingAbilities	= 
					{
						"queenofpain_scream_of_pain",
						"queenofpain_sonic_wave",
						"queenofpain_shadow_strike",
						"queenofpain_blink",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "queenofpain_scream_of_pain", "queenofpain_sonic_wave", "queenofpain_shadow_strike", "queenofpain_blink" },
					},
				},
			},
		}, self, true )

		self.hWraithKingSpawner = CDotaSpawner( "wraith_king_spawner", 
		{
			{
				EntityName = "npc_dota_hero_skeleton_king",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Wraith King",
					EntityScript = "ai/initiation_teamfight/wraith_king.lua",
					StartingHeroLevel = 5,
					StartingItems = 
					{
						"item_power_treads",
						"item_platemail",
						"item_desolator",
					},
					StartingAbilities	= 
					{
						"skeleton_king_hellfire_blast",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "skeleton_king_hellfire_blast" },
					},
				},
			},
		}, self, true )

		self.hSniperSpawner = CDotaSpawner( "sniper_spawner", 
		{
			{
				EntityName = "npc_dota_hero_sniper",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Sniper",
					EntityScript = "ai/initiation_teamfight/sniper.lua",
					StartingHeroLevel = 6,
					StartingItems =
					{
						"item_power_treads",
						"item_wraith_band",
					},
					StartingAbilities	= 
					{
						"sniper_assassinate",
						"sniper_take_aim",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "sniper_take_aim", "sniper_assassinate" },
					},
				},
			},
		}, self, true )

		self.hLionP2Spawner = CDotaSpawner( "p2_lion_spawner", 
		{
			{
				EntityName = "npc_dota_hero_lion",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Lion",
					EntityScript = "ai/initiation_teamfight/lion_p2.lua",
					StartingHeroLevel = 7,
					StartingItems = 
					{
						"item_arcane_boots",
						"item_null_talisman",
						"item_blink",
					},
					StartingAbilities = 
					{
						"lion_finger_of_death",
						"lion_impale",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "lion_finger_of_death", "lion_impale" },
					},
				},
			},
		}, self, true )

		self.hDragonKnightP2Spawner = CDotaSpawner( "p2_dragon_knight_spawner", 
		{
			{
				EntityName = "npc_dota_hero_dragon_knight",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Dragon Knight",
					EntityScript = "ai/initiation_teamfight/dragon_knight_p2.lua",
					StartingHeroLevel = 6,
					StartingItems =
					{
						"item_power_treads",
						"item_hyperstone",
						"item_lesser_crit",
						"item_blink",
					},
					StartingAbilities	=
					{
						"dragon_knight_elder_dragon_form",
					},
					AbilityBuild =
					{
						AbilityPriority = { "dragon_knight_elder_dragon_form" },
					},
				},
			},
		}, self, true )

		self.hWraithKingP2Spawner = CDotaSpawner( "p2_wraith_king_spawner", 
		{
			{
				EntityName = "npc_dota_hero_skeleton_king",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Wraith King",
					EntityScript = "ai/initiation_teamfight/wraith_king_p2.lua",
					StartingHeroLevel = 5,
					StartingItems = 
					{
						"item_power_treads",
						"item_hyperstone",
						"item_desolator",
					},
					StartingAbilities	= 
					{
						"skeleton_king_hellfire_blast",
						"skeleton_king_vampiric_aura",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "skeleton_king_hellfire_blast", "skeleton_king_vampiric_aura" },
					},
				},
			},
		}, self, true )

		self.hSniperP2Spawner = CDotaSpawner( "p2_sniper_spawner", 
		{
			{
				EntityName = "npc_dota_hero_sniper",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Sniper",
					EntityScript = "ai/initiation_teamfight/sniper_p2.lua",
					StartingHeroLevel = 6,
					StartingItems =
					{
						"item_power_treads",
						"item_wraith_band",
						"item_wraith_band",
						"item_desolator",
					},
					StartingAbilities	= 
					{
						"sniper_assassinate",
						"sniper_take_aim",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "sniper_take_aim", "sniper_assassinate" },
					},
				},
			},
		}, self, true )

		self.hEnigmaP2Spawner = CDotaSpawner( "p2_enigma_spawner", 
		{
			{
				EntityName = "npc_dota_hero_enigma",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Enigma",
					EntityScript = "ai/initiation_teamfight/enigma_p2.lua",
					StartingHeroLevel = 7,
					StartingItems = 
					{
						"item_arcane_boots",
						"item_null_talisman",
						"item_black_king_bar",
						"item_blink",
					},
					StartingAbilities	= 
					{
						"enigma_black_hole",
						"enigma_midnight_pulse",
					}, 
					AbilityBuild = 
					{
						AbilityPriority = { "enigma_black_hole", "enigma_midnight_pulse" },
					},
				},
			},
		}, self, true )

		-- Remove/freeze handled in OnSpawnerFinished since spawns are async.
		end  -- end checkpoint gate
	else
		-- RESTART: reset all existing bot heroes.
		-- ResetSpawnedUnit leaves every bot frozen offmap with invulnerable.
		printf( "RESTART: resetting all bot heroes (bRestart=true)" )
		self:ResetSpawnedUnit( self.hQueenOfPainSpawner )
		self:ResetSpawnedUnit( self.hWraithKingSpawner )
		self:ResetSpawnedUnit( self.hSniperSpawner )
		self:ResetSpawnedUnit( self.hLionP2Spawner )
		self:ResetSpawnedUnit( self.hDragonKnightP2Spawner )
		self:ResetSpawnedUnit( self.hWraithKingP2Spawner )
		self:ResetSpawnedUnit( self.hSniperP2Spawner )
		self:ResetSpawnedUnit( self.hEnigmaP2Spawner )

		-- Re-disable WK reincarnation (Purge cleared it)
		self:DisableWKReincarnation( self.hWraithKingSpawner )
		self:DisableWKReincarnation( self.hWraithKingP2Spawner )

		-- Reset tower health (re-find in case handles went stale)
		self.hRadiantMidTower = Entities:FindByName( nil, "dota_goodguys_tower1_mid" )
		self.hDireMidTower = Entities:FindByName( nil, "dota_badguys_tower1_mid" )
		if self.hRadiantMidTower and not self.hRadiantMidTower:IsNull() and self.hRadiantMidTower:IsAlive() then
			self.hRadiantMidTower:SetHealth( self.hRadiantMidTower:GetMaxHealth() * 0.2 )
		end
		if self.hDireMidTower and not self.hDireMidTower:IsNull() and self.hDireMidTower:IsAlive() then
			self.hDireMidTower:SetHealth( self.hDireMidTower:GetMaxHealth() * 0.5 )
		end

		if self.nCheckpoint == 0 then
			-- QoP is the only bot active at scenario start.
			-- Reveal her and add disable_healing.  Everything else stays frozen
			-- until go_into_trees / move_to_p2_loc tasks complete.
			self:RevealSpawnedUnit( self.hQueenOfPainSpawner )
			local hQueenOfPain = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
			if hQueenOfPain then
				hQueenOfPain:AddNewModifier( hQueenOfPain, nil, "modifier_disable_healing", { duration = -1 } )
				-- AI bScenarioReset sets 40% HP but hasn't ticked yet.
				-- Set it here so the player never sees full-HP QoP.
				hQueenOfPain:SetHealth( hQueenOfPain:GetMaxHealth() * 0.4 )
			end
		end
		-- Checkpoint 1: everything stays frozen.  CheckpointSkip will
		-- complete move_to_p2_loc which calls RevealSpawnedUnit on P2 heroes.
	end  -- end bRestart

	-- Clean up old trigger listener from previous run
	if self.nTaskListener then
		StopListeningToGameEvent( self.nTaskListener )
		self.nTaskListener = nil
	end

	self.nTaskListener = ListenToGameEvent( "trigger_start_touch", Dynamic_Wrap( CDotaNPXScenario_InitiationTeamfight, "OnTriggerStartTouch" ), self )

	return true
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:DisableWKReincarnation( hSpawner )
	local hUnit = hSpawner:GetSpawnedUnits()[ 1 ]
	if hUnit then
		local rgAbilityNames = {
			"skeleton_king_reincarnation",
			"skeleton_king_vampiric_spirit",
			"skeleton_king_bone_guard",
		}
		for _, szName in pairs( rgAbilityNames ) do
			local hAbility = hUnit:FindAbilityByName( szName )
			if hAbility then
				hAbility:SetLevel( 0 )
				hAbility:SetHidden( true )
				hAbility:SetActivated( false )
			end
		end
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:ResetSpawnedUnit( hSpawner )
	local hUnit = hSpawner:GetSpawnedUnits()[ 1 ]
	if hUnit == nil or hUnit:IsNull() then
		printf( "WARNING: ResetSpawnedUnit - no unit for spawner %s", hSpawner:GetSpawnerName() )
		return
	end

	printf( "ResetSpawnedUnit: %s (alive=%s)", hUnit:GetUnitName(), tostring( hUnit:IsAlive() ) )

	-- Move offmap FIRST to prevent AI from acting during reset
	hUnit:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
	hUnit:Stop()

	-- Respawn if dead (will spawn at current offmap position)
	if not hUnit:IsAlive() then
		hUnit:RespawnHero( false, false )
		hUnit:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
	end

	-- Purge all modifiers
	hUnit:Purge( true, true, false, true, true )
	hUnit:RemoveModifierByName( "modifier_invulnerable" )
	-- BKB immunity and other unpurgeable modifiers need explicit removal
	hUnit:RemoveModifierByName( "modifier_black_king_bar_immune" )
	hUnit:RemoveModifierByName( "modifier_item_black_king_bar" )
	hUnit:RemoveModifierByName( "modifier_disable_healing" )

	-- Reset mana and ability cooldowns
	hUnit:SetMana( hUnit:GetMaxMana() )
	for i = 0, hUnit:GetAbilityCount() - 1 do
		local hAbility = hUnit:GetAbilityByIndex( i )
		if hAbility then
			hAbility:EndCooldown()
		end
	end

	-- Strip all items and re-give fresh copies (resets BKB charges, etc.)
	for i = DOTA_ITEM_SLOT_1, 16 do
		local hItem = hUnit:GetItemInSlot( i )
		if hItem then
			hUnit:RemoveItem( hItem )
		end
	end
	local rgUnitInfo = hSpawner.rgUnitsInfo[ 1 ]
	if rgUnitInfo and rgUnitInfo.BotPlayer and rgUnitInfo.BotPlayer.StartingItems then
		for _, szItemName in pairs( rgUnitInfo.BotPlayer.StartingItems ) do
			hUnit:AddItemByName( szItemName )
		end
	end

	-- Save the spawn entity position for RevealSpawnedUnit to use later
	local rgSpawners = Entities:FindAllByName( hSpawner:GetSpawnerName() )
	if rgSpawners[ 1 ] then
		hUnit.vSpawnOrigin = rgSpawners[ 1 ]:GetAbsOrigin()
	end

	-- Leave frozen: invulnerable + offmap + flag
	hUnit:AddNewModifier( nil, nil, "modifier_invulnerable", {} )
	hUnit.bFrozen = true
	hUnit:RemoveNoDraw()

	-- Signal the AI entity script to reset its state machine.
	-- Each AI BotThink checks this flag and re-runs initialization
	-- (clears bWasKilled, resets nBotState to IDLE, sets starting HP).
	hUnit.bScenarioReset = true
end

--------------------------------------------------------------------------------

-- FreezeSpawnedUnit and RevealSpawnedUnit are inherited from CDotaNPXScenario

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:SetupTasks()
	if not CDotaNPXScenario.SetupTasks( self ) then
		return false
	end
	if self.Tasks == nil then
		self.Tasks = {}
	end

	local rootTask = CDotaNPXTask_Sequence( {
		TaskName = "root",
		Hidden = true,
	}, self )
	table.insert( self.Tasks, rootTask )
	rootTask.CheckTaskStart = function() return true end

	local szInitialPlayerMoveLoc = "initial_player_move_loc"
	self.hInitialPlayerMoveLoc = Entities:FindByName( nil, szInitialPlayerMoveLoc )
	ScriptAssert( self.hInitialPlayerMoveLoc ~= nil, "Could not find entity named %s!", szInitialPlayerMoveLoc )

	local GoIntoTrees = rootTask:AddTask( CDotaNPXTask_MoveToLocation( {
		TaskName = "go_into_trees",
		TaskType = "task_move_to_location",
		UseHints = true,
		TaskParams =
		{
			GoalLocation = self.hInitialPlayerMoveLoc:GetAbsOrigin(),
			GoalDistance = 64,
		},
		CheckTaskStart = 
		function() 
			return true
		end,
	}, self ), 1.5 )

	local WinTeamfight = rootTask:AddTask( CDotaNPXTask_Parallel( {
		TaskName = "win_teamfight",
		CheckTaskStart =
		function() 
			return GameRules.DotaNPX:IsTaskComplete( "go_into_trees" )
		end,
	}, self ), 0.5 )

	local RavageEnemies = WinTeamfight:AddTask( CDotaNPXTask_KillUnits( {
		TaskName = "ravage_and_kill_enemies",
		TaskType = "task_kill_units",
		Hidden = true,
		TaskParams =
		{
		},
		UseHints = true,
	}, self ), 1.5 )

	self.ProtectAllies = WinTeamfight:AddTask( CDotaNPXTask_ProtectUnits( {
		TaskName = "protect_allies",
		Hidden = true,
		TaskParams =
		{
			FailureString = "initiation_teamfight_failure_protect_units",
		},
	}, self ), 1.5 )

	local szP2PlayerMoveLoc = "p2_player_move_loc"
	local hP2PlayerMoveLoc = Entities:FindByName( nil, szP2PlayerMoveLoc )
	ScriptAssert( hP2PlayerMoveLoc ~= nil, "Could not find entity named %s!", szP2PlayerMoveLoc )

	local MoveToP2Loc = rootTask:AddTask( CDotaNPXTask_MoveToLocation( {
		TaskName = "move_to_p2_loc",
		TaskType = "task_move_to_location",
		UseHints = true,
		TaskParams =
		{
			GoalLocation = hP2PlayerMoveLoc:GetAbsOrigin(),
			GoalDistance = 64,
		},
		CheckTaskStart =
		function() 
			return GameRules.DotaNPX:IsTaskComplete( "win_teamfight" )
		end,
	}, self ), 2.0 )

	local WinSecondTeamfight = rootTask:AddTask( CDotaNPXTask_Parallel( {
		TaskName = "win_second_teamfight",
		CheckTaskStart =
		function() 
			return GameRules.DotaNPX:IsTaskComplete( "move_to_p2_loc" )
		end,
	}, self ), 0.5 )

	local EnterSecondTeamfightTrigger = WinSecondTeamfight:AddTask( CDotaNPXTask_MoveToTrigger( {
		TaskName = "enter_second_teamfight_trigger",
		TaskType = "task_move_to_trigger",
		Hidden = true,
		TaskParams =
		{
			TriggerName = "part_two_detect_player_movement",
		},
		UseHints = false,
		CheckTaskStart =
		function() 
			return GameRules.DotaNPX:IsTaskComplete( "move_to_p2_loc" )
		end,
	}, self ), 2.0 )

	local BlinkRavageEnemies = WinSecondTeamfight:AddTask( CDotaNPXTask_KillUnits( {
		TaskName = "blink_ravage_enemies",
		TaskType = "task_kill_units",
		Hidden = true,
		TaskParams =
		{				
		},
		CheckTaskStart =
		function() 
			return GameRules.DotaNPX:IsTaskComplete( "move_to_p2_loc" )
		end,
	}, self ), 2.0 )

	local ProtectAlliesP2 = WinSecondTeamfight:AddTask( CDotaNPXTask_ProtectUnits( {
		TaskName = "protect_allies_p2",
		Hidden = true,
		TaskParams =
		{
			FailureString = "initiation_teamfight_failure_protect_units",
		},
		CheckTaskStart =
		function() 
			return GameRules.DotaNPX:IsTaskComplete( "move_to_p2_loc" )
		end,
	}, self ), 2.0 )

	return true
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:OnTaskStarted( event )
	CDotaNPXScenario.OnTaskStarted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	--[[
	-- @note: I think checkpoint_skip needs to be hooked to TaskStarted for this to do anything
	if event.checkpoint_skip == 1 then
		printf( "OnTaskTarted - Checkpoint Skipping past the task completed logic for \"%s\"", Task:GetTaskName() )

		return
	end
	]]
	
	if Task:GetTaskName() == "go_into_trees" then
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 2.0, function()
			self:ShowWizardTip( "initiation_teamfight_tip_ravage_primer", 5.0 )
		end )
	end

	if Task:GetTaskName() == "win_teamfight" then
		self:ShowWizardTip( "initiation_teamfight_tip_queenofpain_combo", 4.0 )
	end

	if Task:GetTaskName() == "move_to_p2_loc" then
		self:ShowWizardTip( "initiation_teamfight_tip_blink_gained", 6.0 )
	end

	if Task:GetTaskName() == "win_second_teamfight" then
		self:ShowWizardTip( "initiation_teamfight_tip_enigma_bkb", 6.0 )
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:OnTaskCompleted( event )
	CDotaNPXScenario.OnTaskCompleted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	if Task:GetTaskName() == "move_to_p2_loc" then
		self.nCheckpoint = 1
		self.bP2Active = true

		-- Reveal Phase 2 heroes (spawned and frozen during SetupScenario)
		self:RevealSpawnedUnit( self.hLionP2Spawner )
		self:RevealSpawnedUnit( self.hDragonKnightP2Spawner )
		self:RevealSpawnedUnit( self.hWraithKingP2Spawner )
		self:RevealSpawnedUnit( self.hSniperP2Spawner )
		self:RevealSpawnedUnit( self.hEnigmaP2Spawner )

		-- Set up kill targets for P2 enemies
		local hKillTask = self:GetTask( "blink_ravage_enemies" )

		local hWKP2 = self.hWraithKingP2Spawner:GetSpawnedUnits()[ 1 ]
		if hWKP2 then
			hWKP2:AddNewModifier( hWKP2, nil, "modifier_disable_healing", { duration = -1 } )
			if hKillTask then hKillTask:AddUnitsToKill( { hWKP2 } ) end
		end

		local hEnigma = self.hEnigmaP2Spawner:GetSpawnedUnits()[ 1 ]
		if hEnigma then
			hEnigma:AddNewModifier( hEnigma, nil, "modifier_disable_healing", { duration = -1 } )
			if hKillTask then hKillTask:AddUnitsToKill( { hEnigma } ) end
		end

		local hSniperP2 = self.hSniperP2Spawner:GetSpawnedUnits()[ 1 ]
		if hSniperP2 then
			hSniperP2:AddNewModifier( hSniperP2, nil, "modifier_disable_healing", { duration = -1 } )
			if hKillTask then hKillTask:AddUnitsToKill( { hSniperP2 } ) end
		end

		-- Set up protect targets for P2 allies
		local hProtectTask = self:GetTask( "protect_allies_p2" )

		local hDK = self.hDragonKnightP2Spawner:GetSpawnedUnits()[ 1 ]
		if hDK and hProtectTask then
			hProtectTask:AddUnitsToProtect( { hDK } )
		end

		local hLion = self.hLionP2Spawner:GetSpawnedUnits()[ 1 ]
		if hLion and hProtectTask then
			hProtectTask:AddUnitsToProtect( { hLion } )
		end
	elseif Task:GetTaskName() == "blink_ravage_enemies" then
		printf( "Completed task blink_ravage_enemies" )
		local hWinSecondTeamfightTask = GameRules.DotaNPX:GetTask( "win_second_teamfight" )
		if hWinSecondTeamfightTask ~= nil and hWinSecondTeamfightTask:IsCompleted() == false then
			hWinSecondTeamfightTask:CompleteTask( true )
		end
	elseif Task:GetTaskName() == "win_second_teamfight" then
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 2.0, function()
			self:OnScenarioComplete( true )
		end )
	end

	if event.checkpoint_skip == 1 then
		printf( "Checkpoint Skipping past the task completed logic for \"%s\"", Task:GetTaskName() )

		-- If Tidehunter doesn't have a blink (because it's given out when completing a task that's prior to the checkpoint), then give it to him
		local hBlink = self:FindItemByName( self.hPlayerHero, "item_blink" )
		if hBlink == nil then
			local blink = CreateItem( "item_blink", self.hPlayerHero, self.hPlayerHero )
			blink:SetPurchaseTime( 0 )
			blink:SetPurchaser( self.hPlayerHero )
			self.hPlayerHero:AddItem( blink )

			RefreshHero( self.hPlayerHero )
		end

		return
	end

	if Task:GetTaskName() == "go_into_trees" then
		self.hPlayerHero:RemoveModifierByName( "modifier_disable_healing" )

		local hQueenOfPain = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
		if hQueenOfPain then
			hQueenOfPain:RemoveModifierByName( "modifier_disable_healing" )
		end

		-- Reveal Phase 1 enemies (spawned and frozen during SetupScenario)
		self:RevealSpawnedUnit( self.hWraithKingSpawner )
		self:RevealSpawnedUnit( self.hSniperSpawner )

		-- Add units to the kill task
		local hKillTask = self:GetTask( "ravage_and_kill_enemies" )
		local hWK = self.hWraithKingSpawner:GetSpawnedUnits()[ 1 ]
		local hSniper = self.hSniperSpawner:GetSpawnedUnits()[ 1 ]
		if hKillTask then
			if hWK then hKillTask:AddUnitsToKill( { hWK } ) end
			if hSniper then hKillTask:AddUnitsToKill( { hSniper } ) end
		end
	elseif Task:GetTaskName() == "win_teamfight" then
		-- Give Tidehunter a blink dagger
		local blink = CreateItem( "item_blink", self.hPlayerHero, self.hPlayerHero )
		blink:SetPurchaseTime( 0 )
		blink:SetPurchaser( self.hPlayerHero )
		self.hPlayerHero:AddItem( blink )

		RefreshHero( self.hPlayerHero )
	elseif Task:GetTaskName() == "ravage_and_kill_enemies" then
		-- If QoP and the tower are still alive, then that task is completed successfully
		local hQueenOfPain = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
		ScriptAssert( hQueenOfPain ~= nil, "Queen of Pain is nil" )
		ScriptAssert( self.hRadiantMidTower ~= nil, "Radiant mid tower is nil" )

		if hQueenOfPain ~= nil and hQueenOfPain:IsAlive() and self.hRadiantMidTower ~= nil and self.hRadiantMidTower:IsAlive() then
			local hProtectAlliesTask = GameRules.DotaNPX:GetTask( "protect_allies" )
			if hProtectAlliesTask ~= nil and hProtectAlliesTask:IsCompleted() == false then
				hProtectAlliesTask:CompleteTask( true )
			end
		end

		--Task:GetScenario():ScheduleFunctionAtGameTime( GameRules:GetGameTime() + 2.0, function()
		self:ScheduleFunctionAtGameTime( GameRules:GetGameTime() + 2.0, function()
			-- Hide P1 heroes (freeze offmap instead of destroying,
			-- so they can be reused on restart)
			self:FreezeSpawnedUnit( self.hQueenOfPainSpawner )
			self:FreezeSpawnedUnit( self.hWraithKingSpawner )
			self:FreezeSpawnedUnit( self.hSniperSpawner )
		end )
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:OnTriggerStartTouch( event )
	printf( "CDotaNPXScenario_InitiationTeamfight:OnTriggerStartTouch" )

	local szPartTwoEarlyDetectTrigger = "p2_early_player_movement_detection_trigger"
	if self.hPlayerHero and event.trigger_name == szPartTwoEarlyDetectTrigger and event.activator_entindex == self.hPlayerHero:GetEntityIndex() then
		printf( "Player hero walked into trigger named %s", szPartTwoEarlyDetectTrigger )
		self.bPartTwoEarlyTriggerActivated = true
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:OnSetupComplete()
	CDotaNPXScenario.OnSetupComplete( self )

	self.hPlayerHero = PlayerResource:GetSelectedHeroEntity( 0 )
	self.hPlayerHero:SetAbilityPoints( 0 )

	if self.nCheckpoint == 0 then
		-- Tidehunter starts with disable_healing (removed when go_into_trees completes).
		-- On first play this is set in OnNPCSpawned; on restart we must re-add it
		-- since Purge clears all modifiers.
		self.hPlayerHero:AddNewModifier( self.hPlayerHero, nil, "modifier_disable_healing", { duration = -1 } )

		-- Set up ProtectAllies now that the player hero exists
		if self.ProtectAllies and self.ProtectAllies.hUnitsToProtect == nil then
			local hQueenOfPain = self.hQueenOfPainSpawner:GetSpawnedUnits()[ 1 ]
			if hQueenOfPain then
				self.ProtectAllies.hUnitsToProtect = {}
				table.insert( self.ProtectAllies.hUnitsToProtect, hQueenOfPain )
				table.insert( self.ProtectAllies.hUnitsToProtect, self.hPlayerHero )
				table.insert( self.ProtectAllies.hUnitsToProtect, self.hRadiantMidTower )
				self.ProtectAllies:SetUnitsToProtect( self.ProtectAllies.hUnitsToProtect )
			end
		end
	elseif self.nCheckpoint == 1 then
		printf( "CHECKPOINT 1" )
		local bForceStart = true
		self:CheckpointSkipCompleteTask( "go_into_trees", true, bForceStart )
		self:CheckpointSkipCompleteTask( "win_teamfight", true )
		self:CheckpointSkipCompleteTask( "ravage_and_kill_enemies", true )
		self:CheckpointSkipCompleteTask( "protect_allies", true )

		self.bPartTwoEarlyTriggerActivated = false

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

function CDotaNPXScenario_InitiationTeamfight:OnSpawnerFinished( event )
	CDotaNPXScenario.OnSpawnerFinished( self, event )

	printf( "OnSpawnerFinished - event.spawner_name == %s", event.spawner_name )

	-- Look up spawner from rgSpawners by name.  This works because
	-- AddSpawner() runs BEFORE SpawnUnits() in the CDotaSpawner constructor,
	-- so the spawner is already registered even though the assignment like
	-- "self.hQueenOfPainSpawner = CDotaSpawner(...)" hasn't returned yet.
	local hSpawner = self:GetSpawner( event.spawner_name )
	if hSpawner == nil then
		printf( "WARNING: OnSpawnerFinished - could not find spawner '%s'", event.spawner_name )
		return
	end

	-- Assign named handles for later use by tasks/reveal/restart code.
	if event.spawner_name == "queenofpain_spawner" then
		self.hQueenOfPainSpawner = hSpawner
		local hQueenOfPain = hSpawner:GetSpawnedUnits()[ 1 ]
		if hQueenOfPain then
			if self.nCheckpoint == 0 then
				hQueenOfPain:AddNewModifier( hQueenOfPain, nil, "modifier_disable_healing", { duration = -1 } )
			elseif self.nCheckpoint == 1 then
				self:FreezeSpawnedUnit( hSpawner )
			end
		end
	elseif event.spawner_name == "wraith_king_spawner" then
		self.hWraithKingSpawner = hSpawner
		self:DisableWKReincarnation( hSpawner )
		self:FreezeSpawnedUnit( hSpawner )
	elseif event.spawner_name == "sniper_spawner" then
		self.hSniperSpawner = hSpawner
		self:FreezeSpawnedUnit( hSpawner )
	elseif event.spawner_name == "p2_lion_spawner" then
		self.hLionP2Spawner = hSpawner
		if not self.bP2Active then
			self:FreezeSpawnedUnit( hSpawner )
		end
	elseif event.spawner_name == "p2_dragon_knight_spawner" then
		self.hDragonKnightP2Spawner = hSpawner
		if not self.bP2Active then
			self:FreezeSpawnedUnit( hSpawner )
		end
	elseif event.spawner_name == "p2_wraith_king_spawner" then
		self.hWraithKingP2Spawner = hSpawner
		self:DisableWKReincarnation( hSpawner )
		if not self.bP2Active then
			self:FreezeSpawnedUnit( hSpawner )
		end
	elseif event.spawner_name == "p2_sniper_spawner" then
		self.hSniperP2Spawner = hSpawner
		if not self.bP2Active then
			self:FreezeSpawnedUnit( hSpawner )
		end
	elseif event.spawner_name == "p2_enigma_spawner" then
		self.hEnigmaP2Spawner = hSpawner
		if not self.bP2Active then
			self:FreezeSpawnedUnit( hSpawner )
		end
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:OnNPCSpawned( hEnt )
	-- BUG FIX: was incorrectly calling CDotaNPXScenario:OnEntityKilled (copy-paste error).
	-- That called EndHintNPC and the announcer with a live entity as the victim,
	-- and skipped the base class NPC tracking, breaking the spawner flow.
	CDotaNPXScenario.OnNPCSpawned( self, hEnt )

	if hEnt ~= nil and hEnt:IsNull() == false and hEnt:GetUnitName() == "npc_dota_hero_tidehunter" then
		hEnt:SetHealth( hEnt:GetMaxHealth() * 0.6 )
		hEnt:AddNewModifier( hEnt, nil, "modifier_disable_healing", { duration = -1 } )
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:OnEntityKilled( hEnt )
	CDotaNPXScenario.OnEntityKilled( self, hEnt )	

	if hEnt and ( hEnt:GetUnitName() == "npc_dota_hero_queenofpain" or hEnt:GetUnitName() == "dota_goodguys_tower1_mid" ) then
		local hProtectAlliesTask = GameRules.DotaNPX:GetTask( "protect_allies" )
		if hProtectAlliesTask ~= nil and hProtectAlliesTask:IsCompleted() == false then
			hProtectAlliesTask:CompleteTask( false )
		end
	end

	if hEnt and hEnt == self.hPlayerHero then
		local hProtectAlliesP2Task = GameRules.DotaNPX:GetTask( "protect_allies_p2" )
		if hProtectAlliesP2Task ~= nil and hProtectAlliesP2Task:IsCompleted() == false then
			hProtectAlliesP2Task:CompleteTask( false )
		end
	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:GainLevels( hUnit, nLevels )
	local nCurrentXPTotal = GetXPNeededToReachNextLevel( hUnit:GetLevel() )
	local nXPToLevel = GetXPNeededToReachNextLevel( hUnit:GetLevel() + nLevels ) - nCurrentXPTotal
	hUnit:AddExperience( nXPToLevel, DOTA_ModifyXP_Unspecified, false, true )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_InitiationTeamfight:FindItemByName( hUnit, strItemName )
	for iSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_MAX do
		local hItem = hUnit:GetItemInSlot( iSlot )
		if hItem and hItem:GetAbilityName() == strItemName then
			return hItem
		end
	end
end

--------------------------------------------------------------------------------

return CDotaNPXScenario_InitiationTeamfight
