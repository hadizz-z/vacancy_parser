require_relative 'lib/job_market_analytics'
require_relative 'lib/job_market_analytics/api/head_hunter_api'

puts "Введите ключевые слова для поиска (например, ruby developer):"
keywords = gets.chomp

hh_api = JobMarketAnalytics::Api::HeadHunterApi.new
vacancies_data = hh_api.vacancy_request(keywords)

if hh_api.success?
  puts "Найдено вакансий: #{vacancies_data.size}"
  puts "Генерируем отчет..."
  JobMarketAnalytics.generate_report(vacancies_data, "Отчет по вакансиям: #{keywords}", hh_api.total_salary)
else
  puts "Ошибка: #{hh_api.error}"
  puts "Генерируем отчет с сообщением об ошибке..."
  JobMarketAnalytics.generate_report([], "Отчет по вакансиям: #{keywords}", 0, hh_api.error)
end

puts "Готово!"
