require( "npx_scenario" )
require( "tasks/task_sequence" )
require( "tasks/task_buy_item" )
require( "tasks/task_move_to_location" )
require( "tasks/task_place_ward_at_location" )
require( "tasks/task_kill_units" )

--------------------------------------------------------------------

if CDotaNPXScenario_Warding == nil then
	CDotaNPXScenario_Warding = class( {}, {}, CDotaNPXScenario )
end

----------------------------------------------------------------------------
-- Precache handled via g_UnitPrecache in precache.lua
----------------------------------------------------------------------------

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:InitScenarioKeys()
	self.hHeroLoc1 = Entities:FindByName( nil, "hero_location_1" )
	self.hHeroLoc2 = Entities:FindByName( nil, "hero_location_2" )
	self.hWardLoc1 = Entities:FindByName( nil, "ward_location_1" )
	self.hWardLoc2 = Entities:FindByName( nil, "ward_location_2" )
	self.hEnemyWardLoc = Entities:FindByName( nil, "enemy_ward_location" )
	self.hHintShopLoc = Entities:FindByName( nil, "shop_hint_location" )
	self.hHintWardLoc = Entities:FindByName( nil, "ward_hint_location" )

	self.hScenario =
	{
		PreGameTime 		= 0.0,
		HeroSelectionTime 	= 0.0,
		StrategyTime 		= 0.0,
		ForceHero 			= "npc_dota_hero_lich",
		Team 				= DOTA_TEAM_GOODGUYS,
		StartingGold		= tonumber( GetCostOfItem( "item_ward_sentry" ) ) or 0,
		StartingItems 		=
		{
			"item_boots",
		},
		StartingAbilities   =
		{			
		},

		ScenarioTimeLimit = 0, -- Timed.

		Tasks =
		{
			{
				TaskName = "buy_observer_ward",
				TaskType = "task_buy_item",
				UseHints = true,
				TaskParams =
				{
					ItemName = "item_ward_observer",
					WhiteList = { "item_ward_observer", },
					DisableWhitelistOnComplete = false,
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
				TaskName = "buy_sentry_ward",
				TaskType = "task_buy_item",
				UseHints = true,
				TaskParams =
				{
					ItemName = "item_ward_sentry",
					WhiteList = { "item_ward_sentry", },
					DisableWhitelistOnComplete = false,
				},
				CheckTaskStart = 
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "buy_observer_ward" )
				end,
			},
			{
				TaskName = "move_to_location_1",
				TaskType = "task_move_to_location",
				UseHints = true,
				TaskParams =
				{
					GoalLocation = self.hHeroLoc1:GetAbsOrigin(),
					GoalDistance = 96,
				},
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "buy_sentry_ward" )
				end,
			},
			{
				TaskName = "place_obs_ward_1",
				TaskType = "task_place_ward_at_location",
				UseHints = true,
				TaskParams =
				{
					WardType = "observer",
					GoalLocation = self.hWardLoc1:GetAbsOrigin(),
					GoalDistance = 96,
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
					GoalLocation = self.hHeroLoc2:GetAbsOrigin(),
					GoalDistance = 96,
				},
				CheckTaskStart =
				function()
					local task = self:GetTask( "place_obs_ward_1" )
					if task and task:IsCompleted() == true and task:CheckSuccess() == true then
						return true
					end
					return false
				end,
				OnCheckpoint =
				function()
					print( 'CHECKPOINT 1' )
					local bForceStart = true
					self:CheckpointSkipCompleteTask( "buy_observer_ward", true, bForceStart )
					self:CheckpointSkipCompleteTask( "buy_sentry_ward", true )
					self:CheckpointSkipCompleteTask( "move_to_location_1", true )
					self:CheckpointSkipCompleteTask( "place_obs_ward_1", true )

					if self:GetPlayerHero() ~= nil then
						LearnHeroAbilities( self:GetPlayerHero(), {} )
						self:GetPlayerHero():AddItemByName( "item_boots" )
						self:GetPlayerHero():AddItemByName( "item_ward_sentry" )

						local hCheckpoints = Entities:FindAllByName( "hero_location_1" )
						if hCheckpoints[1] ~= nil then
							FindClearSpaceForUnit( self:GetPlayerHero(), hCheckpoints[1]:GetAbsOrigin(), true )
							SendToConsole( "+dota_camera_center_on_hero" )
							SendToConsole( "-dota_camera_center_on_hero" )
							self:SpawnEnemy()
						end
					end
				end,
			},
			{
				TaskName = "place_sentry_ward_1",
				TaskType = "task_place_ward_at_location",
				UseHints = true,
				TaskParams =
				{
					WardType = "sentry",
					GoalLocation = self.hWardLoc2:GetAbsOrigin(),
					GoalDistance = 96,
				},
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "move_to_location_2" )
				end,
			},
			{
				TaskName = "destroy_enemy_ward",
				TaskType = "task_kill_units",
				UseHints = true,
				TaskParams =
				{
				},
				CheckTaskStart =
				function() 
					return GameRules.DotaNPX:IsTaskComplete( "place_sentry_ward_1" )
				end,
			},
		},

		Queries =
		{
		},
	}

