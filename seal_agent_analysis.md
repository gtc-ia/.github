# Анализ Workflow "@Seal agent" - GTC AI Purchasing Agent

## Общее описание

**@Seal agent** — это автоматизированный AI-агент для закупок, интегрированный с Telegram и базой данных PostgreSQL. Workflow реализует интеллектуального помощника по покупкам, который работает в двух этапах:

1. **Идентификация цели покупки** — помогает пользователю понять реальные потребности
2. **Поиск подходящего товара** — находит продукты на различных маркетплейсах

## Архитектура и поток данных

Workflow состоит из **13 узлов**, организованных в линейную последовательность с разветвлениями для AI-компонентов:

```
Telegram Trigger → RegisterOrFind User → [Save User Message1 + Get Chat History1] 
→ Prompt → AI Agent → SanitizeForTelegram → @Procurement_AnalystBot → Save Bot Response
```

## Детальный анализ узлов

### 1. **Telegram Trigger** (Entry Point)
- **Тип**: `n8n-nodes-base.telegramTrigger`
- **Функция**: Точка входа для входящих сообщений из Telegram
- **Конфигурация**: 
  - Прослушивает обновления типа "message"
  - Подключен к боту "@GTCProcureBot"
  - Webhook ID: `0f74bca6-798b-4042-8eaf-ca2d1f0e88ba`

### 2. **RegisterOrFind User** (User Management)
- **Тип**: `n8n-nodes-base.postgres`
- **Функция**: Регистрация нового пользователя или поиск существующего
- **SQL-логика**:
  ```sql
  WITH p AS (SELECT telegram_id, username, first_name, last_name),
  ins_user AS (INSERT INTO "user" ON CONFLICT DO NOTHING),
  upsert_auth AS (INSERT INTO auth_telegram ON CONFLICT UPDATE)
  SELECT user_id, gtc_user_id
  ```
- **Особенности**: 
  - Атомарная операция UPSERT
  - Автоматическое создание UUID для новых пользователей
  - Обновление метаданных при повторных обращениях

### 3. **Save User Message1** (Message Logging)
- **Тип**: `n8n-nodes-base.postgres`  
- **Функция**: Сохранение входящего сообщения пользователя в лог чата
- **Данные**: user_id, message text, session_id, timestamp, metadata (JSON)
- **Поддержка**: Текстовые сообщения, подписи к медиа, маркер "[non_text_message]"

### 4. **Get Chat History1** (Context Retrieval)
- **Тип**: `n8n-nodes-base.postgres`
- **Функция**: Извлечение последних 10 сообщений из истории чата
- **SQL**: `ORDER BY timestamp DESC LIMIT 10`
- **Цель**: Предоставление контекста для AI-агента

### 5. **Prompt** (Context Processing)
- **Тип**: `n8n-nodes-base.code` (JavaScript)
- **Функция**: Формирование промпта для AI-агента
- **Алгоритм**:
  1. Извлечение chat_id из метаданных
  2. Сортировка сообщений по времени
  3. Формирование диалоговой истории в формате "Пользователь: ... AI: ..."
  4. Подготовка контекстных данных

### 6. **AI Agent** (Core Intelligence)
- **Тип**: `@n8n/n8n-nodes-langchain.agent`
- **Функция**: Основной AI-агент с двухэтапной логикой
- **Конфигурация**:
  - Максимум 4 итерации
  - Возврат промежуточных шагов
  - Системный промпт на русском языке

#### Системный промпт (анализ):

**Этап 1 - Консультирование по потребностям:**
- Идентификация цели покупки
- Классификация по пирамиде Маслоу (5 уровней)
- Поощрение осознанного потребления
- Предотвращение импульсивных покупок

**Этап 2 - Поиск товаров:**
- Переход к роли "GTC Procurement Analyst"
- Использование SerpAPI для поиска
- Возврат до 5 позиций с ценами и ссылками
- Поддержка мультирегиональности (EU, RO)

