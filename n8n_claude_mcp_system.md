# Система автоматизированного анализа n8n workflow через Claude MCP

## 📋 Обзор проекта

Создана полнофункциональная система для автоматического анализа n8n workflow с использованием Claude Desktop и MCP (Model Context Protocol), обеспечивающая прямой доступ к production серверу n8n через безопасный SSH туннель.

## 🏗️ Архитектура системы

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐    ┌──────────────────┐
│   Claude Desktop │────│  Local MCP Server │────│   SSH Tunnel    │────│   GTC1 Server    │
│   (Frontend)    │    │   (n8n-mcp)      │    │  (Port 3333)    │    │  (PostgreSQL +   │
│                 │    │                  │    │                 │    │   n8n API)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘    └──────────────────┘
```

### Компоненты системы:

1. **Claude Desktop** - Пользовательский интерфейс для анализа
2. **Local MCP Server** - n8n-mcp сервер для работы с узлами и документацией
3. **SSH Tunnel** - Безопасное подключение к удаленному серверу
4. **GTC1 Server** - Production сервер с n8n и PostgreSQL

## 🛠️ Техническая конфигурация

### Локальная машина (Windows)
- **ОС**: Windows 11
- **Claude Desktop**: v0.12.55
- **Node.js**: v22.17.1
- **MCP Server**: n8n-mcp@2.10.2

### Удаленный сервер (GTC1)
- **ОС**: Ubuntu 22.04.5 LTS
- **Платформа**: Microsoft Azure
- **n8n**: v1.97.1
- **PostgreSQL**: 14+
- **Домен**: agent.gtstor.com
- **SSH доступ**: Ключ GTC1_key.pem

## 📂 Структура файлов

```
C:\Users\kfilipenko\
├── n8n_MSP_Agent\n8n-mcp\
│   ├── dist\mcp\index.js                    # Скомпилированный MCP сервер
│   ├── .env                                 # Конфигурация подключений
│   └── start-mcp-with-tunnel.bat           # Автозапуск скрипт
├── ssh\
│   └── GTC1_key.pem                        # SSH ключ для сервера
└── AppData\Roaming\Claude\
    └── claude_desktop_config.json          # Конфигурация Claude MCP
```

## ⚙️ Конфигурационные файлы

### 1. Claude Desktop Config
**Файл**: `C:\Users\kfilipenko\AppData\Roaming\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "C:\\Users\\kfilipenko\\n8n_MSP_Agent\\n8n-mcp\\start-mcp-with-tunnel.bat"
    }
  }
}
```

### 2. MCP Environment Config
**Файл**: `C:\Users\kfilipenko\n8n_MSP_Agent\n8n-mcp\.env`

```env
N8N_API_URL=https://agent.gtstor.com/api/v1
N8N_API_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
N8N_DB_TYPE=postgres
N8N_DB_HOST=localhost
N8N_DB_PORT=3333
N8N_DB_NAME=gtc_db
N8N_DB_USER=gtc_user
N8N_DB_PASSWORD=gtc_pass
```

### 3. Автозапуск скрипт
**Файл**: `C:\Users\kfilipenko\n8n_MSP_Agent\n8n-mcp\start-mcp-with-tunnel.bat`

```batch
@echo off
echo Checking for existing tunnel...
tasklist /fi "imagename eq ssh.exe" | findstr ssh >nul
if errorlevel 1 (
    echo Starting SSH tunnel...
    start "" ssh -i "C:\ssh\GTC1_key.pem" -L 3333:localhost:5432 -N -o ServerAliveInterval=60 kfilipenko@agent.gtstor.com
    timeout /t 3 /nobreak >nul
) else (
    echo SSH tunnel already running
)