end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:SetupScenario()
	if not CDotaNPXScenario.SetupScenario( self ) then
		return false
	end

	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false )
	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_DEFAULT_UI_TOP_HEROES, false )
	GameRules:SetTimeOfDay( 0.75 ) -- Daytime
	GameRules:GetGameModeEntity():SetDaynightCycleDisabled( true ) -- Always daytime
	GameRules:SetHeroRespawnEnabled( false ) -- No respawn
	GameRules:SetUseUniversalShopMode( true ) -- Universal Shop
	GameRules:GetGameModeEntity():SetAnnouncerDisabled( true )
	GameRules:GetGameModeEntity():SetKillingSpreeAnnouncerDisabled( true )
	GameRules:GetGameModeEntity():SetWeatherEffectsDisabled( true )
	GameRules:SetItemStockCount( 1, DOTA_TEAM_GOODGUYS, "item_ward_observer", -1 ) -- Always have 1 Observer Ward in the Shop
	GameRules:SetItemStockCount( 1, DOTA_TEAM_GOODGUYS, "item_ward_sentry", -1 ) -- Always have 1 Sentry Ward in the Shop

	Tutorial:StartTutorialMode()
	Tutorial:SetItemGuide( "warding" )

	self.bEnemyWardSpawned = false
	self.bFirstWardPlaced = false
	self.bCanPlaceObserver = false
	self.bCanPlaceSentry = false
	self.bPudgeRevealed = false
	self.bReplacingWard = false

	-- Pre-spawn Pudge frozen; revealed when player reaches move_to_location_2.
	-- On restart, spawner persists — skip re-creation.
	if not self.hPudgeSpawner then
		CDotaSpawner( "enemy_spawner", 
		{
			{
				EntityName = "npc_dota_hero_pudge",
				Team = DOTA_TEAM_BADGUYS,
				Count = 1,
				PositionNoise = 0,
				BotPlayer =
				{
					PlayerID = 1,
					BotName = "Pudge",
					EntityScript = "ai/warding/ai_warding_pudge.lua",
					StartingHeroLevel = 10,
					StartingItems = 
					{
						"item_tranquil_boots",
						"item_magic_wand",
						"item_urn_of_shadows",
					},
					AbilityBuild = 
					{
						AbilityPriority = { 
						"pudge_meat_hook",
						"pudge_rot",
						},
					},
				},
			},
		}, self, true )
	end

	self.nTaskListener = ListenToGameEvent( "trigger_start_touch", Dynamic_Wrap( CDotaNPXScenario_Warding, "OnTriggerStartTouch" ), self )
	self.nTaskListener = ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CDotaNPXScenario_Warding, "OnWardSpawned" ), self )

	-- Pre-spawn hidden wards at target locations using CreateUnitByName.
	-- These use the default (precached) model — no cosmetic ERROR.
	-- When the player places their ward, we remove the cosmetic one and
	-- reveal this pre-spawned one instead.
	self:PreSpawnWards()

	return true
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnSpawnerFinished( event )
	CDotaNPXScenario.OnSpawnerFinished( self, event )

	-- Identify Pudge by unit name and freeze manually
	for _, spawner in pairs( self.rgSpawners ) do
		local hUnit = spawner:GetSpawnedUnits()[ 1 ]
		if hUnit and not hUnit.bFrozen then
			if hUnit:GetUnitName() == "npc_dota_hero_pudge" then
				self.hPudgeSpawner = spawner
				-- Manual freeze (matches manual reveal in SpawnEnemy)
				hUnit.bFrozen = true
				hUnit:AddNewModifier( nil, nil, "modifier_invulnerable", {} )
				hUnit:SetAbsOrigin( Vector( 10000, 10000, 0 ) )
				hUnit:Stop()
				printf( "Froze pre-spawned Pudge" )
			end
		end
	end
