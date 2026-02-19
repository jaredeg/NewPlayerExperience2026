-- NPX AI Safety Layer
-- Goal: prevent NPX training bots from hard-crashing Lua/engine when abilities/targets/items are missing
-- and allow scenarios to remain playable even when hero kits change over time.

if SafeExecuteOrder == nil then
	pcall( function() DoScriptFile( "ai/ai_safety", nil ) end )
end

if SafeEntIndex == nil then
	function SafeEntIndex( h )
		if h == nil then return -1 end
		-- Some code may pass raw indexes already
		if type( h ) == "number" then
			return h
		end
		-- Handle IsNull/entindex if available
		if h.IsNull ~= nil then
			local ok, isNull = pcall( function() return h:IsNull() end )
			if ok and isNull then
				return -1
			end
		end
		if h.entindex ~= nil then
			local ok, idx = pcall( function() return SafeEntIndex(h) end )
			if ok and idx ~= nil then
				return idx
			end
		end
		return -1
	end
end

if SafeGetAbsOrigin == nil then
	function SafeGetAbsOrigin( h )
		-- Return a valid Vector() even if h is nil
		if h == nil then
			return Vector( 0, 0, 0 )
		end
		if h.IsNull ~= nil then
			local ok, isNull = pcall( function() return h:IsNull() end )
			if ok and isNull then
				return Vector( 0, 0, 0 )
			end
		end
		if h.GetAbsOrigin ~= nil then
			local ok, v = pcall( function() return SafeGetAbsOrigin(h) end )
			if ok and v ~= nil then
				return v
			end
		end
		return Vector( 0, 0, 0 )
	end
end

if SafeIsAlive == nil then
	function SafeIsAlive( h )
		if h == nil then return false end
		if h.IsNull ~= nil then
			local ok, isNull = pcall( function() return h:IsNull() end )
			if ok and isNull then return false end
		end
		if h.IsAlive ~= nil then
			local ok, alive = pcall( function() return SafeIsAlive(h) end )
			if ok then return alive == true end
		end
		return false
	end
end

if SafeExecuteOrder == nil then
	function SafeExecuteOrder( order )
		if order == nil then return false end
		-- Guard common fields
		if order.UnitIndex ~= nil and order.UnitIndex <= 0 then
			return false
		end
		if order.AbilityIndex ~= nil and order.AbilityIndex <= 0 then
			return false
		end
		if order.TargetIndex ~= nil and order.TargetIndex <= 0 then
			return false
		end
		if order.Position ~= nil then
			-- Ensure Position is a Vector (best-effort: reject nil)
			if order.Position.x == nil then
				return false
			end
		end
		local ok, err = pcall( function() SafeExecuteOrder( order ) end )
		if not ok then
			print( "NPX SafeExecuteOrder suppressed error: " .. tostring( err ) )
			return false
		end
		return true
	end
end
