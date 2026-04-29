# JobMarketAnalytics

**Vacancy Parser** - анализатор рынка вакансий с hh.ru и Telegram бот

## Концепция

Gem умеет ходить в открытое API сайтов по поиску работы, собирать свежие вакансии по заданным критериям, анализировать их и отдавать результат в структурированном виде.

## Для чего это нужно

- HR-специалисты могут быстро получить срез зарплат по рынку

- Разработчики могут понять, какие технологии сейчас востребованы

- Можно интегрировать гем в телеграм-бота или CI/CD пайплайн для еженедельной рассылки отчета

## Инструкция

- Запуск тестов: ruby test/test_integration.rb

- Запуск приложения: ruby test.rb

## Структура гема

job_market_analytics/

├── lib/

│ ├── job_market_analytics.rb # Основная точка входа

│ ├── job_market_analytics/

│ │ ├── version.rb # Версионирование

│ │ ├── client.rb # Класс для работы с API

│ │ ├── models/

│ │ │ ├── vacancy.rb # Модель вакансии

│ │ │ └── summary.rb # Агрегированные данные

│ │ └── reporters/

│ │ ├── base_reporter.rb # Базовый класс репортера

│ │ └── html_reporter.rb # Генератор HTML

│ │ └── api/

│ │ ├── head_hunter_api.rb # Запросы в API

├── test/

│ │ └── test\_integration # Интеграционные тесты

├── ruby/

│ │ └── string.rb # Дополнение к String

├── Gemfile

├── README.md

└── job_market_analytics.gemspec

Авторы

Сентюрина Дарья- HTML репортер, модель Vacancy

Исакова Хадижат - API парсер