end

--------------------------------------------------------------------
-- Helper: re-freeze Pudge for restart reuse.
--------------------------------------------------------------------
function CDotaNPXScenario_Warding:RefreezePudge()
	if not self.hPudgeSpawner then return end
	local hUnit = self.hPudgeSpawner:GetSpawnedUnits()[ 1 ]
	if not hUnit or hUnit:IsNull() then return end

	local hEnt = Entities:FindByName( nil, "enemy_spawner" )
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
		hUnit.Bot.nBotState = 0  -- PUDGE_BOT_STATE_IDLE
		hUnit.Bot.bMovedToStart = false
		hUnit.Bot.hAttackTarget = nil
	end

	RefreshHero( hUnit )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:Restart()
	self:RefreezePudge()
	self.bPudgeRevealed = false
	self.bCanPlaceObserver = false
	self.bCanPlaceSentry = false
	self.bEnemyWardSpawned = false
	self.bReplacingWard = false

	-- Remove any player-placed cosmetic wards that might linger
	local hAllWards = Entities:FindAllByClassname( "npc_dota_observer_wards" )
	for _, hWard in pairs( hAllWards ) do
		if hWard and not hWard:IsNull() and hWard ~= self.hPreObsWard then
			UTIL_Remove( hWard )
		end
	end
	local hAllSentries = Entities:FindAllByClassname( "npc_dota_sentry_wards" )
	for _, hWard in pairs( hAllSentries ) do
		if hWard and not hWard:IsNull() and hWard ~= self.hPreSentryWard then
			UTIL_Remove( hWard )
		end
	end

	-- Re-hide pre-spawned wards (or recreate if they were destroyed)
	self:PreSpawnWards()

	CDotaNPXScenario.Restart( self )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnSetupComplete()
	CDotaNPXScenario.OnSetupComplete( self )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnHeroFinishSpawn( hHero, hPlayer )
	CDotaNPXScenario.OnHeroFinishSpawn( self, hHero, hPlayer )
	self.hHero = hHero
	self.hHero:SetAbilityPoints( 0 )
	--self.hHero:SetHealth( 100 )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnTaskStarted( event )
	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end
	self:HideUIHint()
	if event.task_name == "buy_observer_ward" then
		--self:HintWorldText( self.hHintShopLoc:GetAbsOrigin(), "open_shop", 89, -1 )
		-- Show UI Hint for Shop Button here
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 2, function ()
			self:ShowUIHint( "ShopButton", "scenario_warding_ui_tip_click_to_open_shop", 0.0, nil)
		end )
	elseif event.task_name == "buy_sentry_ward" then
		--self:HintWorldText( self.hHintShopLoc:GetAbsOrigin(), "buy_sentry", 89, -1 )
	elseif event.task_name == "move_to_location_1" then
		self:ShowWizardTip( "scenario_warding_wizard_tip_ward_slot", 15.0 )
		--self:EndHintWorldText( self.hHintShopLoc:GetAbsOrigin() )
	elseif event.task_name == "place_obs_ward_1" then
		self.bCanPlaceObserver = true
		self:ShowItemHint( "item_ward_observer" )
		--self:HintWorldText( self.hHintWardLoc:GetAbsOrigin(), "place_ward", 89, -1 )
	elseif event.task_name == "move_to_location_2" then
		self:SpawnEnemy()
		self:ShowWizardTip( "scenario_warding_wizard_tip_vision", 15.0 )
		-- After Pudge walks to his spot, warn the player to avoid hook range
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 4, function()
			self:ShowWizardTip( "scenario_warding_wizard_tip_avoid_pudge", 15.0 )
		end )
		--self:EndHintWorldText( self.hHintWardLoc:GetAbsOrigin() ) 
	elseif event.task_name == "place_sentry_ward_1" then
		self.bCanPlaceSentry = true
		self:ShowItemHint( "item_ward_sentry" )
	elseif event.task_name == "destroy_enemy_ward" then
		self:ShowWizardTip( "scenario_warding_wizard_tip_sentry", 15.0 )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnTaskCompleted( event )
	local Task = self:GetTask( event.task_name )
	if Task == nil then
		return
	end

	if event.checkpoint_skip == 1 then
		print( 'Checkpoint Skipping past the task completed logic for - ' .. Task:GetTaskName() )
		return
	end

	if event.task_name == "place_sentry_ward_1" then
		self.bEnemyWardSpawned = true
		self:SpawnEnemyWard()
		AddFOWViewer( DOTA_TEAM_GOODGUYS, self.hWardLoc2:GetAbsOrigin(), 100, 480, false )
	elseif event.task_name == "destroy_enemy_ward" then
		self:OnScenarioRankAchieved( 1 )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:SpawnEnemyWard()
	print("Spawning enemy ward")
	local hEnemyWard = CreateUnitByName( "npc_dota_observer_wards", self.hEnemyWardLoc:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS )
	local Task = self:GetTask( "destroy_enemy_ward" )
	if Task then
		local hUnitsToKill = {}
		table.insert( hUnitsToKill, hEnemyWard )
		Task:SetUnitsToKill( hUnitsToKill )
	end

