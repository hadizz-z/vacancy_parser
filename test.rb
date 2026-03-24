require_relative 'lib/job_market_analytics'
require_relative 'lib/job_market_analytics/api/head_hunter_api'

puts "input keywords"
keywords = gets.chomp

hh_api = JobMarketAnalytics::Api::HeadHunterApi.new

vacancies_data = hh_api.vacancy_request(keywords)

puts "Generating report..."
result = JobMarketAnalytics.generate_report(vacancies_data, "Vacancy Market Report", hh_api.total_salary)
puts "Done! File saved to: #{result}"