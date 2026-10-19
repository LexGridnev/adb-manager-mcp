# 📱 Полная инструкция: ADB Manager MCP v2.0 + ZeroG (`0g`)

Руководство по использованию связки **[ZeroG (`0g`)](https://github.com/LexGridnev/zerog-termux)** и **[ADB Manager MCP v2.0](https://github.com/LexGridnev/adb-manager-mcp)** на смартфонах Android 11–15 (Xiaomi POCO / HyperOS, Samsung OneUI, Pixel).

---

## 🇷🇺 ЧАСТЬ 1: Пошаговая инструкция (RU)

### 1. Зачем нужна эта связка?
* **`ZeroG (0g)`** — управляет процессами Termux, защищает ИИ-агента от сна CPU, даёт веб-панель (`:8080`), нативный GitHub-клиент (`0g gh`) и системный MCP-сервер (`poco-mcp`).
* **`ADB Manager MCP v2.0`** — даёт ИИ-агенту права системного пользователя `shell` через локальную **Беспроводную отладку (Wireless Debugging)** без компьютера и без Root-прав, а также **навсегда снимает лимит Android в 32 фоновых процесса (Phantom Process Killer)**!

---

### 2. Быстрая установка в Termux

Если пакет `adb` (`android-tools`) ещё не установлен, установите его одной командой:
```bash
DEBIAN_FRONTEND=noninteractive apt-get -y install android-tools quickjs-ng
```

Установите `adb-manager-mcp` (если ещё не установлен):
```bash
cd ~/adb-manager-mcp && ./install.sh
```
После этого в любой папке Termux станут доступны 3 команды:
* `adb-activate` — подключение телефона к самому себе в 1 клик.
* `adb-manager` — интерактивное меню управления (TUI).
* `adb-mcp` — нативный QuickJS MCP-сервер (3 МБ RAM).

---

### 3. Первичное сопряжение (Connect to Self без ПК и без Root)

Делается **один раз**:

1. **Включите режим разработчика и Беспроводную отладку:**
   - Откройте **Настройки -> О телефоне** и нажмите 7 раз на **Версию ОС (HyperOS / Номер сборки)**.
   - Перейдите в **Настройки -> Расширенные настройки -> Для разработчиков**.
   - Включите **Отладка по USB** и **Беспроводная отладка (Wireless debugging)** (и на Xiaomi/POCO включите **Отладка по USB (Настройки безопасности)**).
2. **Разделите экран (Split Screen) или откройте плавающее окно:**
   - Сверху оставьте окно **Беспроводная отладка**, снизу — **Termux**.
3. **Сопряжение (Pairing):**
   - В настройках нажмите **«Подключение устройства с помощью кода сопряжения» (Pair device with pairing code)**. Вы увидите IP:Порт (например, `192.168.1.50:39123`) и **6-значный код**.
   - В Termux выполните:
     ```bash
     ~/adb-manager-mcp/bin/smart-connect.sh connect 192.168.1.50:39123 123456
     ```
     *(или просто запустите `adb-activate` и введите код в появившемся окне).*
4. **Автоподключение в будущем:**
   - После первого сопряжения достаточно в любой момент набрать:
     ```bash
     adb-activate
     ```
     Скрипт сам найдёт динамический порт через `adb mdns services` за 0.1 секунды и подключится!

> 💡 **Лайфхак без Wi-Fi (в дороге):** Если вокруг нет Wi-Fi сети, включите **Точку доступа (Hotspot)** или откройте настройки **Wi-Fi Direct** (`~/adb-manager-mcp/bin/smart-connect.sh prepare-hotspot`), и Android разрешит включить Беспроводную отладку прямо на мобильном интернете!

---

### 4. Снятие лимита 32 процессов Android (Phantom Process Killer) без Root

Как только `adb-activate` показал `✅ Connected`, выполните:
```bash
adb-activate --unlock-phantom
```
Эта команда через `adb shell device_config` увеличит лимит `max_phantom_processes` с `32` до `2147483647` и отключит мониторинг фантомных процессов. Теперь Android не будет убивать ваши фоновые задачи и субагентов `agy`!

---

### 5. Подключение `adb-manager-mcp` к ИИ-агенту (`agy` / Claude)

Выведите готовую конфигурацию:
```bash
~/adb-manager-mcp/mcp/config_helper.sh
```
Или добавьте сервер `adb-manager` в конфиг MCP:
```json
{
  "mcpServers": {
    "adb-manager": {
      "command": "/data/data/com.termux/files/home/adb-manager-mcp/mcp/start-mcp.sh",
      "args": []
    }
  }
}
```

### 6. Шпаргалка по всем командам (`0g` + `adb-manager`)

| Команда | Что делает |
| :--- | :--- |
| `0g card` | Красивый паспорт вашей мобильной AI-станции для скриншотов |
| `0g status` | Полная телеметрия памяти, Phantom-слотов и здоровья `agy` |
| `0g web` | Запуск офлайн PWA-панели управления в браузере (`127.0.0.1:8080`) |
| `0g gh repos` | Список ваших репозиториев на GitHub (без `git`) |
| `0g gh push <repo> <path>` | Выгрузка файла или папки на GitHub напрямую через REST API |
| `0g gh topics <repo> <tags>` | Установка SEO-тегов репозитория на GitHub |
| `0g gh release <repo> <tag>` | Публикация официального релиза на GitHub |
| `0g gh delete <repo> --yes` | Удаление ненужного репозитория на GitHub |
| `adb-activate` | Автоподключение телефона к самому себе по Wireless ADB |
| `adb-activate --unlock-phantom` | Снятие лимита в 32 процесса (Phantom Process Killer) без Root |
| `adb-manager` | Интерактивное TUI-меню управления приложениями, экраном и файлами |

---

## 🇬🇧 PART 2: English Reference Guide

### Architecture Overview (v2.0)
- **`mcp/start-mcp.sh`**: Universal Zero-Bloat MCP launcher (automatically runs `qjs -m mcp/server.js` in 3 MB RAM, or falls back to `python3 mcp/server.py`).
- **`mcp/server.js`**: Native QuickJS JSON-RPC 2.0 MCP server exposing 25 tools.
- **`bin/smart-connect.sh`**: Non-interactive CLI orchestrator (`status`, `prepare-hotspot`, `prepare-wifi-direct`, `open-wireless`, `connect`, `unlock-phantom`).
- **`lib/adb_core.sh`**: Shared library with Android 11–15 `adb mdns services` auto-discovery and `unlock_phantom_processes`.

### Running Automated Tests
```bash
~/adb-manager-mcp/tests/test_core.sh
qjs -m ~/adb-manager-mcp/tests/test_mcp_qjs.js
~/adb-manager-mcp/tests/system_check.sh
```
