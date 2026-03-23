require_relative 'lib/job_market_analytics'

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
puts "Done! File saved to: #{result}"