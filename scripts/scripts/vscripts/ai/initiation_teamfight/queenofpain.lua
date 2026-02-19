
local QUEENOFPAIN_BOT_STATE_IDLE = 0
local QUEENOFPAIN_BOT_STATE_ATTACK_MOVE = 1
local QUEENOFPAIN_BOT_STATE_UNLOAD_SPELLS = 2

-----------------------------------------------------------------------------------------------------

if CLockdownScenarioQueenOfPainBot == nil then
	CLockdownScenarioQueenOfPainBot = class({})
end

--------------------------------------------------------------------------------

function CLockdownScenarioQueenOfPainBot:constructor( me )
	self.me = me
	self.nBotState = QUEENOFPAIN_BOT_STATE_IDLE

	self.hSonicWaveAbility = self.me:FindAbilityByName( "queenofpain_sonic_wave" )	
	ScriptAssert( self.hSonicWaveAbility ~= nil, "self.hSonicWaveAbility is nil!" )

	self.hAttackMoveLoc = Entities:FindByName( nil, "queenofpain_attack_move_loc" )
	ScriptAssert( self.hAttackMoveLoc ~= nil, "self.hAttackMoveLoc is nil!" )

	self.me:SetHealth( self.me:GetMaxHealth() * 0.4 )
end

--------------------------------------------------------------------------------

function CLockdownScenarioQueenOfPainBot:ChangeBotState( nNewState )
	self.nBotState = nNewState
end

--------------------------------------------------------------------------------

function CLockdownScenarioQueenOfPainBot:BotThink()
	if not IsServer() then
		return
	end

	-- Scenario restart: reset AI state to initial
	if self.me.bScenarioReset then
		self.me.bScenarioReset = nil
		self.bWasKilled = false
		self.nBotState = QUEENOFPAIN_BOT_STATE_IDLE
		self.me:SetHealth( self.me:GetMaxHealth() * 0.4 )
		self.bAttackMoveCommandGiven = false
		self.bAttackMoveAfterUltCommandGiven = false
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

	if self.me.bFrozen then
		return 0.5
	end

	if self.nBotState == QUEENOFPAIN_BOT_STATE_IDLE then
		--printf( "QueenOfPain in state: QUEENOFPAIN_BOT_STATE_IDLE" )

		-- Check the entire map for stunned enemies so QoP always responds
		-- to Ravage even if she is far from the fight.
		local AllHeroes = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector( 0, 0, 0 ), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false )

		local nStunnedEnemyHeroes = 0
		local hFirstStunnedHero = nil
		for _, hHero in pairs( AllHeroes ) do
			if hHero:IsStunned() then
				nStunnedEnemyHeroes = nStunnedEnemyHeroes + 1
				if hFirstStunnedHero == nil then
					hFirstStunnedHero = hHero
				end
			end
		end

		if nStunnedEnemyHeroes >= 2 then
			-- Skip ATTACK_MOVE, go straight to UNLOAD_SPELLS and run toward them
			self:ChangeBotState( QUEENOFPAIN_BOT_STATE_UNLOAD_SPELLS )
			if hFirstStunnedHero then
				ExecuteOrderFromTable( {
					UnitIndex = self.me:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = hFirstStunnedHero:GetAbsOrigin(),
				} )
			end
			return 0.5
		end

		-- Normal IDLE: look for nearby enemies to start attack-moving
		local Heroes = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, self.me:GetOrigin(), self.me, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )

		if #Heroes >= 1 then
			self:ChangeBotState( QUEENOFPAIN_BOT_STATE_ATTACK_MOVE )
		end

		return 0.5
	elseif self.nBotState == QUEENOFPAIN_BOT_STATE_ATTACK_MOVE then
		--printf( "QueenOfPain in state: QUEENOFPAIN_BOT_STATE_ATTACK_MOVE" )
		if not self.bAttackMoveCommandGiven then
			self.bAttackMoveCommandGiven = true

			--printf( "QoP is moving to %s", self.hAttackMoveLoc:GetAbsOrigin() )
			ExecuteOrderFromTable( {
				UnitIndex = self.me:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = self.hAttackMoveLoc:GetAbsOrigin(),
			} )

			return 0.5
		end

		-- Search a wide area for stunned enemies so QoP reacts even when
		-- the player Ravages further from her position.
		local Heroes = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, self.me:GetOrigin(), self.me, 3000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, 0, false )

		local nStunnedEnemyHeroes = 0
		local hFirstStunnedHero = nil
		for _, hHero in pairs( Heroes ) do
			if hHero:IsStunned() then
				nStunnedEnemyHeroes = nStunnedEnemyHeroes + 1
				if hFirstStunnedHero == nil then
					hFirstStunnedHero = hHero
				end
			end
		end

		if nStunnedEnemyHeroes >= 2 then
			self:ChangeBotState( QUEENOFPAIN_BOT_STATE_UNLOAD_SPELLS )
			-- Move toward stunned enemies so she can cast Sonic Wave
			if hFirstStunnedHero then
				ExecuteOrderFromTable( {
					UnitIndex = self.me:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = hFirstStunnedHero:GetAbsOrigin(),
				} )
			end
		end

		return 0.5
	elseif self.nBotState == QUEENOFPAIN_BOT_STATE_UNLOAD_SPELLS then
		--printf( "QueenOfPain in state: QUEENOFPAIN_BOT_STATE_UNLOAD_SPELLS" )

		if self.hSonicWaveAbility:IsCooldownReady() then
			local nSearchRange = self.hSonicWaveAbility:GetCastRange( self.me:GetOrigin(), nil )
			local Heroes = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, self.me:GetOrigin(), self.me, nSearchRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )

			--printf( "QueenOfPain: My sonic wave is ready" )
			if #Heroes >= 1 then
				--printf( "There's at least 1 enemy hero" )
				local hNearTarget = Heroes[ 1 ]
				--printf( "Casting %s on %s", self.hSonicWaveAbility:GetAbilityName(), hNearTarget:GetUnitName() )
				self.me:CastAbilityOnPosition( hNearTarget:GetAbsOrigin(), self.hSonicWaveAbility, -1 )

				return 1.0
			end
		elseif ( not self.bAttackMoveAfterUltCommandGiven ) then
			self.bAttackMoveAfterUltCommandGiven = true

			--printf( "QoP is moving to %s", self.hAttackMoveLoc:GetAbsOrigin() )
			ExecuteOrderFromTable( {
				UnitIndex = self.me:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = self.hAttackMoveLoc:GetAbsOrigin(),
			} )

			return 0.5
		end

		return 0.5
	end

	return 0.5
end

--------------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if IsServer() then
		thisEntity:SetContextThink( "LockdownScenarioQueenOfPainThink", LockdownScenarioQueenOfPainThink, 0.25 )

		thisEntity.Bot = CLockdownScenarioQueenOfPainBot( thisEntity )
	end
end

--------------------------------------------------------------------------------

function LockdownScenarioQueenOfPainThink()
	if IsServer() == false then
		return -1
	end

	return thisEntity.Bot:BotThink()
end

--------------------------------------------------------------------------------
