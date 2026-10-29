# Проверки без запуска игры

Нужны Python 3.11+ и официальный [Luau CLI](https://github.com/luau-lang/luau/releases). Положите `luau` и `luau-compile` в PATH или задайте путь к их папке:

```powershell
$env:LUAU_CLI_DIR = 'C:\tools\luau'
python tests/offline/run.py
```

Скрипт компилирует активные исходники, выполняет 78 сценариев против настоящих модулей с локальным адаптером Roblox API, проверяет соответствие установщика/плагина исходникам и имена Enum по официальному справочнику Roblox. Для первой загрузки справочника требуется интернет. Логи и JSON-результаты сохраняются в игнорируемой Git папке `test-results/offline`.

Это проверка логики, а не замер FPS и не сетевая/физическая сессия. Проверки настоящих Instance выполняются отдельно в edit mode Studio: `tests/style-main-edit.luau`, `tests/map-edit.luau` и `tests/combat-edit.luau`. Зафиксированный результат проверки сохранённого места: `docs/style-main-verification.log`.
