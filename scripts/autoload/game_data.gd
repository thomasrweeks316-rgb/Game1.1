extends Node

const WEAPONS: Dictionary = {
	"minigun": {
		"name": "Drum Spinner",
		"description": "Bite Force-style spinning drum delivers rapid impacts.",
		"damage": 8,
		"fire_rate": 0.08,
		"range": 320,
		"projectile_speed": 500,
		"gem_cost": 0,
		"arena_unlock": 0,
		"color": Color(0.7, 0.7, 0.75),
		"type": "bullet",
	},
	"shotgun": {
		"name": "Fork Flipper",
		"description": "Multi-prong flipper fires a wide spread at close range.",
		"damage": 6,
		"fire_rate": 0.7,
		"range": 180,
		"projectile_speed": 400,
		"gem_cost": 150,
		"arena_unlock": 0,
		"color": Color(0.55, 0.45, 0.35),
		"type": "spread",
		"pellets": 6,
	},
	"rocket": {
		"name": "Pneumatic Cannon",
		"description": "Compressed-air launcher with explosive area impact.",
		"damage": 35,
		"fire_rate": 1.2,
		"range": 400,
		"projectile_speed": 280,
		"gem_cost": 300,
		"arena_unlock": 1,
		"color": Color(0.9, 0.4, 0.1),
		"type": "explosive",
		"blast_radius": 60,
	},
	"laser": {
		"name": "Overhead Bar",
		"description": "Tombstone-inspired horizontal spinner bar pierces armor.",
		"damage": 22,
		"fire_rate": 0.5,
		"range": 450,
		"projectile_speed": 800,
		"gem_cost": 400,
		"arena_unlock": 1,
		"color": Color(1.0, 0.2, 0.3),
		"type": "piercing",
	},
	"saw": {
		"name": "Vertical Spinner",
		"description": "Deadlift-style vertical disc shreds bots at close range.",
		"damage": 18,
		"fire_rate": 0.3,
		"range": 70,
		"projectile_speed": 0,
		"gem_cost": 250,
		"arena_unlock": 0,
		"color": Color(0.6, 0.6, 0.65),
		"type": "melee",
	},
	"tesla": {
		"name": "Chain Flail",
		"description": "Whipping chain arcs damage between nearby bots.",
		"damage": 15,
		"fire_rate": 0.6,
		"range": 250,
		"projectile_speed": 600,
		"gem_cost": 500,
		"arena_unlock": 2,
		"color": Color(0.3, 0.7, 1.0),
		"type": "chain",
		"chain_count": 3,
	},
	"flame": {
		"name": "Flamethrower",
		"description": "Jackpot-style flame burst that burns over time.",
		"damage": 5,
		"fire_rate": 0.1,
		"range": 140,
		"projectile_speed": 300,
		"gem_cost": 350,
		"arena_unlock": 2,
		"color": Color(1.0, 0.5, 0.0),
		"type": "flame",
		"dot_damage": 3,
		"dot_duration": 2.0,
	},
	"plasma": {
		"name": "Pneumatic Hammer",
		"description": "Overhead pneumatic hammer delivers crushing blows.",
		"damage": 40,
		"fire_rate": 0.9,
		"range": 380,
		"projectile_speed": 450,
		"gem_cost": 600,
		"arena_unlock": 3,
		"color": Color(0.5, 0.0, 1.0),
		"type": "bullet",
	},
	"missile": {
		"name": "Guided Ram",
		"description": "Self-steering pneumatic ram tracks its target.",
		"damage": 28,
		"fire_rate": 1.5,
		"range": 500,
		"projectile_speed": 200,
		"gem_cost": 700,
		"arena_unlock": 3,
		"color": Color(0.8, 0.8, 0.2),
		"type": "homing",
	},
	"drill": {
		"name": "Auger Drive",
		"description": "Burrowing auger that tears through armor plating.",
		"damage": 25,
		"fire_rate": 0.4,
		"range": 65,
		"projectile_speed": 0,
		"gem_cost": 450,
		"arena_unlock": 2,
		"color": Color(0.75, 0.55, 0.2),
		"type": "melee",
		"armor_break": true,
	},
	"freeze": {
		"name": "CO2 Blast",
		"description": "Rapid CO2 discharge slows enemy drive systems.",
		"damage": 12,
		"fire_rate": 0.45,
		"range": 300,
		"projectile_speed": 350,
		"gem_cost": 550,
		"arena_unlock": 3,
		"color": Color(0.6, 0.9, 1.0),
		"type": "slow",
		"slow_factor": 0.4,
		"slow_duration": 2.5,
	},
	"poison": {
		"name": "Grinder Dust",
		"description": "Metal shavings cause lingering grinding damage.",
		"damage": 4,
		"fire_rate": 0.15,
		"range": 200,
		"projectile_speed": 250,
		"gem_cost": 400,
		"arena_unlock": 4,
		"color": Color(0.3, 0.9, 0.2),
		"type": "poison",
		"dot_damage": 5,
		"dot_duration": 4.0,
	},
	"railgun": {
		"name": "Slam Hammer",
		"description": "Bronco-style overhead slam with devastating force.",
		"damage": 80,
		"fire_rate": 2.0,
		"range": 600,
		"projectile_speed": 1200,
		"gem_cost": 900,
		"arena_unlock": 4,
		"color": Color(0.2, 0.8, 0.9),
		"type": "piercing",
	},
	"boomerang": {
		"name": "Flywheel Disc",
		"description": "Returning vertical spinner disc cuts on the way out and back.",
		"damage": 20,
		"fire_rate": 0.8,
		"range": 280,
		"projectile_speed": 350,
		"gem_cost": 500,
		"arena_unlock": 3,
		"color": Color(0.85, 0.85, 0.9),
		"type": "boomerang",
	},
	"shield_gen": {
		"name": "Wedge Armor",
		"description": "Reinforced wedge plating absorbs incoming hits.",
		"damage": 0,
		"fire_rate": 5.0,
		"range": 0,
		"projectile_speed": 0,
		"gem_cost": 650,
		"arena_unlock": 4,
		"color": Color(0.2, 0.5, 1.0),
		"type": "shield",
		"shield_amount": 80,
		"shield_duration": 4.0,
	},
	"mortar": {
		"name": "Flipper Launcher",
		"description": "Arcing flipper tosses opponents with blast radius.",
		"damage": 45,
		"fire_rate": 1.8,
		"range": 420,
		"projectile_speed": 200,
		"gem_cost": 750,
		"arena_unlock": 5,
		"color": Color(0.4, 0.35, 0.3),
		"type": "mortar",
		"blast_radius": 80,
	},
	"emp": {
		"name": "Impact Driver",
		"description": "Hydraulic strike briefly disables enemy weapons.",
		"damage": 10,
		"fire_rate": 2.5,
		"range": 280,
		"projectile_speed": 400,
		"gem_cost": 800,
		"arena_unlock": 5,
		"color": Color(0.9, 0.9, 0.3),
		"type": "emp",
		"disable_duration": 2.0,
	},
	"gravity": {
		"name": "Magnet Pull",
		"description": "Powerful magnets yank opponents off balance.",
		"damage": 8,
		"fire_rate": 3.0,
		"range": 200,
		"projectile_speed": 0,
		"gem_cost": 950,
		"arena_unlock": 6,
		"color": Color(0.4, 0.1, 0.6),
		"type": "gravity",
		"pull_radius": 120,
	},
	"photon": {
		"name": "Drive Wheel",
		"description": "High-torque wheel ram for sustained drive pressure.",
		"damage": 30,
		"fire_rate": 0.25,
		"range": 400,
		"projectile_speed": 900,
		"gem_cost": 850,
		"arena_unlock": 6,
		"color": Color(1.0, 1.0, 0.8),
		"type": "bullet",
	},
	"vortex": {
		"name": "Undercutter",
		"description": "Low-profile spinner grinds opponents from beneath.",
		"damage": 12,
		"fire_rate": 2.2,
		"range": 350,
		"projectile_speed": 300,
		"gem_cost": 1000,
		"arena_unlock": 7,
		"color": Color(0.6, 0.0, 0.8),
		"type": "vortex",
		"vortex_duration": 3.0,
		"vortex_radius": 90,
	},
}

