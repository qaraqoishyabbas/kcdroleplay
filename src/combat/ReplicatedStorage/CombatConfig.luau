-- Medieval combat tuning. All numbers live here; nothing else in the project hardcodes damage.
local Config = {}

Config.Version = "combat 1.1"
Config.ModelName = "TrainingYard"

Config.Player = { MaxHealth = 100, RespawnTime = 4, StartGold = 200 }

Config.Gold = { DummyReward = 2, DummyCooldown = 0.4 }

Config.Shop = {
	{ Id = "Sword", Kind = "Weapon", Price = 40 },
	{ Id = "Axe", Kind = "Weapon", Price = 70 },
	{ Id = "Spear", Kind = "Weapon", Price = 35 },
	{ Id = "Bow", Kind = "Weapon", Price = 55 },
	{ Id = "Shield", Kind = "Shield", Price = 30 },
	{ Id = "Helmet", Kind = "Armor", Price = 25 },
	{ Id = "Cuirass", Kind = "Armor", Price = 60 },
	{ Id = "Greaves", Kind = "Armor", Price = 20 },
}

Config.Movement = { Walk = 22 }

Config.Stamina = { Max = 100, Regen = 16, RegenDelay = 0.7, GuardBreak = 1.4 }

Config.Block = {
	Arc = 110, -- degrees of the frontal block cone with a weapon
	ShieldArc = 150, -- wider with a shield
	StaminaPerHit = 10,
	ShieldStaminaPerHit = 6,
	MoveMultiplier = 0.55,
}

Config.Directions = {
	Left = { Name = "слева", Damage = 1.0, Arc = 100, Windup = 0 },
	Right = { Name = "справа", Damage = 1.0, Arc = 100, Windup = 0 },
	Overhead = { Name = "сверху", Damage = 1.15, Arc = 70, Windup = 0.06 },
	Stab = { Name = "укол", Damage = 1.15, Arc = 38, Windup = -0.04, ArmorPierce = 0.5 },
}

Config.Weapons = {
	{
		Id = "Sword", Name = "Короткий меч", Kind = "Melee",
		Damage = 26, Windup = 0.22, Cooldown = 0.85, Reach = 4.4, Arc = 100, Stamina = 12,
	},
	{
		Id = "Axe", Name = "Боевой топор", Kind = "Melee",
		Damage = 36, Windup = 0.34, Cooldown = 1.15, Reach = 3.8, Arc = 90, Stamina = 18,
	},
	{
		Id = "Spear", Name = "Копьё", Kind = "Melee",
		Damage = 20, Windup = 0.18, Cooldown = 0.9, Reach = 6.4, Arc = 42, Stamina = 10,
	},
	{
		Id = "Bow", Name = "Лук", Kind = "Bow",
		DrawMin = 0.35, DrawMax = 1.2, DamageMin = 12, DamageMax = 40, SpeedMin = 110, SpeedMax = 175,
	},
	{ Id = "Shield", Name = "Щит", Kind = "Shield" },
}

Config.Arrow = { Lifetime = 6, Step = 0.04, Radius = 0.6, StickTime = 4 }

Config.Bow = { StaminaCost = 6, MinInterval = 0.35 }

Config.Armor = {
	{
		Id = "Helmet", Name = "Шлем", Reduction = 0.12, Part = "Head",
		Size = Vector3.new(1.5, 1.2, 1.5), Offset = CFrame.new(0, 0.25, 0),
	},
	{
		Id = "Cuirass", Name = "Кираса", Reduction = 0.22, Part = "UpperTorso",
		Size = Vector3.new(2.3, 2.2, 1.3), Offset = CFrame.new(0, 0, 0),
	},
	{
		Id = "Greaves", Name = "Поножи", Reduction = 0.1, Part = "LowerTorso",
		Size = Vector3.new(2.1, 1.8, 1.2), Offset = CFrame.new(0, 0, 0),
	},
}

Config.ArmorCap = 0.55

-- Grey placeholder look for every weapon and armor piece.
Config.Grey = {
	Color = Color3.fromRGB(126, 130, 134),
	Dark = Color3.fromRGB(92, 96, 100),
	Material = Enum.Material.Metal,
}

Config.WeaponModels = {
	Sword = {
		{ Name = "Blade", Size = Vector3.new(0.18, 3.0, 0.55), Offset = CFrame.new(0, -1.9, 0), Color = "Grey" },
		{ Name = "Guard", Size = Vector3.new(1.1, 0.16, 0.3), Offset = CFrame.new(0, -0.38, 0), Color = "Dark" },
		{ Name = "Grip", Size = Vector3.new(0.22, 0.7, 0.22), Offset = CFrame.new(0, 0, 0), Color = "Dark" },
	},
	Axe = {
		{ Name = "Shaft", Size = Vector3.new(0.22, 3.2, 0.22), Offset = CFrame.new(0, -1.5, 0), Color = "Dark" },
		{ Name = "Head", Size = Vector3.new(0.2, 1.1, 1.3), Offset = CFrame.new(0, -2.6, 0.35), Color = "Grey" },
	},
	Spear = {
		{ Name = "Shaft", Size = Vector3.new(0.16, 6.0, 0.16), Offset = CFrame.new(0, -3.0, 0), Color = "Dark" },
		{ Name = "Tip", Size = Vector3.new(0.22, 0.9, 0.22), Offset = CFrame.new(0, -6.1, 0), Color = "Grey" },
	},
	Bow = {
		{ Name = "LimbTop", Size = Vector3.new(0.16, 1.6, 0.16), Offset = CFrame.new(0, 0.7, 0.1) * CFrame.Angles(math.rad(-18), 0, 0), Color = "Dark" },
		{ Name = "LimbBottom", Size = Vector3.new(0.16, 1.6, 0.16), Offset = CFrame.new(0, -0.7, 0.1) * CFrame.Angles(math.rad(18), 0, 0), Color = "Dark" },
		{ Name = "Grip", Size = Vector3.new(0.24, 0.7, 0.24), Offset = CFrame.new(0, 0, 0.16), Color = "Grey" },
	},
	Shield = {
		{ Name = "Board", Size = Vector3.new(0.18, 2.4, 1.6), Offset = CFrame.new(0, 0, 0.2), Color = "Grey" },
		{ Name = "Boss", Size = Vector3.new(0.3, 0.7, 0.7), Offset = CFrame.new(0, 0, -0.1), Color = "Dark" },
	},
}

return Config
