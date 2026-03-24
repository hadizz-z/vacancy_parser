require_relative 'lib/job_market_analytics'
<<<<<<< HEAD
require_relative 'lib/job_market_analytics/api/head_hunter_api'

puts "input keywords"
keywords = gets.chomp

hh_api = JobMarketAnalytics::Api::HeadHunterApi.new

vacancies_data = hh_api.vacancy_request(keywords)

puts "Generating report..."
result = JobMarketAnalytics.generate_report(vacancies_data, "Vacancy Market Report", hh_api.total_salary)
=======

vacancies = [
  {
    title: "Ruby Developer",
    salary: { from: 150000, to: 200000, currency: "RUB" },
    employer: "Tech Company",
    description: "We are looking for Ruby on Rails developer with PostgreSQL and Docker experience",
    url: "https://hh.ru/vacancy/123"
  },
  {
    title: "Python Developer", 
    salary: { from: 120000, to: 180000, currency: "RUB" },
    employer: "Startup Inc",
    description: "Django, REST API, React, PostgreSQL. Remote work available",
    url: "https://hh.ru/vacancy/456"
  },
  {
    title: "Frontend Developer",
    salary: { from: 100000, to: 150000, currency: "RUB" },
    employer: "Web Studio",
    description: "React, JavaScript, HTML, CSS. Working with modern frontend stack",
    url: "https://hh.ru/vacancy/789"
  }
]

puts "Generating report..."
result = JobMarketAnalytics.generate_report(vacancies, "Vacancy Market Report")
>>>>>>> 78d9af17130ee3cdf88e8162af52626c71082def
puts "Done! File saved to: #{result}"