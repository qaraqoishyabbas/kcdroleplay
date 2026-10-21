# CROWNLANDS: Medieval Life

Рабочий локальный прототип в `kcdroleplay.rbxl`. Мир и исходники установлены в Roblox Studio. Это поэтапная разработка, **не завершённая RPG из всех восьми этапов**. В текущей версии нет постоянных сохранений: инвентарь, Gold, одежда и выполненный заказ живут до выхода с сервера.

## Запуск

1. Откройте `kcdroleplay.rbxl` в Roblox Studio.
2. Test → Start Test Session → Test.
3. Дождитесь «Мир готов», выберите один из трёх вариантов одежды, нажмите Play.
4. WASD / стик — движение, Space — прыжок, Shift / кнопка «Бег» — бег.
5. E / встроенная сенсорная кнопка ProximityPrompt — взаимодействие. I / кнопка «Инвентарь» — инвентарь.
6. Соберите 3 древесины и 2 руды у западной дороги, затем поговорите с кузнецом. Заказ выдаёт 12 Gold один раз. Мирек на площади покупает и продаёт товары. Хлеб восстанавливает здоровье.
7. За мостом на востоке — тренировочный двор. Возьмите учебный меч и щит у стойки. ЛКМ / R2 — удар, R / Y — тяжёлый удар, F / L2 — удержание блока, Q / B — уклонение. Первые 0,25 секунды блока — окно парирования. Во время задержки между ударами атаковать повторно нельзя.
8. Учебный противник восстанавливается через 12 секунд после смерти. Разбойники находятся севернее фермы. После смерти игрок возвращается в деревню.

Имя персонажа берётся из Roblox DisplayName. Свободный ввод имени не добавлен, поэтому дополнительная фильтрация пользовательского текста не требуется. Внешность собрана стандартными цветами частей тела без сторонних моделей и одежды.

## Структура и исходники

`src/` повторяет Explorer. `.server.luau` означает **Script**, `.client.luau` — **LocalScript**, прочие `.luau` — **ModuleScript**. Суффиксы расширений не входят в имена объектов Explorer. Точная машинная таблица путей: `docs/source-manifest.json`.

| Explorer | Тип | Назначение и зависимости | Проверка / диагностика |
|---|---|---|---|
| ReplicatedStorage/Shared/Config | ModuleScript | Название, параметры бега, пресеты, обучение | edit-acceptance; неверные пресеты отклоняются сервером |
| ReplicatedStorage/Shared/UtilityModules | ModuleScript | Проверка персонажа, расстояния, чисел, безопасной зоны, частоты | edit-acceptance; NaN, бесконечность и спам отклоняются |
| ReplicatedStorage/Shared/WeaponDefinitions | ModuleScript | Урон, стоимость, дальность, задержка и вес меча | play-server; менять баланс здесь |
| ReplicatedStorage/Shared/ItemDefinitions | ModuleScript | ID, названия, категории, иконки, описания, вес, цены | economy-server; отсутствующие ID не принимаются |
| ServerScriptService/Bootstrap | Script | Запуск сервисов, ограниченный по частоте heartbeat и время суток | Output: CROWNLANDS_SERVER_READY; если отсутствует — проверить установку |
| ServerScriptService/Services/PlayerStateService | ModuleScript | Сессионный профиль, Play, одежда, спавн, серверная выносливость | play-server; меню без ответа означает проблему Bootstrap / Remotes |
| ServerScriptService/Services/InteractionService | ModuleScript | Проверка ProximityPrompt, колодец, отдых, NPC, сбор, первый заказ | economy-server; подойти ближе 13 studs, держать E |
| ServerScriptService/Services/CombatService | ModuleScript | Серверные атаки, луч видимости, блок, парирование, уклонение, экипировка, простой NPC AI | play-server; сначала взять оружие на стойке; NPC агрессивны вне безопасной зоны |
| ServerScriptService/Services/InventoryService | ModuleScript | Не уступающие управление транзакции предметов и Gold; еда, снятие, вес | economy-server; 30 кг — замедление, 45 кг — жёсткий предел |
| ServerScriptService/Services/EconomyService | ModuleScript | NPC-покупки и продажи, серверные цены и дистанция | economy-server; для торговли стоять рядом с Миреком |
| StarterPlayer/StarterPlayerScripts/ClientBootstrap | LocalScript | Запуск клиентских контроллеров | Output: CROWNLANDS_CLIENT_READY; если нет — проверить PlayerScripts |
| StarterPlayer/StarterPlayerScripts/Controllers/UIController | ModuleScript | Меню, HUD, обучение, диалог, уведомления, экран смерти | Вход через Play; HUD должен восстановиться после смерти |
| StarterPlayer/StarterPlayerScripts/Controllers/InputController | ModuleScript | Клавиатура, геймпад, сенсорный бег, сброс при потере фокуса | Shift; серверный расход проверяет фактическую скорость |
| StarterPlayer/StarterPlayerScripts/Controllers/CombatController | ModuleScript | Ввод боя и локальные процедурные движения рук / эффекты | После выдачи оружия проверить ЛКМ/R/F/Q; нужны Motor6D стандартного R6/R15 |
| StarterPlayer/StarterPlayerScripts/Controllers/TouchControls | ModuleScript | Сенсорные кнопки в HUD, удержание и отпускание блока/бега | Телефонный эмулятор; сетка выше стандартного прыжка |
| StarterPlayer/StarterPlayerScripts/Controllers/InventoryController | ModuleScript | Инвентарь, категории, вес, торговля, цель первого заказа | I, выбор категории, еда и экипировка; UI обновляется серверными снимками |

