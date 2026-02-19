require( "npx_scenario" )

--------------------------------------------------------------------

-- FindItemInInventory misses the dedicated TP scroll slot.
-- Iterate all slots (0-19) to reliably find the TP scroll.
local function FindTPScroll( hHero )
	if not hHero or hHero:IsNull() then return nil end
	for i = 0, 19 do
		local hItem = hHero:GetItemInSlot( i )
		if hItem and hItem:GetAbilityName() == "item_tpscroll" then
			return hItem
		end
	end
	return nil
end

--------------------------------------------------------------------

if CDotaNPXScenario_TP_Scroll == nil then
	CDotaNPXScenario_TP_Scroll = class( {}, {}, CDotaNPXScenario )
end

----------------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:PrecacheResources()
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:InitScenarioKeys()
	self.hScenario =
	{
		PreGameTime 			= 0,
		HeroSelectionTime 		= 0.0,
		StrategyTime 			= 0.0,
		DayNightCycleDisabled	= true,
		ScenarioTimeLimit		= 0,
		ForceHero 				= "npc_dota_hero_skeleton_king",
		Team 					= DOTA_TEAM_GOODGUYS,
		StartingHeroLevel		= 5,
		StartingGold			= 1000,
		StartingItems 			=
		{
			"item_power_treads",
			"item_bracer",
		},
		StartingAbilities =
		{
			"skeleton_king_hellfire_blast",
			"skeleton_king_mortal_strike",
			"skeleton_king_hellfire_blast",
			"skeleton_king_mortal_strike",
			"skeleton_king_hellfire_blast",
		},
		Tasks =
		{
			{
				TaskName = "buy_two_tp",
				TaskType = "task_buy_item",
				UseHints = true,
				TaskParams =
				{
					ItemName = "item_tpscroll",
					ItemAmount = 2,
				},
				CheckTaskStart =
				function()
					return true
				end
			},
			{
				TaskName = "teleport_to_tower",
				TaskType = "task_teleport_to_unit",
				UseHints = true,
				TaskParams = { NoFailure = true, NoCameraTakeover = true },
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "buy_two_tp" )
				end,
			},
			{
				TaskName = "stun_tp",
				TaskType = "task_interrupt_ability",
				UseHints = true,
				TaskParams = { AbilityName = "item_tpscroll", FailureReason = "scenario_tp_scroll_task_stun_tp_Failure" },
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "teleport_to_tower" )
				end,
			},
			{
				TaskName = "kill_enemy",
				TaskType = "task_kill_units",
				UseHints = true,
				TaskParams = {},
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "stun_tp" )
				end,
			},
		},

		Queries =
		{
		},
	}

	self.nCheckpoint = 0
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:SetupScenario()
	if not CDotaNPXScenario.SetupScenario( self ) then
		return false
	end

	GameRules:SetHeroRespawnEnabled( false )

	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_HEROES, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_KILLCAM, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_BAR, false )
	GameRules:GetGameModeEntity():SetAnnouncerDisabled( true )
	GameRules:GetGameModeEntity():SetKillingSpreeAnnouncerDisabled( true )
	GameRules:GetGameModeEntity():SetWeatherEffectsDisabled( true )
	
	GameRules:AddItemToWhiteList( "item_tpscroll" )
	GameRules:SetWhiteListEnabled( true )

	Tutorial:StartTutorialMode()
	Tutorial:SetItemGuide( "item_build_tp_scroll" )
	
	for _,hBlocker in pairs ( Entities:FindAllByClassname( "tutorial_npc_blocker" ) ) do
		hBlocker:SetEnabled( true )
	end
	
	for _,hTower in ipairs( Entities:FindAllByClassname( "npc_dota_tower" ) ) do
		if hTower:GetTeam() == DOTA_TEAM_GOODGUYS then
			self.hTower = hTower
			local hTeleportTask = self:GetTask( "teleport_to_tower" )
			if hTeleportTask then
				hTeleportTask:SetTeleportUnit( self.hTower )
			end
			break
		end
	end
	
	-- Clean up any previous listener (from a restart) to avoid duplicates
	if self.hTeleportListener then
		StopListeningToGameEvent( self.hTeleportListener )
		self.hTeleportListener = nil
	end
	self.hTeleportListener = ListenToGameEvent( "dota_hero_teleport_to_unit", Dynamic_Wrap( CDotaNPXScenario_TP_Scroll, "OnTeleportToUnit" ), self )

	self.bDKRevealed = false

	-- Pre-spawn DK frozen; skip creating if spawner already exists (restart reuse)
	printf( "SetupScenario: self.hDKSpawner = %s", tostring( self.hDKSpawner ) )
	if not self.hDKSpawner then
		CDotaSpawner( "enemy_spawn_location",
		{
			{
				EntityName = "npc_dota_hero_dragon_knight",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					BotName = "Dragon Knight",
					EntityScript = "ai/tp_scroll/ai_tp_scroll_dragon_knight.lua",
					StartingHeroLevel = 2,
					StartingItems = 
					{
						"boots",
					},
					AbilityBuild = 
					{
						AbilityPriority = {
							"dragon_knight_dragon_tail",
						},
					},
				},
			},
		}, self, true )
	end

	-- Checkpoint: if player already TP'd successfully, skip buy/TP tasks
	-- and restart from the tower with DK + kobold already active.
	if self.nCheckpoint >= 1 then
		printf( "TP_SCROLL CHECKPOINT 1: skipping buy/TP, starting at tower" )
		local bForceStart = true
		self:CheckpointSkipCompleteTask( "buy_two_tp", true, bForceStart )
		self:CheckpointSkipCompleteTask( "teleport_to_tower", true )

		-- Immediately reveal DK and spawn kobold
		self:RevealDK()

		self.CreepSpawner = CDotaSpawner( "creep_spawn_location",
		{
			{
				EntityName = "npc_dota_neutral_kobold",
				Team = DOTA_TEAM_NEUTRALS,
				Count = 1,
				PositionNoise = 0,
				PostSpawn = function( hUnit )
					hUnit:SetMaxHealth( 4000 )
					hUnit:SetHealth( 4000 )
				end
			},
		}, self, true )

		local hEnemySpawn = Entities:FindByName( nil, "enemy_spawn_location" )
		if hEnemySpawn then
			AddFOWViewer( DOTA_TEAM_GOODGUYS, hEnemySpawn:GetAbsOrigin(), 250, 999, false )
		end
	end

	return true
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:OnSpawnerFinished( event )
	CDotaNPXScenario.OnSpawnerFinished( self, event )

	local hSpawner = self:GetSpawner( event.spawner_name )
	if hSpawner == nil then
		printf( "WARNING: TP_SCROLL OnSpawnerFinished could not find spawner '%s'", event.spawner_name )
		return
	end

	printf( "TP_SCROLL OnSpawnerFinished: spawner_name = %s", tostring( event.spawner_name ) )

	if event.spawner_name == "enemy_spawn_location" then
		self.hDKSpawner = hSpawner
		self:FreezeSpawnedUnit( hSpawner )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:RevealDK()
	if self.bDKRevealed then return end
	self.bDKRevealed = true

	if not self.hDKSpawner then return end
	local hUnit = self.hDKSpawner:GetSpawnedUnits()[ 1 ]
	if not hUnit or hUnit:IsNull() then return end

	-- Use base RevealSpawnedUnit (same as lockdown/status_effects)
	self:RevealSpawnedUnit( self.hDKSpawner )

	-- Give DK a fresh TP scroll (the previous one was consumed)
	local hTP = hUnit:FindItemInInventory( "item_tpscroll" )
	if not hTP then
		hUnit:AddItemByName( "item_tpscroll" )
	end

	-- Reset HP/mana
	hUnit:SetHealth( hUnit:GetMaxHealth() )
	hUnit:SetMana( hUnit:GetMaxMana() )

	-- End all cooldowns
	for i = 0, hUnit:GetAbilityCount() - 1 do
		local hAbility = hUnit:GetAbilityByIndex( i )
		if hAbility then
			hAbility:EndCooldown()
		end
	end

	-- Reset bot state so entity_hurt listener will trigger TP again
	if hUnit.Bot then
		hUnit.Bot.nBotState = 0  -- DK_BOT_STATE_IDLE
		hUnit.Bot.hAttackTarget = nil
		hUnit.Bot.hTownPortalItem = nil  -- forces re-find + EndCooldown
		hUnit.Bot.bHeroHitMe = false
	end

	-- Wire up task targets
	local hStunTask = GameRules.DotaNPX:GetTask( "stun_tp" )
	if hStunTask then
		hStunTask:SetTargetCaster( hUnit )
	end
	local hKillTask = GameRules.DotaNPX:GetTask( "kill_enemy" )
	if hKillTask then
		hKillTask:SetUnitsToKill( { hUnit } )
	end

	self.hEnemyDK = hUnit
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:Restart()
	-- Reuse the DK bot across restarts (never destroy — recreating bot heroes
	-- purges cosmetic model resources and causes ERROR skins / crashes).
	self.bDKRevealed = false

	-- Re-freeze DK: respawn if dead, make invulnerable, hide offmap
	if self.hDKSpawner then
		local hDK = self.hDKSpawner:GetSpawnedUnits()[ 1 ]
		if hDK and not hDK:IsNull() then
			if not hDK:IsAlive() then
				hDK:RespawnHero( false, false )
			end

			-- Re-freeze using same pattern as base FreezeSpawnedUnit
			hDK.bFrozen = true
			if not hDK:HasModifier( "modifier_invulnerable" ) then
				hDK:AddNewModifier( nil, nil, "modifier_invulnerable", {} )
			end
			-- Preserve spawn origin for RevealSpawnedUnit
			local hSpawnEnt = Entities:FindByName( nil, "enemy_spawn_location" )
			if hSpawnEnt then
				hDK.vSpawnOrigin = hSpawnEnt:GetAbsOrigin()
			end
			hDK:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
			hDK:Stop()

			-- Reset bot state
			if hDK.Bot then
				hDK.Bot.nBotState = 0
				hDK.Bot.hAttackTarget = nil
				hDK.Bot.hTownPortalItem = nil
				hDK.Bot.bHeroHitMe = false
			end
		end
	end

	-- Remove kobold creeps from previous attempt
	local hCreeps = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false )
	for _, hCreep in pairs( hCreeps ) do
		if hCreep and not hCreep:IsNull() and hCreep:GetUnitName() == "npc_dota_neutral_kobold" then
			UTIL_Remove( hCreep )
		end
	end

	-- Base Restart handles everything: tear down tasks, SetupScenario,
	-- _ResetPlayerHero (respawn, purge, re-give items, reset cooldowns).
	CDotaNPXScenario.Restart( self )

	local hHeroPost = PlayerResource:GetSelectedHeroEntity( 0 )
	if hHeroPost and not hHeroPost:IsNull() then
		self.hHero = hHeroPost

		-- Checkpoint: move player to the tower (must happen AFTER
		-- _ResetPlayerHero which resets position to spawn point)
		if self.nCheckpoint >= 1 and self.hTower and not self.hTower:IsNull() then
			FindClearSpaceForUnit( hHeroPost, self.hTower:GetAbsOrigin(), true )
			self:CenterCameraOnHero()
		end
	end