const CHASSIS: Dictionary = {
	"light": {
		"name": "Light Frame",
		"hp": 100,
		"speed": 220,
		"armor": 0,
		"weapon_slots": 1,
		"gem_cost": 0,
		"arena_unlock": 0,
		"color": Color(0.4, 0.7, 0.9),
	},
	"medium": {
		"name": "Medium Frame",
		"hp": 150,
		"speed": 180,
		"armor": 10,
		"weapon_slots": 2,
		"gem_cost": 200,
		"arena_unlock": 1,
		"color": Color(0.5, 0.55, 0.6),
	},
	"heavy": {
		"name": "Heavy Frame",
		"hp": 220,
		"speed": 140,
		"armor": 25,
		"weapon_slots": 3,
		"gem_cost": 450,
		"arena_unlock": 2,
		"color": Color(0.45, 0.4, 0.42),
	},
	"titan": {
		"name": "Titan Frame",
		"hp": 300,
		"speed": 110,
		"armor": 40,
		"weapon_slots": 3,
		"gem_cost": 800,
		"arena_unlock": 4,
		"color": Color(0.6, 0.3, 0.25),
	},
	"stealth": {
		"name": "Stealth Frame",
		"hp": 90,
		"speed": 260,
		"armor": 5,
		"weapon_slots": 1,
		"gem_cost": 600,
		"arena_unlock": 3,
		"color": Color(0.2, 0.25, 0.3),
	},
}