Remotes: `ReplicatedStorage/Remotes/{InteractionRemote,UIUpdateRemote,CombatRemote,InventoryRemote,TradeRemote}` — **RemoteEvent**. Клиент не передаёт урон, цену или размер награды. Папки `ServerStorage/{NPCModels,ItemModels,WeaponModels,WorldTemplates}` созданы для следующих этапов; пока модели оружия создаёт CombatService, NPC — сборщик мира.

ScreenGui: `StarterGui/{MainMenu,HUD,DialogueUI,InventoryUI,TradeUI}`. `ResetOnSpawn=false`; содержимое создают контроллеры. Не удаляйте GUI во время Play.

Workspace: `Map/CrownlandsPrototype` — сгенерированный мир; `Map/MedievalClearing` — сохранённая исходная поляна; `NPCs` — шесть мирных NPC, два разбойника, учебный противник; `InteractionPoints/Crownlands` — проверяемые сервером точки; `SafeZones/Village` — маркер зоны. `NPCSpawns`, `ResourceNodes`, `EnemySpawns` зарезервированы папками, работающие ресурсные декорации сейчас находятся в `Map/CrownlandsPrototype/ResourceOutcrops`.

## Повторная сборка из исходников

Уже установленную карту повторно собирать для обычного запуска не нужно.

1. После правок файлов выполните `python3 tools/package.py`. Генератор использует только стандартную библиотеку Python.
2. Остановите Play в Studio.
3. Вставьте весь `install-crownlands.luau` в Command Bar и выполните ⌘Enter. Ожидается `CROWN_INSTALL_OK 16 source files`.
4. Для пересборки геометрии выполните весь `tools/build-world.luau` в Command Bar. Меняется только сгенерированный мир Crownlands; существующая поляна сохраняется. NPC и точки взаимодействия обновляются. Ожидается `CROWN_WORLD_OK`.
5. File → Save to File. Запустите Test заново: изменение ModuleScript во время Play не заменяет уже загруженный модуль.

StreamingEnabled включается в edit-time сборщике. Радиусы стриминга — стандартные, эти свойства Roblox помечены Not Scriptable; при необходимости меняйте их в Properties. Никаких изменений разрешений Roblox и публикации установщик не выполняет.

## Проверки

- `tests/edit-acceptance.luau` — вставить в Command Bar в edit mode: структура, загрузка модулей, карта, единственный спавн, безопасная зона, защита от NaN / бесконечности / спама, дистанция, направление и стена для удара.
- `tests/play-server.luau` — временный **Script** `ServerScriptService/CrownAcceptance` во время Play ПОСЛЕ входа через игровую кнопку Play. Проверяет серверный стартовый профиль, повторный Play, выносливость, выдачу оружия, урон, задержки, блок, уклонение, смерть и возрождение. Скрипт сам удаляется при успехе.
- `tests/economy-server.luau` — временный **Script** на сервере после предыдущего теста в той же сессии: дальние запросы, сбор, таймер ресурса, одноразовый заказ, покупка/продажа, некорректные числа, недостаток денег, целостность транзакций, вес, еда и продажа оружия.

Тесты меняют только тестовую сессию. Остановите Play после проверок. Command Bar и обычные Script могут использовать разные кэши require, поэтому тесты сессионного состояния выполняются именно обычными серверными Script.

## Подтверждённые результаты

На локальной сборке проверены 51 утверждение edit-mode, затем 23 проверки игрового сервера и 20 проверок экономики. `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)` завершился `CROWN_MULTIPLAYER_ALL_PASS`: два клиента подтвердили HUD, видимость обоих персонажей, мечей/щитов и 16 боевых событий каждый. Сервер подтвердил отсутствие урона в безопасной зоне и 12 урона за её пределами. Выдержки Output: `docs/verification.log`.

В логах отдельных клиентов были сообщения Roblox о таймауте загрузки beta features / installed plugins из облака. Приёмочные сценарии игры завершились успешно; это не основание утверждать, что во всём Output нет сообщений об ошибках.

Для повторения мультиплеерного теста вставьте `tests/run-multiplayer-command.luau` в Command Bar в edit mode. Временные Script/LocalScript/RemoteEvent устанавливаются только для теста. После его завершения удалите `ServerScriptService/CrownMultiplayerAcceptance`, `StarterPlayer/StarterPlayerScripts/CrownMultiplayerClient` и `ReplicatedStorage/CrownTestReport` перед сохранением. В поставляемой карте эти объекты удалены.

Телефонный эмулятор iPhone 13, горизонтальный экран 844×390: пройдена проверка пяти сенсорных кнопок (минимум 44×44, без пересечений друг с другом, прыжком и обучением). Инвентарь проверен визуально и по координатам; слои окон выше HUD. Это проверка эмулятора, не реального телефона. Скрипт: `tests/phone-client.luau`, превью: `docs/phone-inventory.png`.

## Границы текущего результата

Это основа и первый игровой цикл, а не готовность по всем 15 сценариям исходного задания. Ещё нужны полноценные профессии и крафт/ремонт, четыре оставшихся задания, закон/тюрьма, постоянные профили DataStore, безопасная долговечная торговля между игроками, группы и общие события. Перед включением реальных сохранений нужен отдельный опубликованный тестовый place и проверка ошибки загрузки, сессий и повторного входа. Пустыми обработчиками эти системы не заменены.

Боевые движения сейчас процедурные; кастомные анимации, звуки боя/окружения и детализированная одежда — последующая полировка. Случайные asset ID не добавлены. Производительность на 12–20 игроках и реальные мобильные устройства не подтверждены без соответствующего теста.

Исходные требования: `docs/requirements.ru.txt`. План: `docs/superpowers/plans/2026-10-20-crownlands.md`. Резервная копия до расширения: `backups/kcdroleplay-before-crownlands.rbxl`.
