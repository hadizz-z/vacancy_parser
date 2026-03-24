# JobMarketAnalytics

[![Tests](https://github.com/hadizz-z/vacancy_parser/actions/workflows/test.yml/badge.svg)](https://github.com/hadizz-z/vacancy_parser/actions/workflows/test.yml)

Ruby gem для анализа рынка вакансий и генерации HTML отчетов.

## Концепция

Gem умеет ходить в открытое API сайтов по поиску работы, собирать свежие вакансии по заданным критериям, анализировать их и отдавать результат в структурированном виде.

## Для чего это нужно

- HR-специалисты могут быстро получить срез зарплат по рынку
- Разработчики могут понять, какие технологии сейчас востребованы
- Можно интегрировать гем в телеграм-бота или CI/CD пайплайн для еженедельной рассылки отчета

## Установка

```bash
git clone https://github.com/hadizz-z/vacancy_parser.git
cd vacancy_parser
bundle install


## Авторы

Сентюрина Дарья - HTML репортер, модель Vacancy

Исакова Хадижат - API парсер

##Лицензия 

MIT