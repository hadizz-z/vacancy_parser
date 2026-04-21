require_relative "job_market_analytics/version"
require_relative "job_market_analytics/models/vacancy"
require_relative "job_market_analytics/reporters/html_reporter"
require_relative "job_market_analytics/statistics/statistics_calculator"

module JobMarketAnalytics
  class Error < StandardError; end

  def self.generate_report(vacancies_data, title = "Job Market Report", total = "0", error = nil, output_path = nil)
    vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
    reporter = Reporters::HtmlReporter.new(vacancies, title, total, output_path)
    reporter.error = error if error
    #reporter.generate_and_open
    report_path = reporter.generate
    report_path
  end
  
  # def self.save_report(vacancies_data, title = "Job Market Report", output_path = nil)
  #   vacancies = vacancies_data.map { |data| Models::Vacancy.new(data) }
  #   reporter = Reporters::HtmlReporter.new(vacancies, title, output_path)
  #   reporter.generate
  # end

  def self.analyze_and_report(keywords, output_path = nil)
    api = Api::HeadHunterApi.new
    raw_data = api.vacancy_request(keywords)
    
    return { error: api.error } unless api.success?

    vacancies = raw_data.map { |data| Models::Vacancy.new(data) }
    calculator = StatisticsCalculator.new(vacancies)
    
    # генерируем HTML
    reporter = Reporters::HtmlReporter.new(vacancies, "Отчет: #{keywords}", calculator.average_salary, output_path)
    report_file = reporter.generate

    # возвращаем боту хэш со всем необходимым
    {
      error: nil,
      vacancies_count: calculator.total_count,
      average_salary: calculator.average_salary,
      median_salary: calculator.median_salary,
      top_skills: calculator.top_skills,
      top_employers: calculator.top_employers,
      experience: calculator.experience_distribution,
      schedule: calculator.schedule_distribution,
      report_path: report_file
    }
  end
end