const ARENAS: Array[Dictionary] = [
	{
		"id": 0,
		"name": "Scrap Yard",
		"description": "Rusty junk and broken bots litter the arena.",
		"trophy_required": 0,
		"gem_reward_win": 15,
		"gem_reward_boss": 100,
		"bg_color": Color(0.35, 0.28, 0.22),
		"accent": Color(0.7, 0.5, 0.3),
		"weapon_pool": ["minigun", "shotgun", "saw"],
		"chassis_pool": ["light"],
		"terrain": [
			{"shape": "rect", "pos": Vector2(640, 400), "size": Vector2(130, 75), "color": Color(0.48, 0.34, 0.22)},
			{"shape": "rect", "pos": Vector2(460, 290), "size": Vector2(70, 70), "color": Color(0.42, 0.3, 0.2)},
			{"shape": "rect", "pos": Vector2(820, 470), "size": Vector2(80, 65), "color": Color(0.45, 0.32, 0.21)},
			{"shape": "rect", "pos": Vector2(540, 520), "size": Vector2(55, 90), "color": Color(0.4, 0.38, 0.36)},
		],
		"boss": {
			"name": "Junk Titan",
			"hp": 500,
			"damage_mult": 1.2,
			"speed": 90,
			"weapons": ["shotgun", "saw"],
			"color": Color(0.55, 0.4, 0.3),
			"size": 1.8,
		},
	},
	{
		"id": 1,
		"name": "Factory Floor",
		"description": "Conveyor belts and industrial hazards.",
		"trophy_required": 50,
		"gem_reward_win": 20,
		"gem_reward_boss": 150,
		"bg_color": Color(0.25, 0.27, 0.3),
		"accent": Color(0.8, 0.6, 0.2),
		"weapon_pool": ["minigun", "shotgun", "rocket", "laser", "saw"],
		"chassis_pool": ["light", "medium", "heavy"],
		"terrain": [
			{"shape": "rect", "pos": Vector2(640, 330), "size": Vector2(55, 150), "color": Color(0.38, 0.4, 0.44)},
			{"shape": "rect", "pos": Vector2(500, 460), "size": Vector2(100, 45), "color": Color(0.42, 0.44, 0.48)},
			{"shape": "rect", "pos": Vector2(780, 260), "size": Vector2(95, 50), "color": Color(0.4, 0.42, 0.46)},
			{"shape": "rect", "pos": Vector2(350, 380), "size": Vector2(40, 110), "color": Color(0.36, 0.38, 0.42)},
			{"shape": "rect", "pos": Vector2(930, 400), "size": Vector2(40, 110), "color": Color(0.36, 0.38, 0.42)},
		],
		"boss": {
			"name": "Tombstone",
			"hp": 650,
			"damage_mult": 1.3,
			"speed": 70,
			"weapons": ["laser", "minigun", "rocket"],
			"color": Color(0.3, 0.35, 0.4),
			"size": 2.0,
			"model": "res://assets/Boss1.1/tombstone_2018_-_battlebots.glb",
			"model_scale": 1.0,
		},
	},
	{
		"id": 2,
		"name": "Volcano Forge",
		"description": "Molten lava flows beneath metal grating.",
		"trophy_required": 120,
		"gem_reward_win": 28,
		"gem_reward_boss": 200,
		"bg_color": Color(0.4, 0.15, 0.1),
		"accent": Color(1.0, 0.4, 0.1),
		"weapon_pool": ["flame", "rocket", "tesla", "drill", "minigun"],
		"chassis_pool": ["medium", "heavy"],
		"terrain": [
			{"shape": "circle", "pos": Vector2(600, 390), "radius": 52, "color": Color(0.45, 0.22, 0.15)},
			{"shape": "circle", "pos": Vector2(720, 470), "radius": 38, "color": Color(0.5, 0.25, 0.12)},
			{"shape": "rect", "pos": Vector2(640, 280), "size": Vector2(90, 55), "color": Color(0.42, 0.2, 0.14)},
			{"shape": "rect", "pos": Vector2(480, 540), "size": Vector2(70, 45), "color": Color(0.4, 0.18, 0.12)},
		],
		"boss": {
			"name": "Magma Golem",
			"hp": 800,
			"damage_mult": 1.4,
			"speed": 60,
			"weapons": ["flame", "mortar", "drill"],
			"color": Color(0.9, 0.3, 0.1),
			"size": 2.2,
		},
	},
	{
		"id": 3,
		"name": "Ice Citadel",
		"description": "Frozen fortress with slippery floors.",
		"trophy_required": 200,
		"gem_reward_win": 35,
		"gem_reward_boss": 280,
		"bg_color": Color(0.6, 0.75, 0.85),
		"accent": Color(0.3, 0.6, 0.9),
		"weapon_pool": ["freeze", "laser", "plasma", "missile", "boomerang"],
		"chassis_pool": ["light", "medium", "stealth"],
		"terrain": [
			{"shape": "rect", "pos": Vector2(640, 360), "size": Vector2(50, 130), "color": Color(0.72, 0.86, 0.95)},
			{"shape": "rect", "pos": Vector2(520, 430), "size": Vector2(45, 100), "color": Color(0.68, 0.82, 0.92)},
			{"shape": "rect", "pos": Vector2(760, 300), "size": Vector2(45, 100), "color": Color(0.68, 0.82, 0.92)},
			{"shape": "circle", "pos": Vector2(400, 500), "radius": 42, "color": Color(0.7, 0.85, 0.98)},
		],
		"boss": {
			"name": "Frost Queen",
			"hp": 750,
			"damage_mult": 1.35,
			"speed": 100,
			"weapons": ["freeze", "laser", "missile"],
			"color": Color(0.7, 0.85, 1.0),
			"size": 1.7,
		},
	},
	{
		"id": 4,
		"name": "Toxic Swamp",
		"description": "Acid pools and poisonous fumes.",
		"trophy_required": 300,
		"gem_reward_win": 42,
		"gem_reward_boss": 350,
		"bg_color": Color(0.2, 0.35, 0.15),
		"accent": Color(0.4, 0.9, 0.2),
		"weapon_pool": ["poison", "railgun", "shield_gen", "shotgun", "tesla"],
		"chassis_pool": ["medium", "heavy", "titan"],
		"terrain": [
			{"shape": "circle", "pos": Vector2(300, 590), "radius": 65, "color": Color(0.25, 0.7, 0.18)},
			{"shape": "circle", "pos": Vector2(900, 560), "radius": 80, "color": Color(0.22, 0.65, 0.16)},
			{"shape": "circle", "pos": Vector2(640, 630), "radius": 50, "color": Color(0.2, 0.6, 0.14)},
			{"shape": "rect", "pos": Vector2(640, 340), "size": Vector2(70, 70), "color": Color(0.28, 0.55, 0.2)},
		],
		"boss": {
			"name": "Plague Hound",
			"hp": 900,
			"damage_mult": 1.5,
			"speed": 130,
			"weapons": ["poison", "railgun", "saw"],
			"color": Color(0.3, 0.6, 0.2),
			"size": 1.9,
		},
	},
	{
		"id": 5,
		"name": "Neon City",
		"description": "Cyberpunk streets glow with neon lights.",
		"trophy_required": 420,
		"gem_reward_win": 50,
		"gem_reward_boss": 450,
		"bg_color": Color(0.1, 0.08, 0.18),
		"accent": Color(1.0, 0.0, 0.8),
		"weapon_pool": ["emp", "mortar", "plasma", "photon", "laser"],
		"chassis_pool": ["stealth", "medium", "heavy"],
		"terrain": [
			{"shape": "rect", "pos": Vector2(100, 360), "size": Vector2(35, 220), "color": Color(0.15, 0.12, 0.28)},
			{"shape": "rect", "pos": Vector2(1180, 360), "size": Vector2(35, 220), "color": Color(0.15, 0.12, 0.28)},
			{"shape": "rect", "pos": Vector2(640, 400), "size": Vector2(160, 40), "color": Color(0.18, 0.1, 0.32)},
			{"shape": "rect", "pos": Vector2(500, 280), "size": Vector2(40, 90), "color": Color(0.14, 0.1, 0.26)},
			{"shape": "rect", "pos": Vector2(780, 500), "size": Vector2(40, 90), "color": Color(0.14, 0.1, 0.26)},
		],
		"boss": {
			"name": "Cyber Overlord",
			"hp": 1000,
			"damage_mult": 1.55,
			"speed": 110,
			"weapons": ["emp", "photon", "plasma"],
			"color": Color(0.8, 0.1, 0.9),
			"size": 2.1,
		},
	},
	{
		"id": 6,
		"name": "Space Station",
		"description": "Zero-gravity combat in orbit.",
		"trophy_required": 550,
		"gem_reward_win": 60,
		"gem_reward_boss": 550,
		"bg_color": Color(0.05, 0.05, 0.12),
		"accent": Color(0.5, 0.7, 1.0),
		"weapon_pool": ["gravity", "photon", "missile", "railgun", "shield_gen"],
		"chassis_pool": ["light", "stealth", "titan"],
		"terrain": [
			{"shape": "rect", "pos": Vector2(640, 380), "size": Vector2(110, 80), "color": Color(0.22, 0.28, 0.42)},
			{"shape": "rect", "pos": Vector2(480, 300), "size": Vector2(65, 65), "color": Color(0.2, 0.26, 0.4)},
			{"shape": "rect", "pos": Vector2(800, 480), "size": Vector2(65, 65), "color": Color(0.2, 0.26, 0.4)},
			{"shape": "rect", "pos": Vector2(560, 540), "size": Vector2(50, 50), "color": Color(0.18, 0.24, 0.38)},
		],
		"boss": {
			"name": "Orbital Destroyer",
			"hp": 1200,
			"damage_mult": 1.6,
			"speed": 85,
			"weapons": ["gravity", "railgun", "missile"],
			"color": Color(0.3, 0.4, 0.7),
			"size": 2.4,
		},
	},
	{
		"id": 7,
		"name": "Ancient Ruins",
		"description": "Crumbling temples hold forgotten power.",
		"trophy_required": 700,
		"gem_reward_win": 75,
		"gem_reward_boss": 700,
		"bg_color": Color(0.35, 0.3, 0.22),
		"accent": Color(0.9, 0.75, 0.3),
		"weapon_pool": ["vortex", "boomerang", "plasma", "tesla", "mortar"],
		"chassis_pool": ["heavy", "titan", "medium"],
		"terrain": [
			{"shape": "rect", "pos": Vector2(100, 380), "size": Vector2(28, 150), "color": Color(0.52, 0.47, 0.4)},
			{"shape": "rect", "pos": Vector2(1160, 400), "size": Vector2(28, 150), "color": Color(0.52, 0.47, 0.4)},
			{"shape": "rect", "pos": Vector2(640, 320), "size": Vector2(80, 120), "color": Color(0.5, 0.45, 0.38)},
			{"shape": "rect", "pos": Vector2(520, 480), "size": Vector2(50, 80), "color": Color(0.48, 0.43, 0.36)},
			{"shape": "rect", "pos": Vector2(760, 480), "size": Vector2(50, 80), "color": Color(0.48, 0.43, 0.36)},
		],
		"boss": {
			"name": "Stone Colossus",
			"hp": 1500,
			"damage_mult": 1.8,
			"speed": 50,
			"weapons": ["vortex", "mortar", "railgun"],
			"color": Color(0.6, 0.55, 0.45),
			"size": 2.6,
		},
	},
	{
		"id": 8,
		"name": "Void Nexus",
		"description": "The final arena at the edge of reality.",
		"trophy_required": 900,
		"gem_reward_win": 100,
		"gem_reward_boss": 1000,
		"bg_color": Color(0.08, 0.02, 0.12),
		"accent": Color(0.7, 0.0, 1.0),
		"weapon_pool": ["vortex", "gravity", "emp", "photon", "railgun", "plasma"],
		"chassis_pool": ["titan", "stealth", "heavy"],
		"terrain": [
			{"shape": "circle", "pos": Vector2(640, 400), "radius": 70, "color": Color(0.25, 0.05, 0.38)},
			{"shape": "rect", "pos": Vector2(500, 300), "size": Vector2(45, 110), "color": Color(0.2, 0.02, 0.32)},
			{"shape": "rect", "pos": Vector2(780, 300), "size": Vector2(45, 110), "color": Color(0.2, 0.02, 0.32)},
			{"shape": "rect", "pos": Vector2(640, 540), "size": Vector2(100, 45), "color": Color(0.22, 0.04, 0.35)},
		],
		"boss": {
			"name": "Void Emperor",
			"hp": 2000,
			"damage_mult": 2.0,
			"speed": 95,
			"weapons": ["vortex", "gravity", "photon", "emp"],
			"color": Color(0.3, 0.0, 0.5),
			"size": 2.8,
		},
	},
]