echo Starting n8n MCP server...
node "C:\Users\kfilipenko\n8n_MSP_Agent\n8n-mcp\dist\mcp\index.js"
```

## 🔧 Процесс установки и настройки

### Этап 1: Подготовка инфраструктуры
1. ✅ Установка n8n MCP сервера локально
2. ✅ Настройка SSH ключей для доступа к GTC1
3. ✅ Конфигурация Claude Desktop

### Этап 2: Решение проблем подключения
**Проблема**: JSON парсинг ошибки в MCP подключении
**Решение**: 
- Исправление путей в claude_desktop_config.json
- Обновление MCP зависимостей
- Пересборка проекта

### Этап 3: Настройка SSH туннеля
**Проблема**: Ручное создание туннеля при каждом запуске
**Решение**: 
- Создание batch скрипта для автоматического запуска
- Интеграция в конфигурацию Claude MCP
- Проверка существующих туннелей

### Этап 4: Тестирование и валидация
1. ✅ Проверка автозапуска при старте Claude
2. ✅ Валидация SSH туннеля (порт 3333)
3. ✅ Тестирование MCP подключения
4. ✅ Анализ реального workflow с сервера

## 🎯 Функциональные возможности

### Автоматический анализ workflow
- **Получение структуры**: Прямой доступ к PostgreSQL базе n8n
- **Анализ узлов**: Детальное изучение конфигурации каждого узла
- **Валидация SQL**: Проверка сложных запросов и CTE
- **Документация**: Доступ к 532+ узлам n8n с полной документацией

### Инструменты MCP
- `n8n-mcp:get_database_statistics` - Статистика узлов
- `n8n-mcp:search_nodes` - Поиск узлов по ключевым словам
- `n8n-mcp:get_node_documentation` - Полная документация узлов
- `n8n-mcp:validate_workflow` - Валидация workflow
- И 35+ других инструментов

## 📊 Анализ производительности

### Показатели подключения
- **Время запуска**: ~3 секунды
- **SSH туннель**: Стабильное подключение с keepalive
- **MCP ответ**: <1 секунды для большинства запросов
- **База данных**: Прямое подключение к PostgreSQL

### Статистика данных
- **Общее количество узлов**: 532
- **AI-инструменты**: 267
- **Триггеры**: 108
- **Покрытие документацией**: 88%
- **Пакеты**: n8n-nodes-base (436), n8n-nodes-langchain (96)

## 🔒 Безопасность

### SSH подключение
- **Аутентификация**: Приватный ключ (GTC1_key.pem)
- **Туннелирование**: Локальный порт 3333 → удаленный 5432
- **Keepalive**: Автоматическое поддержание соединения
- **Ограничения**: Доступ только с локальной машины

### Данные и доступы
- **API ключ**: JWT токен с ограниченными правами
- **База данных**: Только чтение через туннель
- **Credentials**: Хранение в защищенных .env файлах

## 🚀 Практическое применение

### Успешно проанализированный workflow
**Название**: "Agent + sub WF V3 Corrected"  
**ID**: DyudoPlZcbk2CFK1  
**Узлы**: 4 (Telegram Trigger → PostgreSQL → Code → Execute Workflow)

### Выявленные особенности
1. **Сложный CTE запрос** с UPSERT логикой для пользователей
2. **Валидация данных** в JavaScript Code узле
3. **Асинхронный запуск** дочернего AI workflow
4. **Обработка ошибок** с retry механизмом

## 🔄 Процедуры обслуживания

### Ежедневные проверки
```powershell
# Проверка процессов
tasklist | findstr ssh
tasklist | findstr node

# Проверка туннеля
netstat -an | findstr 3333

# Тест MCP подключения
# (через Claude интерфейс)
```

### Устранение неполадок
1. **SSH туннель не работает**: Перезапуск Claude
2. **MCP ошибки**: Проверка .env конфигурации
3. **Медленная работа**: Проверка сетевого подключения к GTC1

## 📈 Перспективы развития

### Краткосрочные улучшения
- [ ] Добавление метрик производительности
- [ ] Расширенное логирование операций
- [ ] Backup конфигураций

### Долгосрочные планы
- [ ] Поддержка множественных серверов n8n
- [ ] Интеграция с системами мониторинга
- [ ] Автоматические отчеты по workflow

## 💡 Извлеченные уроки

### Технические инсайты
1. **MCP Protocol**: Мощный инструмент для интеграции AI с внешними системами
2. **SSH туннелирование**: Безопасный способ доступа к удаленным базам данных
3. **Batch автоматизация**: Простое решение для сложных задач запуска

### Процессы разработки
1. **Итеративный подход**: Пошаговое решение проблем
2. **Тестирование**: Важность проверки каждого этапа
3. **Документирование**: Критично для поддержки системы

## 📝 Контакты и поддержка

**Разработчик**: Konstantin Filipenko  
**Сервер**: GTC1 (agent.gtstor.com)  
**Дата создания**: Август 2025  
**Версия системы**: 1.0  

---

*Система успешно протестирована и готова к продуктивному использованию для анализа и оптимизации n8n workflow.*