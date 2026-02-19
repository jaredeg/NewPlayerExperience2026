
local PUDGE_BOT_STATE_IDLE 		= 0
local PUDGE_BOT_STATE_ATTACK 	= 1

-----------------------------------------------------------------------------------------------------

if CItemsScenarioPudgeBot == nil then
	CItemsScenarioPudgeBot = class({})
end

--------------------------------------------------------------------------------

function CItemsScenarioPudgeBot:constructor( me )
	self.me = me
	self.nBotState = PUDGE_BOT_STATE_IDLE
	self.bMovedToStart = false
	self.hAbilityHook = self.me:FindAbilityByName( "pudge_meat_hook" )
	self.hAbilityRot = self.me:FindAbilityByName( "pudge_rot" )
	self.hAttackTarget = nil
	self.hInitialMoveLoc = Entities:FindByName( nil, "enemy_location_1" )
	self.fAttackStartTime = 0
	self.fMaxAttackTime = 5.0  -- Chase for max 5 seconds then return to spot

	printf( "PudgeBot::constructor" )
end

--------------------------------------------------------------------------------

function CItemsScenarioPudgeBot:ChangeBotState( nNewState )
	self.nBotState = nNewState
end

--------------------------------------------------------------------------------

function CItemsScenarioPudgeBot:BotThink()
	if not IsServer() then
		return
	end

	if self.me.bFrozen then
		return 0.5
	end

	if self.bWasKilled then
		return 1.0
	end

	if ( not self.me:IsAlive() ) then
		self.bWasKilled = true
		return 1.0
	end

	if GameRules:IsGamePaused() == true then
		return 0.5
	end

	if self.nBotState == PUDGE_BOT_STATE_IDLE then
		-- Walk to start position once
		if self.bMovedToStart == false then
			self.bMovedToStart = true
			if self.hInitialMoveLoc then
				ExecuteOrderFromTable( {
					UnitIndex = self.me:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = self.hInitialMoveLoc:GetAbsOrigin(),
					Queue = false,
				} )
			end
			return 0.5
		end

		-- Look for heroes in hook range
		local Heroes = FindUnitsInRadius( DOTA_TEAM_BADGUYS, self.me:GetOrigin(), self.me, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )
		if #Heroes > 0 and self.hAbilityHook and self.hAbilityHook:IsFullyCastable() then
			self.hAttackTarget = Heroes[1]
			self.fAttackStartTime = GameRules:GetGameTime()
			self:ChangeBotState( PUDGE_BOT_STATE_ATTACK )
			-- Toggle Rot on
			if self.hAbilityRot and self.hAbilityRot:GetLevel() > 0 and not self.me:HasModifier( "modifier_pudge_rot" ) then
				ExecuteOrderFromTable( {
					UnitIndex = self.me:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = self.hAbilityRot:entindex(),
				} )
			end
			-- Immediately attack (hook or right-click)
			self:AttackTarget( self.hAttackTarget )
		end

	elseif self.nBotState == PUDGE_BOT_STATE_ATTACK then
		local fElapsed = GameRules:GetGameTime() - self.fAttackStartTime

		-- Stop if target dead/gone or chase time exceeded
		if self.hAttackTarget == nil or self.hAttackTarget:IsNull() or not self.hAttackTarget:IsAlive() or fElapsed > self.fMaxAttackTime then
			-- Toggle Rot off
			if self.hAbilityRot and self.me:HasModifier( "modifier_pudge_rot" ) then
				ExecuteOrderFromTable( {
					UnitIndex = self.me:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = self.hAbilityRot:entindex(),
				} )
			end
			-- Walk back to spot
			self.bMovedToStart = false
			self.hAttackTarget = nil
			self:ChangeBotState( PUDGE_BOT_STATE_IDLE )
			return 0.5
		end

		-- Keep attacking — hook if available, otherwise right-click
		-- This is the exact pattern from the old working bot
		self:AttackTarget( self.hAttackTarget )
	end

	return 0.5
end

--------------------------------------------------------------------------------
-- Attack pattern from the original working bot:
-- Hook if castable, otherwise right-click attack
--------------------------------------------------------------------------------

function CItemsScenarioPudgeBot:AttackTarget( hTarget )
	if hTarget == nil or hTarget:IsNull() or not hTarget:IsAlive() then
		return
	end

	if self.hAbilityHook and self.hAbilityHook:IsFullyCastable() then
		ExecuteOrderFromTable( {
			UnitIndex = self.me:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			AbilityIndex = self.hAbilityHook:entindex(),
			Position = hTarget:GetAbsOrigin(),
		} )
	else
		ExecuteOrderFromTable( {
			UnitIndex = self.me:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = hTarget:entindex(),
		} )
	end
end

--------------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if IsServer() then
		thisEntity:SetContextThink( "PudgeThink", PudgeThink, 0.25 )

		thisEntity.Bot = CItemsScenarioPudgeBot( thisEntity )
	end
end

--------------------------------------------------------------------------------

function PudgeThink()
	if IsServer() == false then
		return 1.0
	end

	if thisEntity == nil or thisEntity:IsNull() or thisEntity.Bot == nil then return 1.0 end
	local fThinkTime = thisEntity.Bot:BotThink()
	if fThinkTime and fThinkTime > 0 then
		return fThinkTime
	end

	return 0.5
end

--------------------------------------------------------------------------------