const GEM_PACKS: Array[Dictionary] = [
	{"gems": 100, "cost_trophies": 0, "label": "Daily Bonus", "daily": true},
	{"gems": 250, "cost_trophies": 0, "label": "Battle Pass Reward", "battle_pass": true},
	{"gems": 500, "cost_trophies": 30, "label": "Gem Cache"},
	{"gems": 1200, "cost_trophies": 70, "label": "Gem Vault"},
	{"gems": 3000, "cost_trophies": 150, "label": "Gem Treasury"},
]

const STARTING_GEMS := 150
const STARTING_WEAPON := "minigun"
const STARTING_CHASSIS := "light"
const MAX_WEAPON_SLOTS := 3


func get_chassis_weapon_slots(chassis_id: String) -> int:
	var slots: int = get_chassis(chassis_id).get("weapon_slots", 1)
	return clampi(slots, 1, MAX_WEAPON_SLOTS)


func trim_weapons_for_chassis(weapons: Array, chassis_id: String) -> Array[String]:
	var result: Array[String] = []
	var max_slots := get_chassis_weapon_slots(chassis_id)
	for w in weapons:
		var wid := str(w)
		if wid.is_empty() or get_weapon(wid).is_empty():
			continue
		if wid not in result:
			result.append(wid)
		if result.size() >= max_slots:
			break
	if result.is_empty():
		result.append(STARTING_WEAPON)
	return result