end

--------------------------------------------------------------------
-- Override _ResetPlayerHero to use a gentler Purge that preserves
-- hidden cosmetic/wearable modifiers (the base version strips them,
-- causing ERROR skins on WK).
--------------------------------------------------------------------
function CDotaNPXScenario_TP_Scroll:_ResetPlayerHero( hPlayerHero )
	if not hPlayerHero:IsAlive() then
		hPlayerHero:RespawnHero( false, false )
	end

	-- Gentle purge: only debuffs, preserve hidden/cosmetic modifiers
	hPlayerHero:Purge( false, true, false, true, false )

	for i = DOTA_ITEM_SLOT_1, 16 do
		local hItem = hPlayerHero:GetItemInSlot( i )
		if hItem then
			hPlayerHero:RemoveItem( hItem )
		end
	end

	if self.hScenario and self.hScenario.StartingItems ~= nil then
		for _, szItemName in pairs( self.hScenario.StartingItems ) do
			hPlayerHero:AddItemByName( szItemName )
		end
	end

	hPlayerHero:SetHealth( hPlayerHero:GetMaxHealth() )
	hPlayerHero:SetMana( hPlayerHero:GetMaxMana() )

	for i = 0, hPlayerHero:GetAbilityCount() - 1 do
		local hAbility = hPlayerHero:GetAbilityByIndex( i )
		if hAbility then
			hAbility:EndCooldown()
		end
	end

	if self.hScenario.StartingGold ~= nil then
		PlayerResource:SetGold( 0, self.hScenario.StartingGold, true )
	else
		hPlayerHero:SetGold( 0, true )
	end
	hPlayerHero:SetGold( 0, false )

	if self.hScenario.StartingPosition ~= nil then
		FindClearSpaceForUnit( hPlayerHero, self.hScenario.StartingPosition, true )
	else
		local hSpawnPoint = Entities:FindByClassname( nil, "info_player_start_goodguys" )
		if hSpawnPoint then
			FindClearSpaceForUnit( hPlayerHero, hSpawnPoint:GetAbsOrigin(), true )
		end
	end

	self.bPlayerHeroReady = true
	self.hPlayerHero = hPlayerHero

	self:CenterCameraOnHero()
	self:LoadCombatAnalyzerQueries()
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:OnHeroFinishSpawn( hHero, hPlayer )
	self.hHero = hHero
	self.vStart = hHero:GetAbsOrigin()

	for i=0,DOTA_MAX_ABILITIES-1 do
		local hAbility = hHero:GetAbilityByIndex(i)
		if hAbility then
			print( "Ability #" .. tostring(i) .. " = " .. hAbility:GetAbilityName() )
		end
	end

	CDotaNPXScenario.OnHeroFinishSpawn( self, hHero, hPlayer )

	if hHero then
		local hTP = FindTPScroll( hHero )
		if hTP then
			hTP:EndCooldown()
			hHero:RemoveItem( hTP )
		end
	end
