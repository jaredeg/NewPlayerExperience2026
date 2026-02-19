
g_ModelPrecache =
{
}

g_UnitPrecache =
{
	-- Custom hero override
	"npc_dota_hero_templar_assassin_template",

	-- Heroes used across tutorial scenario AI scripts.
	-- All heroes must be listed here (not as explicit PrecacheUnitByNameSync
	-- calls) because the engine processes g_UnitPrecache more reliably
	-- than inline calls.  Moving heroes to this table fixed SF/Nevermore
	-- in the economy scenario.
	"npc_dota_hero_phantom_assassin",
	"npc_dota_hero_mirana",
	"npc_dota_hero_nevermore",
	"npc_dota_hero_lina",
	"npc_dota_hero_lion",
	"npc_dota_hero_drow_ranger",
	"npc_dota_hero_shadow_shaman",
	"npc_dota_hero_queenofpain",
	"npc_dota_hero_ogre_magi",
	"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_tinker",
	"npc_dota_hero_ursa",
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_invoker",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_sniper",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_enigma",
	"npc_dota_hero_gyrocopter",
	"npc_dota_hero_alchemist",
	"npc_dota_hero_crystal_maiden",
	"npc_dota_hero_tidehunter",
	"npc_dota_hero_skeleton_king",
	"npc_dota_hero_bane",
	"npc_dota_hero_juggernaut",
	"npc_dota_hero_snapfire",
	"npc_dota_hero_lich",
	"npc_dota_hero_sven",
	"npc_dota_hero_dark_seer",
	"npc_dota_hero_troll_warlord",
	"npc_dota_hero_storm_spirit",
	"npc_dota_hero_bounty_hunter",
	"npc_dota_hero_riki",
	"npc_dota_hero_pudge",
	"npc_dota_hero_earthshaker",
	"npc_dota_hero_undying",
	"npc_dota_hero_windrunner",
	"npc_dota_hero_phantom_lancer",
	"npc_dota_hero_furion",
	"npc_dota_hero_zuus",
	"npc_dota_hero_viper",

	-- Courier
	"npc_dota_courier",

	-- Custom units from npc_units_custom.txt
	"npc_dota_big_centaur",
	"npc_dota_broodmother_spiderling_weak",
	"npc_dota_custom_target_dummy",
	"npc_dota_lycan_wolf4",

	-- Ward units (used in warding scenario)
	"npc_dota_observer_wards",
	"npc_dota_sentry_wards",
}

g_ItemPrecache =
{
	"item_ward_observer",
	"item_ward_sentry",
}

g_SoundPrecache =
{
	"soundevents/game_sounds_vo.vsndevts",
}

g_ParticlePrecache =
{
}

g_ParticleFolderPrecache =
{
	"particles/world_environmental_fx",
}
