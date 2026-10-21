return table.freeze({
    Title = "CROWNLANDS", Subtitle = "MEDIEVAL LIFE", Version = "0.3.0 • FOUNDATION / COMBAT / ITEMS",
    WalkSpeed = 14, SprintSpeed = 22, MaxStamina = 100,
    SprintDrain = 18, StaminaRegen = 13, RegenDelay = 1.2,
    InteractionDistance = 13, Spawn = Vector3.new(0, 5, 38),
    SafeCenter = Vector3.new(0,0,0), SafeRadius = 105,
    Presets = {
        {Name = "Лён и кожа", Color = Color3.fromRGB(126, 105, 73)},
        {Name = "Лесной путник", Color = Color3.fromRGB(77, 91, 59)},
        {Name = "Серый холст", Color = Color3.fromRGB(99, 103, 105)},
    },
    Tutorial = {
        "Добро пожаловать в Crownlands. Двигайтесь WASD или стиком. Осмотрите деревню.",
        "Shift / кнопка «Бег» — бег. Следите за выносливостью; отпустите кнопку для восстановления.",
        "Подойдите к колодцу и удерживайте E / кнопку взаимодействия. Вода восстанавливает здоровье.",
        "Загляните в таверну и на рынок. Для боя возьмите учебное оружие у тренировочной площадки.",
    },
})