end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:SpawnEnemy()
	if self.bPudgeRevealed then return end
	self.bPudgeRevealed = true

	print("Revealing enemy Pudge")
	if self.hPudgeSpawner then
		local hUnit = self.hPudgeSpawner:GetSpawnedUnits()[1]
		if hUnit and not hUnit:IsNull() then
			-- Manual reveal: unfreeze, remove invuln, move to spawn position
			hUnit.bFrozen = nil
			hUnit:RemoveModifierByName( "modifier_invulnerable" )

			local hPos = Entities:FindByName( nil, "enemy_spawner" )
			if hPos then
				FindClearSpaceForUnit( hUnit, hPos:GetAbsOrigin(), true )
			end

			-- Reset bot AI state for fresh encounter
			if hUnit.Bot then
				hUnit.Bot.bWasKilled = nil
				hUnit.Bot.bMovedToStart = false
				hUnit.Bot.nBotState = 0  -- PUDGE_BOT_STATE_IDLE
				hUnit.Bot.hAttackTarget = nil
			end

			self.hEnemyPudge = hUnit
		end
	end

	-- Pan camera to show Pudge (SetCameraTarget works in custom games, SendToConsole dota_camera_lerp_position does not)
	if self.hEnemyPudge and not self.hEnemyPudge:IsNull() then
		PlayerResource:SetCameraTarget( 0, self.hEnemyPudge )
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 3, function()
			PlayerResource:SetCameraTarget( 0, nil )
		end )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnEntityKilled( hEnt )
	CDotaNPXScenario:OnEntityKilled( hEnt )
	if hEnt == nil or hEnt:IsNull() then return end
	if self.hHero and hEnt == self.hHero then
		-- Delay restart so the death animation finishes and hook pull doesn't
		-- cause the hero model to fly across the map on respawn.
		self:ScheduleFunctionAtGameTime( GameRules:GetDOTATime( false, false ) + 1.5, function()
			self:Restart()
		end )
		return
	end
	if hEnt:GetUnitName() == "npc_dota_sentry_wards" then
		self:OnScenarioComplete( false, "scenario_warding_failure_sentry_ward_destroyed" )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:PreSpawnWards()
	-- Create observer ward at ward_location_1
	if self.hPreObsWard and not self.hPreObsWard:IsNull() then
		UTIL_Remove( self.hPreObsWard )
	end
	self.bReplacingWard = true
	self.hPreObsWard = CreateUnitByName( "npc_dota_observer_wards", self.hWardLoc1:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS )
	self.bReplacingWard = false
	if self.hPreObsWard then
		self:HideWard( self.hPreObsWard )
	end

	-- Create sentry ward at ward_location_2
	if self.hPreSentryWard and not self.hPreSentryWard:IsNull() then
		UTIL_Remove( self.hPreSentryWard )
	end
	self.bReplacingWard = true
	self.hPreSentryWard = CreateUnitByName( "npc_dota_sentry_wards", self.hWardLoc2:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS )
	self.bReplacingWard = false
	if self.hPreSentryWard then
		self:HideWard( self.hPreSentryWard )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:HideWard( hWard )
	hWard:AddNoDraw()
	hWard:AddNewModifier( hWard, nil, "modifier_invulnerable", {} )
	hWard:SetDayTimeVisionRange( 0 )
	hWard:SetNightTimeVisionRange( 0 )
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:RevealWard( hWard )
	hWard:RemoveNoDraw()
	hWard:RemoveModifierByName( "modifier_invulnerable" )
	-- Restore default vision ranges
	if hWard:GetUnitName() == "npc_dota_observer_wards" then
		hWard:SetDayTimeVisionRange( 1400 )
		hWard:SetNightTimeVisionRange( 1400 )
	elseif hWard:GetUnitName() == "npc_dota_sentry_wards" then
		hWard:SetDayTimeVisionRange( 150 )
		hWard:SetNightTimeVisionRange( 150 )
	end
