require 'spec_helper'
require 'tempfile'

RSpec.describe JobMarketAnalytics::Reporters::HtmlReporter do
  let(:vacancies) do
    [
      JobMarketAnalytics::Models::Vacancy.new(
        title: 'Ruby Developer',
        salary: { from: 100000, to: 150000, currency: 'RUB' },
        employer: 'Company A',
        description: 'Ruby on Rails'
      ),
      JobMarketAnalytics::Models::Vacancy.new(
        title: 'Python Developer',
        salary: { from: 120000, to: 180000, currency: 'RUB' },
        employer: 'Company B',
        description: 'Django and PostgreSQL'
      )
    ]
  end
  
  describe '#generate' do
    it 'создает HTML файл' do
      temp_file = Tempfile.new(['test', '.html'])
      reporter = described_class.new(vacancies, 'Test Report', temp_file.path)
      
      file_path = reporter.generate
      
      expect(File.exist?(file_path)).to be true
      content = File.read(file_path)
      expect(content).to include('Test Report')
      expect(content).to include('Ruby Developer')
      expect(content).to include('Python Developer')
      
      temp_file.close
      temp_file.unlink
    end
  end
  
  describe '#average_salary' do
    it 'вычисляет среднюю зарплату' do
      reporter = described_class.new(vacancies)
      avg = reporter.send(:average_salary)
      expect(avg).to eq(137500)
    end
    
    it 'возвращает 0 если нет вакансий с зарплатой' do
      empty_vacancies = [
        JobMarketAnalytics::Models::Vacancy.new(title: 'No Salary', salary: nil)
      ]
      reporter = described_class.new(empty_vacancies)
      avg = reporter.send(:average_salary)
      expect(avg).to eq(0)
    end
  end
  
  describe '#unique_employers_count' do
    it 'считает уникальных работодателей' do
      reporter = described_class.new(vacancies)
      count = reporter.send(:unique_employers_count)
      expect(count).to eq(2)
    end
  end
end