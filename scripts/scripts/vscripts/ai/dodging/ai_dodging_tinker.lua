
local TINKER_BOT_STATE_IDLE				= 0
local TINKER_BOT_STATE_CAST_MISSILES	= 1
local TINKER_BOT_STATE_CAST_MISSILE		= 1
local TINKER_BOT_STATE_CAST_REARM		= 2
local TINKER_BOT_STATE_TP				= 3
local TINKER_BOT_STATE_INACTIVE			= 4


-----------------------------------------------------------------------------------------------------

if CDodgingTinkerBot == nil then
	CDodgingTinkerBot = class({})
end

function CDodgingTinkerBot:constructor( me )
	self.me = me

	self.hAbilityMissiles = self.me:FindAbilityByName( "tinker_warp_grenade" )
	self.hAbilityRearm = self.me:FindAbilityByName( "tinker_rearm" )

	self.nBotState = TINKER_BOT_STATE_IDLE

	self.me:AddNewModifier(nil, nil, "modifier_fountain_aura_buff", {})

	for _,hTower in ipairs( Entities:FindAllByClassname( "ent_dota_fountain" ) ) do
		if hTower:GetTeam() == me:GetTeam() then
			self.hTpLocation = hTower
			break
		end
	end

	self.hTownPortalItem = nil
	self.LastMissileTime = GameRules:GetGameTime() - 6

	-- Configurable: scenario sets these on the entity before revealing.
	-- Defaults for phase 1.
	self.szCompletionTask = self.me.szCompletionTask or "dodge_all_missiles_1"
	self.fMissileInterval = self.me.fMissileInterval or 3.5
	self.bKillIllusions = self.me.bKillIllusions or false
end


function CDodgingTinkerBot:BotThink()

	if not IsServer() then
		return
	end

	-- Reconfigure for a new phase (scenario sets bReconfigure before reveal)
	if self.me.bReconfigure then
		self.me.bReconfigure = nil
		self.nBotState = TINKER_BOT_STATE_IDLE
		self.szCompletionTask = self.me.szCompletionTask or "dodge_all_missiles_1"
		self.fMissileInterval = self.me.fMissileInterval or 3.5
		self.bKillIllusions = self.me.bKillIllusions or false
		self.LastMissileTime = GameRules:GetGameTime() - 6
		self.hAttackTarget = nil
	end

	-- Frozen offmap: do nothing until revealed
	if self.me.bFrozen then
		return 0.5
	end

	if not self.me:IsAlive() then
		return 1.0
	end

	if GameRules:IsGamePaused() then
		return
	end

	-- Scenario handles freeze/reveal; do NOT call RemoveSelf
	if self.nBotState == TINKER_BOT_STATE_INACTIVE then
		return 1.0
	end

	if self.hTownPortalItem == nil then
		self.hTownPortalItem = self.me:FindItemInInventory( "item_tpscroll" )
		if self.hTownPortalItem then
			self.hTownPortalItem:EndCooldown()
		end
	end
	self.me:SetHealth( self.me:GetMaxHealth() )
	
	local hTask = GameRules.DotaNPX:GetTask( self.szCompletionTask )
	if hTask ~= nil and hTask:IsCompleted() == true then
		-- Scenario will freeze us; just go inactive
		self.nBotState = TINKER_BOT_STATE_INACTIVE
	end

	if self.nBotState == TINKER_BOT_STATE_IDLE then

		local Heroes = FindUnitsInRadius( DOTA_TEAM_BADGUYS, self.me:GetOrigin(), self.me, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )
		if #Heroes > 0 then
			self.hAttackTarget = Heroes[1]
			self.nBotState = TINKER_BOT_STATE_CAST_MISSILE
		else
			return 1
		end


	elseif self.nBotState == TINKER_BOT_STATE_CAST_MISSILE then
		self.hAbilityMissiles:EndCooldown()		

	 	local vDirection = self.hAttackTarget:GetAbsOrigin() - self.me:GetAbsOrigin()

 		self.me:SetForwardVector(vDirection)
		if self.hAbilityMissiles ~= nil and self.hAbilityMissiles:GetLevel() > 0 and self.hAbilityMissiles:IsFullyCastable() and GameRules:GetGameTime() >= self.LastMissileTime + self.fMissileInterval then
			
			-- Kill illusions before casting (phase 2 behavior)
			if self.bKillIllusions then
				local Enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, self.me:GetOrigin(), self.me, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )
				if #Enemies > 0 then
					for _,hEnemy in pairs ( Enemies ) do
						if hEnemy and hEnemy:IsIllusion() == true then
							hEnemy:ForceKill(false)
						end
					end
				end
			end

			-- Refresh the player
			RefreshHero( self.hAttackTarget )
			self.hAttackTarget:RemoveModifierByName("modifier_invulnerable")
			local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/refresher.vpcf", PATTACH_CUSTOMORIGIN, self.hAttackTarget )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, self.hAttackTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", self.hAttackTarget:GetAbsOrigin(), true )
			ParticleManager:ReleaseParticleIndex( nFXIndex )

				ExecuteOrderFromTable( {
				UnitIndex = self.me:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				AbilityIndex = self.hAbilityMissiles:entindex(),
				TargetIndex = self.hAttackTarget:entindex(),
				Queue = true
			} )
			self.LastMissileTime = GameRules:GetGameTime()
			self.nBotState = TINKER_BOT_STATE_CAST_REARM
			self.hAbilityMissiles:RefundManaCost()
		end

		return 1

	 elseif self.nBotState == TINKER_BOT_STATE_CAST_REARM then

	 	self.hAbilityRearm:EndCooldown()

		if self.hAbilityRearm and self.hAbilityRearm:IsFullyCastable() then
	
			
			ExecuteOrderFromTable( {
				UnitIndex = self.me:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = self.hAbilityRearm:entindex(),
				Queue = true
			} )
			self.nBotState = TINKER_BOT_STATE_CAST_MISSILE
		end
		self.hAbilityRearm:RefundManaCost()

		return 3
	end
	return 3
end

-----------------------------------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if IsServer() then
		thisEntity:SetContextThink( "CDodgingTinkerBotThink", CDodgingTinkerBotThink, 1 )

		thisEntity.Bot = CDodgingTinkerBot( thisEntity )
	end
end

function CDodgingTinkerBotThink()
	if IsServer() == false then
		return -1
	end

	thisEntity.Bot:BotThink()

	return 1
end