func get_weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, {})


func get_chassis(id: String) -> Dictionary:
	return CHASSIS.get(id, {})


func get_arena(arena_id: int) -> Dictionary:
	if arena_id >= 0 and arena_id < ARENAS.size() and ARENAS[arena_id].get("id", arena_id) == arena_id:
		return ARENAS[arena_id]
	for arena in ARENAS:
		if arena.get("id", -1) == arena_id:
			return arena
	return {}


func get_unlocked_arenas(bosses_beaten: Array) -> Array[int]:
	var result: Array[int] = []
	for arena in ARENAS:
		var arena_id: int = int(arena.get("id", -1))
		if is_arena_unlocked(arena_id, bosses_beaten):
			result.append(arena_id)
	return result


func is_arena_unlocked(arena_id: int, bosses_beaten: Array) -> bool:
	if arena_id <= 0:
		return true
	for entry in bosses_beaten:
		if int(entry) == arena_id - 1:
			return true
	return false


func get_arena_unlock_requirement(arena_id: int) -> String:
	if arena_id <= 0:
		return ""
	var prev := get_arena(arena_id - 1)
	if prev.is_empty():
		return "Defeat the previous arena boss to unlock."
	var boss_name: String = str(prev.get("boss", {}).get("name", "Boss"))
	var arena_name: String = str(prev.get("name", "the previous arena"))
	return "Defeat %s in %s to unlock." % [boss_name, arena_name]


func random_ai_loadout(arena_id: int, difficulty: float = 1.0) -> Dictionary:
	var arena := get_arena(arena_id)
	if arena.is_empty():
		return {"chassis": "light", "weapons": ["minigun"]}
	var chassis_pool: Array = arena.get("chassis_pool", ["light"])
	var weapon_pool: Array = arena.get("weapon_pool", ["minigun"])
	var chassis_id: String = chassis_pool[randi() % chassis_pool.size()]
	var max_slots := get_chassis_weapon_slots(chassis_id)
	var weapons: Array[String] = []
	var slot_count := mini(randi_range(1, max_slots), weapon_pool.size())
	var shuffled := weapon_pool.duplicate()
	shuffled.shuffle()
	for i in slot_count:
		weapons.append(shuffled[i])
	return {"chassis": chassis_id, "weapons": weapons, "difficulty": difficulty}
