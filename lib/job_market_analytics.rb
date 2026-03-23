require_relative "job_market_analytics/version"
require_relative "job_market_analytics/models/vacancy"
require_relative "job_market_analytics/reporters/html_reporter"

module JobMarketAnalytics
  class Error < StandardError; end

  def self.generate_report(vacancies_data, title = "Job Market Report", output_path = nil)
    vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
    reporter = Reporters::HtmlReporter.new(vacancies, title, output_path)
    reporter.generate_and_open
  end
  
  def self.save_report(vacancies_data, title = "Job Market Report", output_path = nil)
    vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
    reporter = Reporters::HtmlReporter.new(vacancies, title, output_path)
    reporter.generate
  end
end