### 7. **Azure OpenAI Chat Model** (Primary LLM)
- **Тип**: `@n8n/n8n-nodes-langchain.lmChatAzureOpenAi`
- **Модель**: GPT-4o
- **Функция**: Основная языковая модель для AI-агента
- **Credentials**: "Azure GPT4o Telegramm"

### 8. **Azure OpenAI Chat Model1** (Secondary LLM)
- **Тип**: `@n8n/n8n-nodes-langchain.lmChatAzureOpenAi`
- **Модель**: GPT-4o
- **Функция**: Резервная или специализированная модель
- **Credentials**: "Azure OpenAI GPT-4o GTC1"

### 9. **Search for products and servicesI** (Web Search Tool)
- **Тип**: `@n8n/n8n-nodes-langchain.toolSerpApi`
- **Функция**: Инструмент поиска товаров в интернете
- **Конфигурация**: google.com домен
- **Интеграция**: Подключен как AI-tool к агенту

### 10. **SanitizeForTelegram** (Message Formatting)
- **Тип**: `n8n-nodes-base.code` (JavaScript)
- **Функция**: Подготовка ответа для Telegram
- **Возможности**:
  - Экранирование специальных символов для MarkdownV2
  - Разбиение длинных сообщений (лимит 3500 символов)
  - Поддержка множественных частей

### 11. **@Procurement_AnalystBot** (Response Delivery)
- **Тип**: `n8n-nodes-base.telegram`
- **Функция**: Отправка ответа пользователю в Telegram
- **Конфигурация**:
  - Формат: MarkdownV2
  - Динамический chat_id из контекста
  - Webhook ID: `1266b80d-ad8a-4a5a-9b27-1aafd3e70c91`

### 12. **Save Bot Response** (Response Logging)
- **Тип**: `n8n-nodes-base.postgres`
- **Функция**: Сохранение ответа AI в базу данных
- **SQL**: UPDATE с jsonb_set для метаданных Telegram
- **Данные**: response text, message_id, chat_id, raw response

### 13. **Sticky Note** (Documentation)
- **Тип**: `n8n-nodes-base.stickyNote`
- **Содержание**: "Следует выяснить, как можно научить поиску в сети"
- **Функция**: Документация и заметки разработчика

## Технические особенности

### База данных
- **PostgreSQL** с таблицами:
  - `user` (основные пользователи)
  - `auth_telegram` (Telegram-аутентификация)
  - `chat_log` (история сообщений)
- **JSONB** поля для гибких метаданных

### AI Capabilities
- **Двухмодельная архитектура** (два Azure OpenAI подключения)
- **LangChain Agent** с инструментами поиска
- **SerpAPI** для веб-поиска товаров
- **Контекстная память** через историю чата

### Telegram Integration
- **MarkdownV2** форматирование
- **Chunking** длинных сообщений
- **Webhook** архитектура для real-time ответов

## Бизнес-логика

### Философия агента
1. **Защита от импульсивных покупок**
2. **Классификация потребностей** по Маслоу
3. **Осознанное потребление**
4. **Персонализированные рекомендации**

### Мультиязычность
- Базовый язык: русский
- Поддержка ответов на языке пользователя
- English queries для поиска товаров

### Регионализация
- Поддержка EUR, USD, RON валют
- Регионы: EU, RO
- Локализованные маркетплейсы (AliExpress, eMAG, Amazon)

## Потенциальные улучшения

1. **Обработка ошибок**: Добавить error handling узлы
2. **Кэширование**: Реализовать кэш частых запросов
3. **Аналитика**: Дашборд для метрик использования
4. **A/B тестирование**: Разные промпты для групп пользователей
5. **Мультимодальность**: Поддержка изображений товаров

## Заключение

Workflow представляет собой полнофункциональную систему AI-помощника по покупкам с продуманной архитектурой, интеграцией с внешними сервисами и ориентацией на пользовательский опыт. Система демонстрирует современные подходы к conversational AI и e-commerce автоматизации.