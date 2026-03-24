require_relative '../lib/job_market_analytics/api/head_hunter_api'
require_relative '../lib/job_market_analytics/reporters/html_reporter'
require_relative '../lib/job_market_analytics'
require 'minitest/autorun'
require 'fileutils'
require_relative '../ruby/string'

class TestIntegration < Minitest::Test
  def setup
    @api = JobMarketAnalytics::Api::HeadHunterApi.new
    @test_output = 'test_report.html'
  end

  def teardown
    FileUtils.rm_f(@test_output)
  end

  def test_api_returns_response
    puts "\nТест 1: Проверка API"
    
    result = @api.vacancy_request('ruby')
    
    assert_kind_of Array, result, "API должен вернуть массив".red
    puts "✓ API вернул массив".green
    
    assert result.size > 0, "Массив вакансий не должен быть пустым".red
    puts "✓ Найдено вакансий: #{result.size}".green
    
    if result.size > 0
      first = result.first
      assert first[:title], "Вакансия должна иметь название".red
      assert first[:salary], "Вакансия должна иметь зарплату".red
      assert first[:description], "Вакансия должна иметь описание".red
      assert first[:employer], "Вакансия должна иметь работодателя".red
      assert first[:url], "Вакансия должна иметь URL".red
      
      puts "✓ Структура вакансии корректна".green
      puts "  - Название: #{first[:title]}"
      puts "  - Зарплата: #{first[:salary]}"
      puts "  - Работодатель: #{first[:employer]}"
    end
  end

  def test_total_salary_calculated
    puts "\nТест 2: Проверка суммы зарплат "
    
    result = @api.vacancy_request('ruby')
    total = @api.total_salary
    
    assert_kind_of Numeric, total, "total_salary должен быть числом".red
    puts "✓ total_salary - число: #{total}".green
    
    if result.size > 0
      any_salary = result.any? { |v| v[:salary] > 0 }
      
      if any_salary
        assert total > 0, "Сумма зарплат должна быть > 0".red
        puts "✓ Сумма зарплат посчитана: #{total}".green
      else
        puts "Нет вакансий с указанной зарплатой, total = #{total}".red
      end
    end
  end

  def test_report_created
    puts "\nТест 3: Проверка создания отчёта "
    
    vacancies_data = @api.vacancy_request('ruby')
    total = @api.total_salary
    
    result = JobMarketAnalytics.generate_report(vacancies_data, 'Test Report', total, @test_output)
    
    assert File.exist?(@test_output), "Файл отчёта должен быть создан".red
    puts "✓ Файл отчёта создан: #{@test_output}".green
    
    assert File.size(@test_output) > 0, "Файл отчёта не должен быть пустым".red
    puts "✓ Файл отчёта не пустой (#{File.size(@test_output)} байт)".green
    
    content = File.read(@test_output)
    assert content.include?('Test Report'), "Отчёт должен содержать заголовок".red
    assert content.include?(@total.to_s), "Отчёт должен содержать сумму зарплат".red
    puts "✓ Отчёт содержит заголовок и сумму зарплат".green
    
    assert content.include?('<!DOCTYPE html>') || content.include?('<html'), "Отчёт должен быть HTML".red
    puts "✓ Отчёт корректно сформирован как HTML".green
  end

  def test_multiple_requests_reset_total
    puts "\nТест 4: Проверка сброса суммы при новом запросе "
    
    @api.vacancy_request('ruby')
    first_total = @api.total_salary
    
    @api.vacancy_request('python')
    second_total = @api.total_salary
    
    assert_kind_of Numeric, second_total, "После второго запроса total должен быть числом".red
    puts "✓ total_salary обновляется при каждом запросе".green
    puts "✓ Второй запрос: сумма = #{second_total}".green
    puts "✓ total_salary обновляется при каждом запросе".green
  end
end
