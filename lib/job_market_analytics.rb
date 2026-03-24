require_relative "job_market_analytics/version"
require_relative "job_market_analytics/models/vacancy"
require_relative "job_market_analytics/reporters/html_reporter"

module JobMarketAnalytics
  class Error < StandardError; end

<<<<<<< HEAD
  def self.generate_report(vacancies_data, title = "Job Market Report", total = "0", output_path = nil)
    vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
    reporter = Reporters::HtmlReporter.new(vacancies, title, total, output_path)
=======
  def self.generate_report(vacancies_data, title = "Job Market Report", output_path = nil)
    vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
    reporter = Reporters::HtmlReporter.new(vacancies, title, output_path)
>>>>>>> 78d9af17130ee3cdf88e8162af52626c71082def
    reporter.generate_and_open
  end
  
  def self.save_report(vacancies_data, title = "Job Market Report", output_path = nil)
    vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
    reporter = Reporters::HtmlReporter.new(vacancies, title, output_path)
    reporter.generate
  end
end