end

--------------------------------------------------------------------


function CDotaNPXScenario_TP_Scroll:OnTaskStarted( event )
	CDotaNPXScenario.OnTaskStarted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end
	
	if Task:GetTaskName() == "buy_two_tp" then
		self:ShowWizardTip( "scenario_tp_scroll_wizard_tip_intro", 10.0 )
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 3.0, function ()
			self:ShowUIHint( "ShopButton" )
		end )
	end
	
	if Task:GetTaskName() == "teleport_to_tower" then
		if self.hTower and not self.hTower:IsNull() then
			PlayerResource:SetCameraTarget( 0, self.hTower )
			self:ScheduleFunctionAtGameTime( GameRules:GetGameTime() + 1.5, function()
				PlayerResource:SetCameraTarget( 0, nil )
			end )
		end
		self:ScheduleFunctionAtGameTime( GameRules:GetGameTime() + 0.5, function()
			self:ShowWizardTip( "scenario_tp_scroll_wizard_tip_teleport", 10.0 )
			self:ShowUIHint( "inventory_tpscroll_slot" )
		end )
	end

	if Task:GetTaskName() == "stun_tp" then
		-- Wire up task targets here (in addition to RevealDK) to ensure
		-- they're set after a checkpoint restart where RevealDK runs
		-- before tasks are fully started.
		if self.hEnemyDK and not self.hEnemyDK:IsNull() then
			Task:SetTargetCaster( self.hEnemyDK )
			local hKillTask = self:GetTask( "kill_enemy" )
			if hKillTask then
				hKillTask:SetUnitsToKill( { self.hEnemyDK } )
			end
		end

		self:ShowWizardTip( "scenario_tp_scroll_wizard_tip_stun", 10.0 )
		self:ShowUIHint( "Ability0 AbilityButton" )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:OnTaskCompleted( event )
	CDotaNPXScenario.OnTaskCompleted( self, event )

	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end
	
	if event.task_name == "buy_two_tp" then
		-- Skip DK reveal if this is a checkpoint skip
		if event.checkpoint_skip == 1 then
			return
		end

		-- Guard: if the DK spawner doesn't exist yet, skip
		if not self.hDKSpawner then
			return
		end

		self:RevealDK()

		self.CreepSpawner = CDotaSpawner( "creep_spawn_location",
		{
			{
				EntityName = "npc_dota_neutral_kobold",
				Team = DOTA_TEAM_NEUTRALS,
				Count = 1,
				PositionNoise = 0,
				PostSpawn = function( hUnit )
					hUnit:SetMaxHealth( 4000 )
					hUnit:SetHealth( 4000 )
				end
			},
		}, self, true )

		local hEnemySpawn = Entities:FindByName( nil, "enemy_spawn_location" )
		if hEnemySpawn then
			AddFOWViewer( DOTA_TEAM_GOODGUYS, hEnemySpawn:GetAbsOrigin(), 250, 999, false )
		end

		return
	elseif event.task_name == "teleport_to_tower" then
		-- Set checkpoint so on retry, player skips buy/TP and starts here
		if event.checkpoint_skip ~= 1 then
			self.nCheckpoint = 1
		end

	elseif event.task_name == "kill_enemy" then
		self:ScheduleFunctionAtGameTime(GameRules:GetDOTATime( false, false ) + 2.0, function()
			self:OnScenarioComplete( true )
		end )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:OnEntityKilled( hVictim, hKiller, hInflictor )
	CDotaNPXScenario.OnEntityKilled( self, hVictim, hKiller, hInflictor )

	if hVictim == self.hHero then
		self:ScheduleFunctionAtGameTime(GameRules:GetDOTATime( false, false ) + 2.0, function()
			self:OnScenarioComplete( false )
		end )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_TP_Scroll:OnTeleportToUnit( event )
	local hBuyTask = self:GetTask( "buy_two_tp" )
	if hBuyTask and hBuyTask:IsActive() and self.hHero and not self.hHero:IsNull() then
		if self.vStart then
			self.hHero:SetAbsOrigin( self.vStart )
		end
		
		local hTP = FindTPScroll( self.hHero )
		if hTP then
			hTP:SetCurrentCharges( hTP:GetCurrentCharges() + 1 )
			hTP:EndCooldown()
		else
			hTP = self.hHero:AddItemByName( "item_tpscroll" )
			if hTP then
				hTP:SetCurrentCharges( 1 )
				hTP:EndCooldown()
			end
		end

		self:ShowWizardTip( "scenario_tp_scroll_wizard_tip_wait", 15.0 )
		EmitGlobalSound( "General.InvalidTarget_Invulnerable" )
	end
end

return CDotaNPXScenario_TP_Scroll
