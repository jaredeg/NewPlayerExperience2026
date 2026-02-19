
local DK_BOT_STATE_IDLE					= 0
local DK_BOT_STATE_ATTACK				= 1
local DK_BOT_STATE_TP					= 2
local DK_BOT_STATE_INACTIVE				= 3

-----------------------------------------------------------------------------------------------------

if CTPScrollDragonKnightBot == nil then
	CTPScrollDragonKnightBot = class({})
end

function CTPScrollDragonKnightBot:constructor( me )
	self.me = me

	for _,hTower in ipairs( Entities:FindAllByClassname( "npc_dota_tower" ) ) do
		if hTower:GetTeam() == me:GetTeam() then
			self.hTpLocation = hTower
			break
		end
	end

	self.nBotState = DK_BOT_STATE_IDLE
	self.hAttackTarget = nil
	self.hTownPortalItem = nil
	self.bHeroHitMe = false

	-- Register entity_hurt ONCE in constructor.  The bot entity persists
	-- across restarts so this listener stays alive.  We never stop it —
	-- bHeroHitMe flag prevents re-triggering, and the scenario resets
	-- bHeroHitMe on refreeze.
	ListenToGameEvent( "entity_hurt", Dynamic_Wrap( CTPScrollDragonKnightBot, "OnTakeDamage" ), self )
end

-----------------------------------------------------------------------------------------------------

function CTPScrollDragonKnightBot:OnTakeDamage( event )
	if self.bHeroHitMe then return end
	if not event.entindex_killed or not event.entindex_attacker then return end

	local hTarget = EntIndexToHScript( event.entindex_killed )
	local hAttacker = EntIndexToHScript( event.entindex_attacker )
	if hTarget and hTarget == self.me and hAttacker and hAttacker:IsHero() then
		if self.hTownPortalItem and not self.hTownPortalItem:IsNull() and self.hTownPortalItem:IsFullyCastable() then
			self.bHeroHitMe = true
			self:ChangeBotState( DK_BOT_STATE_TP )
		end
	end
end

-----------------------------------------------------------------------------------------------------

function CTPScrollDragonKnightBot:ChangeBotState( nNewState )
	self.nBotState = nNewState
end

-----------------------------------------------------------------------------------------------------
-- BotThink — Lina/Sven pattern.  TP scroll found via FindItemInInventory
-- every think if nil, with EndCooldown.  TP cast via ExecuteOrderFromTable.
-----------------------------------------------------------------------------------------------------
function CTPScrollDragonKnightBot:BotThink()
	if not IsServer() then return end

	if self.me.bFrozen then
		return 0.5
	end

	if not self.me:IsAlive() then
		return -1
	end

	if self.nBotState == DK_BOT_STATE_INACTIVE then
		return 1.0
	end

	-- Re-find TP every think if nil + EndCooldown (Lina/Sven pattern)
	if self.hTownPortalItem == nil then
		self.hTownPortalItem = self.me:FindItemInInventory( "item_tpscroll" )
		if self.hTownPortalItem then
			self.hTownPortalItem:EndCooldown()
		end
	end

	if self.nBotState == DK_BOT_STATE_IDLE then
		-- Look for kobold to attack
		local rgTargets = FindUnitsInRadius( self.me:GetTeam(), self.me:GetOrigin(), self.me, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 0, false )
		if #rgTargets > 0 then
			self.hAttackTarget = rgTargets[1]
			self:ChangeBotState( DK_BOT_STATE_ATTACK )
		end

	elseif self.nBotState == DK_BOT_STATE_ATTACK then
		if not self.hAttackTarget or self.hAttackTarget:IsNull() or not self.hAttackTarget:IsAlive() then
			self.me:Stop()
			self:ChangeBotState( DK_BOT_STATE_IDLE )
			return
		end

		ExecuteOrderFromTable( {
			UnitIndex = self.me:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = self.hAttackTarget:entindex(),
		} )

	elseif self.nBotState == DK_BOT_STATE_TP then
		-- Cast TP via ExecuteOrderFromTable (Lina/Sven pattern)
		if self.hTownPortalItem ~= nil and self.hTownPortalItem:IsNull() == false then
			ExecuteOrderFromTable( {
				UnitIndex = self.me:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
				AbilityIndex = self.hTownPortalItem:entindex(),
				Position = self.hTpLocation:GetAbsOrigin(),
			} )
		end

		-- TP finished: not castable + not channeling = consumed or interrupted
		if self.hTownPortalItem and self.hTownPortalItem:IsNull() == false and not self.hTownPortalItem:IsFullyCastable() and not self.hTownPortalItem:IsChanneling() then
			self.nBotState = DK_BOT_STATE_INACTIVE
			return 1.0
		end
	end

	return 0.25
end

-----------------------------------------------------------------------------------------------------

function Spawn( entityKeyValues )
	if IsServer() then
		thisEntity:SetContextThink( "DragonKnightThink", DragonKnightThink, 0.25 )
		thisEntity.Bot = CTPScrollDragonKnightBot( thisEntity )
	end
end

function DragonKnightThink()
	if not IsServer() then
		return 1.0
	end

	if not thisEntity or thisEntity:IsNull() then
		return 1.0
	end

	if thisEntity.Bot then
		local ok, retval = pcall( function() return thisEntity.Bot:BotThink() end )
		if ok and type( retval ) == "number" and retval > 0 then
			return retval
		end
	end

	return 0.25
end
