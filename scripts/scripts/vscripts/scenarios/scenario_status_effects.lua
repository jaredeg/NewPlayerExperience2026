
require( "npx_scenario" )
require( "tasks/task_sequence" )
require( "tasks/task_parallel" )
require( "tasks/task_modifier_removed_from_enemy" )
require( "tasks/task_kill_units" )


--------------------------------------------------------------------------------

if CDotaNPXScenario_Status_Effects == nil then
	CDotaNPXScenario_Status_Effects = class( {}, {}, CDotaNPXScenario )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:InitScenarioKeys()
	
	self.hInitialPlayerMoveLoc = Entities:FindByName( nil, "initial_player_move_loc" )
	ScriptAssert( self.hInitialPlayerMoveLoc ~= nil, "Could not find entity named initial_player_move_loc!" )

	self.hScenario =
	{
		DaynightCycleDisabled = true,
		bLetGoldThrough		= false,
		bLetXPThrough		= false,
		PreGameTime 		= 0.0,
		HeroSelectionTime 	= 0.0,
		StrategyTime 		= 0.0,
		ForceHero 			= "npc_dota_hero_ogre_magi",
		StartingHeroLevel	= 1,
		Team 				= DOTA_TEAM_GOODGUYS,
		StartingGold		= 0,

		StartingItems 		=
		{
		
		},
		StartingAbilities =
		{

		},
		
		ScenarioTimeLimit = 0.0,


		Tasks = 
		{
			{
				TaskName = "move_to_location_1",
				TaskType = "task_move_to_location",
				UseHints = true,
				TaskParams =
				{
					GoalLocation = self.hInitialPlayerMoveLoc:GetAbsOrigin(),
					GoalDistance = 64,
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
			--[[
			{
				TaskName = "stun_enemy_hero",
				TaskType = "task_modifier_removed_from_enemy",
				UseHints = true,
				TaskParams =
				{
					AbilityName = "modifier_bashed",
					TimesToComplete = 1,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_1" )
				end,
			},
			]]
			{
				TaskName = "stun_enemy_hero",
				TaskType = "task_kill_units",
				--Hidden = true,
				TaskParams = 
				{
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_1" )
				end,
			},

			{
				TaskName = "move_to_location_2",
				TaskType = "task_move_to_location",
				UseHints = true,
				TaskParams =
				{
					GoalLocation = self.hInitialPlayerMoveLoc:GetAbsOrigin(),
					GoalDistance = 64,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "stun_enemy_hero" )
				end,
			},
--[[
			{
				TaskName = "silence_enemy_hero",
				TaskType = "task_modifier_removed_from_enemy",
				UseHints = true,
				TaskParams =
				{
					AbilityName = "modifier_orchid_malevolence_debuff",
					TimesToComplete = 1,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_2" )
				end,
			},
]]
			{
				TaskName = "silence_enemy_hero",
				TaskType = "task_kill_units",
				--Hidden = true,
				TaskParams = 
				{
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_2" )
				end,
			},


			{
				TaskName = "move_to_location_3",
				TaskType = "task_move_to_location",
				UseHints = true,
				TaskParams =
				{
					GoalLocation = self.hInitialPlayerMoveLoc:GetAbsOrigin(),
					GoalDistance = 64,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "silence_enemy_hero" )
				end,
			},
--[[			
			{
				TaskName = "root_enemy_hero",
				TaskType = "task_modifier_removed_from_enemy",
				UseHints = true,
				TaskParams =
				{
					AbilityName = "modifier_rod_of_atos_debuff",
					TimesToComplete = 1,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_3" )
				end,
			},
]]

			{
				TaskName = "root_enemy_hero",
				TaskType = "task_kill_units",
				--Hidden = true,
				TaskParams = 
				{
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_3" )
				end,
			},

			{
				TaskName = "move_to_location_4",
				TaskType = "task_move_to_location",
				UseHints = true,
				TaskParams =
				{
					GoalLocation = self.hInitialPlayerMoveLoc:GetAbsOrigin(),
					GoalDistance = 64,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "root_enemy_hero" )
				end,
			},

			{
				TaskName = "disarm_enemy_hero",
				TaskType = "task_kill_units",
				--Hidden = true,
				TaskParams = 
				{
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_4" )
				end,
			},
			--[[
			{
				TaskName = "disarm_enemy_hero",
				TaskType = "task_modifier_removed_from_enemy",
				UseHints = true,
				TaskParams =
				{
					AbilityName = "modifier_heavens_halberd_debuff",
					TimesToComplete = 1,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_4" )
				end,
			},
			]]
--[[
			{
				TaskName = "break_enemy_hero",
				TaskType = "task_modifier_removed_from_enemy",
				UseHints = true,
				TaskParams =
				{
					AbilityName = "modifier_silver_edge_debuff",
					TimesToComplete = 1,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "disarm_enemy_hero" )
				end,
			}, 
]]--
		},

		Queries =
		{
		},
	}
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:SetupScenario()
	if not CDotaNPXScenario.SetupScenario( self ) then
		return false
	end

	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_HEROES, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_QUICK_STATS, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_KILLCAM, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_BAR, false )

	-- Pre-spawn ALL bot heroes so models load with valid precache context.
	-- OnSpawnerFinished freezes each one offmap; OnTaskCompleted reveals pairs.
	-- On restart, existing spawners persist — skip re-creation.

	-- Phase 1: Shadow Shaman (enemy) + Lina (ally)
	if not self.hShamanSpawner then
		CDotaSpawner( "enemy_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_shadow_shaman",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Shadow Shaman",
					EntityScript = "ai/status_effects/ai_status_effects_shadow_shaman.lua",
					StartingHeroLevel = 5,
					StartingItems = { "item_boots" },
					StartingAbilities = { "shadow_shaman_shackles", "shadow_shaman_voodoo" },
					AbilityBuild = { AbilityPriority = { "shadow_shaman_shackles" } },
				},
			},
		}, self, true )
	end

	if not self.hLinaSpawner then
		CDotaSpawner( "ally_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_lina",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Lina",
					EntityScript = "ai/status_effects/ai_status_effects_lina",
					StartingHeroLevel = 14,
					StartingItems = { "item_boots", "item_ultimate_scepter" },
					StartingAbilities = { "lina_light_strike_array", "lina_dragon_slave", "lina_laguna_blade" },
					AbilityBuild = { AbilityPriority = { "lina_laguna_blade" } },
				},
			},
		}, self, true )
	end

	-- Phase 2: Tinker (enemy) + Drow Ranger (ally)
	if not self.hTinkerSpawner then
		CDotaSpawner( "enemy_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_tinker",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Tinker",
					EntityScript = "ai/status_effects/ai_status_effects_tinker.lua",
					StartingHeroLevel = 12,
					StartingItems = { "item_travel_boots", "item_kaya" },
					StartingAbilities = { "tinker_laser", "tinker_rearm" },
					AbilityBuild = { AbilityPriority = { "tinker_laser" } },
				},
			},
		}, self, true )
	end

	if not self.hDrowSpawner then
		CDotaSpawner( "ally_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_drow_ranger",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Drow Ranger",
					EntityScript = "ai/status_effects/ai_status_effects_drow",
					StartingHeroLevel = 14,
					StartingItems = { "item_power_treads", "item_butterfly", "item_greater_crit", "item_heart" },
					StartingAbilities = { "drow_ranger_frost_arrows" },
					AbilityBuild = { AbilityPriority = { "drow_ranger_frost_arrows" } },
				},
			},
		}, self, true )
	end

	-- Phase 3: Dark Seer (enemy) + Sven (ally)
	if not self.hDarkSeerSpawner then
		CDotaSpawner( "enemy_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_dark_seer",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Dark Seer",
					EntityScript = "ai/status_effects/ai_status_effects_dark_seer.lua",
					StartingHeroLevel = 6,
					StartingItems = { "item_boots", "item_hood_of_defiance" },
					StartingAbilities = { "dark_seer_surge" },
					AbilityBuild = { AbilityPriority = { "dark_seer_surge" } },
				},
			},
		}, self, true )
	end

	if not self.hSvenSpawner then
		CDotaSpawner( "ally_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_sven",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Sven",
					EntityScript = "ai/status_effects/ai_status_effects_sven",
					StartingHeroLevel = 14,
					StartingItems = { "item_boots", "item_sange", "item_heart" },
					StartingAbilities = {},
					AbilityBuild = {},
				},
			},
		}, self, true )
	end

	-- Phase 4: Troll Warlord (enemy) + Storm Spirit (ally)
	if not self.hTrollSpawner then
		CDotaSpawner( "enemy_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_troll_warlord",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Troll Warlord",
					EntityScript = "ai/status_effects/ai_status_effects_troll.lua",
					StartingHeroLevel = 5,
					StartingItems = { "item_boots", "item_basher", "item_moon_shard" },
					StartingAbilities = { "troll_warlord_fervor", "troll_warlord_berserkers_rage" },
					AbilityBuild = { AbilityPriority = { "troll_warlord_fervor" } },
				},
			},
		}, self, true )
	end

	if not self.hStormSpawner then
		CDotaSpawner( "ally_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_storm_spirit",
				Team = DOTA_TEAM_GOODGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Storm Spirit",
					EntityScript = "ai/status_effects/ai_status_effects_storm_spirit",
					StartingHeroLevel = 14,
					StartingItems = { "item_power_treads", "item_yasha_and_kaya", "item_bloodstone" },
					StartingAbilities = { "storm_spirit_electric_vortex", "storm_spirit_overload", "storm_spirit_static_remnant", "storm_spirit_ball_lightning" },
					AbilityBuild = {},
				},
			},
		}, self, true )
	end

	self.nTaskListener = ListenToGameEvent( "trigger_start_touch", Dynamic_Wrap( CDotaNPXScenario_Status_Effects, "OnTriggerStartTouch" ), self)
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnSpawnerFinished( event )
	CDotaNPXScenario.OnSpawnerFinished( self, event )

	-- Multiple spawners share "enemy_spawn_location" / "ally_spawn_location".
	-- Identify by unit name and freeze any that aren't frozen yet.
	for _, spawner in pairs( self.rgSpawners ) do
		local hUnit = spawner:GetSpawnedUnits()[ 1 ]
		if hUnit and not hUnit.bFrozen then
			local szName = hUnit:GetUnitName()
			local szField = nil

			if szName == "npc_dota_hero_shadow_shaman" then szField = "hShamanSpawner"
			elseif szName == "npc_dota_hero_lina" then szField = "hLinaSpawner"
			elseif szName == "npc_dota_hero_tinker" then szField = "hTinkerSpawner"
			elseif szName == "npc_dota_hero_drow_ranger" then szField = "hDrowSpawner"
			elseif szName == "npc_dota_hero_dark_seer" then szField = "hDarkSeerSpawner"
			elseif szName == "npc_dota_hero_sven" then szField = "hSvenSpawner"
			elseif szName == "npc_dota_hero_troll_warlord" then szField = "hTrollSpawner"
			elseif szName == "npc_dota_hero_storm_spirit" then szField = "hStormSpawner"
			end

			if szField then
				printf( "Freezing pre-spawned %s", szName )
				self[ szField ] = spawner
				self:FreezeSpawnedUnit( spawner )
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Helper: reveal a spawner and return the unit handle.
--------------------------------------------------------------------------------
function CDotaNPXScenario_Status_Effects:RevealBot( hSpawner )
	if hSpawner then
		self:RevealSpawnedUnit( hSpawner )
		return hSpawner:GetSpawnedUnits()[ 1 ]
	end
	return nil