end

--------------------------------------------------------------------

function CDotaNPXScenario_Warding:OnWardSpawned( event )
	local hUnit = EntIndexToHScript( event.entindex )
	if hUnit == nil or hUnit:IsNull() then return end

	-- Only process player-placed wards (GOODGUYS).
	if hUnit:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then return end

	-- Skip our own pre-spawned wards
	if self.bReplacingWard then return end

	if hUnit:GetUnitName() == "npc_dota_observer_wards" then
		print("Observer Ward Detected (player placed)")

		if self.bCanPlaceObserver == false then
			self:OnScenarioComplete( false, "scenario_warding_failure_observer_placed_at_wrong_time" )
			return
		end

		-- Hide the player's cosmetic ward (ERROR model) but don't remove it —
		-- the task system needs the entity handle to check position and complete.
		hUnit:AddNoDraw()
		hUnit:SetDayTimeVisionRange( 0 )
		hUnit:SetNightTimeVisionRange( 0 )

		-- Reveal the pre-spawned ward with correct model
		if self.hPreObsWard and not self.hPreObsWard:IsNull() then
			self:RevealWard( self.hPreObsWard )
		end

	elseif hUnit:GetUnitName() == "npc_dota_sentry_wards" then
		print("Sentry Ward Detected (player placed)")

		if self.bCanPlaceSentry == false then
			self:OnScenarioComplete( false, "scenario_warding_failure_sentry_placed_at_wrong_time" )
			return
		end

		hUnit:AddNoDraw()
		hUnit:SetDayTimeVisionRange( 0 )
		hUnit:SetNightTimeVisionRange( 0 )

		-- Reveal the pre-spawned sentry with correct model
		if self.hPreSentryWard and not self.hPreSentryWard:IsNull() then
			self:RevealWard( self.hPreSentryWard )
		end
	end
end

----------------------------------------------------------------------------

function CDotaNPXScenario_Warding:ShowItemHint( szItemName )
	local hItem = self.hHero:FindItemInInventory( szItemName )
	if hItem then
		local nItemSlot = hItem:GetItemSlot()
		if nItemSlot >= 0 then
			self:ShowUIHint( "inventory_slot_" .. nItemSlot )
			return
		end
	end
	self:HideUIHint()
end

--------------------------------------------------------------------

return CDotaNPXScenario_Warding