end

--------------------------------------------------------------------------------
-- Helper: re-freeze a bot for restart reuse.
--------------------------------------------------------------------------------
function CDotaNPXScenario_Status_Effects:RefreezeBot( hSpawner, szSpawnEntity )
	if not hSpawner then return end
	local hUnit = hSpawner:GetSpawnedUnits()[ 1 ]
	if not hUnit or hUnit:IsNull() then return end

	-- Reset spawn origin from map entity
	local hEnt = Entities:FindByName( nil, szSpawnEntity )
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
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnTriggerStartTouch( event )
	printf( "OnTriggerStartTouch" )

	local hPlayerHero = PlayerResource:GetSelectedHeroEntity( 0 )
	if hPlayerHero and event.trigger_name == "start_trigger" and event.activator_entindex == hPlayerHero:GetEntityIndex() then

	end
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnSetupComplete()
	CDotaNPXScenario.OnSetupComplete( self )

	self.hPlayerHero = PlayerResource:GetSelectedHeroEntity( 0 )

	self.hPlayerHero:SetAbilityPoints( 0 )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnTaskCompleted( event )
	CDotaNPXScenario.OnTaskCompleted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	if Task:GetTaskName() == "move_to_location_1" then
		self:GetPlayerHero():AddItemByName("item_abyssal_blade")

		-- Reveal phase 1 pair
		local hShaman = self:RevealBot( self.hShamanSpawner )
		self:RevealBot( self.hLinaSpawner )

		-- Disable Shadow Shaman's innate ability (Fowl Play)
		if hShaman then
			local hInnate = hShaman:FindAbilityByName( "shadow_shaman_fowl_play" )
			if hInnate then
				hShaman:RemoveAbility( "shadow_shaman_fowl_play" )
				printf( "Removed Shadow Shaman innate: shadow_shaman_fowl_play" )
			else
				print( "WARNING: shadow_shaman_fowl_play not found - trying alternate names" )
				local rgAlternateNames = { "shadow_shaman_chicken", "shadow_shaman_innate" }
				for _, szName in ipairs( rgAlternateNames ) do
					local hAlt = hShaman:FindAbilityByName( szName )
					if hAlt then
						hShaman:RemoveAbility( szName )
						printf( "Removed Shadow Shaman innate via alternate name: %s", szName )
						break
					end
				end
			end
			-- Also purge any existing fowl play modifier in case it already proc'd
			hShaman:RemoveModifierByName( "modifier_shadow_shaman_fowl_play" )
			hShaman:RemoveModifierByName( "modifier_shadow_shaman_fowl_play_chicken" )
		end

		if hShaman then
			local killTask = self:GetTask( "stun_enemy_hero" )
			if killTask then killTask:SetUnitsToKill( { hShaman } ) end
		end

	elseif Task:GetTaskName() == "stun_enemy_hero" then
		-- Clean up phase 1 — re-freeze offmap (don't Remove, it crashes the think loop)
		self:RefreezeBot( self.hShamanSpawner, "enemy_spawn_location" )
		self:RefreezeBot( self.hLinaSpawner, "ally_spawn_location" )

	elseif Task:GetTaskName() == "move_to_location_2" then
		local hAbyssalBlade = self:GetPlayerHero():FindItemInInventory("item_abyssal_blade")
		if hAbyssalBlade ~= nil then
			self:GetPlayerHero():RemoveItem(hAbyssalBlade)
		end
		self:GetPlayerHero():AddItemByName("item_orchid")

		-- Reveal phase 2 pair
		local hTinker = self:RevealBot( self.hTinkerSpawner )
		self:RevealBot( self.hDrowSpawner )

		if hTinker then
			local killTask = self:GetTask( "silence_enemy_hero" )
			if killTask then killTask:SetUnitsToKill( { hTinker } ) end
		end

	elseif Task:GetTaskName() == "silence_enemy_hero" then
		-- Clean up phase 2
		self:RefreezeBot( self.hTinkerSpawner, "enemy_spawn_location" )
		self:RefreezeBot( self.hDrowSpawner, "ally_spawn_location" )

	elseif Task:GetTaskName() == "move_to_location_3" then
		local hOrchid = self:GetPlayerHero():FindItemInInventory("item_orchid")
		if hOrchid ~= nil then
			self:GetPlayerHero():RemoveItem(hOrchid)
		end
		self:GetPlayerHero():AddItemByName("item_rod_of_atos")

		-- Reveal phase 3 pair
		local hDarkSeer = self:RevealBot( self.hDarkSeerSpawner )
		self:RevealBot( self.hSvenSpawner )

		if hDarkSeer then
			local killTask = self:GetTask( "root_enemy_hero" )
			if killTask then killTask:SetUnitsToKill( { hDarkSeer } ) end
		end

	elseif Task:GetTaskName() == "root_enemy_hero" then
		-- Clean up phase 3
		self:RefreezeBot( self.hDarkSeerSpawner, "enemy_spawn_location" )
		self:RefreezeBot( self.hSvenSpawner, "ally_spawn_location" )

	elseif Task:GetTaskName() == "move_to_location_4" then
		local hRodOfAtos = self:GetPlayerHero():FindItemInInventory("item_rod_of_atos")
		if hRodOfAtos ~= nil then
			self:GetPlayerHero():RemoveItem(hRodOfAtos)
		end
		self:GetPlayerHero():AddItemByName("item_heavens_halberd")

		-- Reveal phase 4 pair
		local hTroll = self:RevealBot( self.hTrollSpawner )
		self:RevealBot( self.hStormSpawner )

		if hTroll then
			local killTask = self:GetTask( "disarm_enemy_hero" )
			if killTask then killTask:SetUnitsToKill( { hTroll } ) end
		end

	elseif Task:GetTaskName() == "disarm_enemy_hero" then
		self:OnScenarioComplete(true)
	end
end	

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:Restart()
	-- Re-freeze all surviving bots before base Restart calls SetupScenario
	self:RefreezeBot( self.hShamanSpawner, "enemy_spawn_location" )
	self:RefreezeBot( self.hLinaSpawner, "ally_spawn_location" )
	self:RefreezeBot( self.hTinkerSpawner, "enemy_spawn_location" )
	self:RefreezeBot( self.hDrowSpawner, "ally_spawn_location" )
	self:RefreezeBot( self.hDarkSeerSpawner, "enemy_spawn_location" )
	self:RefreezeBot( self.hSvenSpawner, "ally_spawn_location" )
	self:RefreezeBot( self.hTrollSpawner, "enemy_spawn_location" )
	self:RefreezeBot( self.hStormSpawner, "ally_spawn_location" )

	CDotaNPXScenario.Restart( self )
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnTaskStarted( event )
	CDotaNPXScenario.OnTaskStarted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end
	
	if Task:GetTaskName() == "move_to_location_1" then
		self:ShowWizardTip( "scenario_status_effects_wizard_tip_intro", 10.0 )
	end
	
	if Task:GetTaskName() == "stun_enemy_hero" then
		self:ShowWizardTip( "scenario_status_effects_wizard_tip_stun_enemy_hero", 10.0 )
	end

	if Task:GetTaskName() == "silence_enemy_hero" then
		self:ShowWizardTip( "scenario_status_effects_wizard_tip_silence_enemy_hero", 10.0 )
	end

	if Task:GetTaskName() == "root_enemy_hero" then
		self:ShowWizardTip( "scenario_status_effects_wizard_tip_root_enemy_hero", 10.0 )
	end

	if Task:GetTaskName() == "disarm_enemy_hero" then
		self:ShowWizardTip( "scenario_status_effects_wizard_tip_disarm_enemy_hero", 10.0 )
	end

end
--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnNPCSpawned( hEnt )
	CDotaNPXScenario.OnNPCSpawned( self, hEnt )	
end

--------------------------------------------------------------------------------

function CDotaNPXScenario_Status_Effects:OnThink()
	CDotaNPXScenario.OnThink( self )
end



return CDotaNPXScenario_Status_Effects
