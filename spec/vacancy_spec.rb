require 'spec_helper'

RSpec.describe JobMarketAnalytics::Models::Vacancy do
  describe '#initialize' do
    it 'создает вакансию с хэш атрибутами' do
      vacancy = described_class.new(
        title: 'Ruby Developer',
        salary: { from: 100000, to: 150000, currency: 'RUB' },
        employer: 'Tech Corp',
        description: 'Ruby on Rails developer needed'
      )
      
      expect(vacancy.title).to eq('Ruby Developer')
      expect(vacancy.salary[:from]).to eq(100000)
      expect(vacancy.employer).to eq('Tech Corp')
    end
    
    it 'работает с ключами в виде строк' do
      vacancy = described_class.new(
        'title' => 'Python Developer',
        'salary' => { 'from' => 120000, 'to' => 180000 }
      )
      
      expect(vacancy.title).to eq('Python Developer')
      expect(vacancy.salary[:from]).to eq(120000)
    end
  end
  
  describe '#salary_present?' do
    it 'возвращает true если зарплата указана' do
      vacancy = described_class.new(salary: { from: 100000 })
      expect(vacancy.salary_present?).to be true
    end
    
    it 'возвращает false если зарплата не указана' do
      vacancy = described_class.new(salary: nil)
      expect(vacancy.salary_present?).to be false
    end
  end
  
  describe '#average_salary' do
    it 'вычисляет среднее когда есть from и to' do
      vacancy = described_class.new(salary: { from: 100000, to: 150000 })
      expect(vacancy.average_salary).to eq(125000)
    end
    
    it 'использует from если to нет' do
      vacancy = described_class.new(salary: { from: 100000 })
      expect(vacancy.average_salary).to eq(100000)
    end
    
    it 'возвращает nil если зарплата не указана' do
      vacancy = described_class.new(salary: nil)
      expect(vacancy.average_salary).to be_nil
    end
  end
  
  describe '#formatted_salary' do
    it 'форматирует зарплату с from и to' do
      vacancy = described_class.new(salary: { from: 100000, to: 150000, currency: 'RUB' })
      expect(vacancy.formatted_salary).to eq('от 100000 до 150000 RUB')
    end
    
    it 'возвращает "Не указана" если зарплаты нет' do
      vacancy = described_class.new(salary: nil)
      expect(vacancy.formatted_salary).to eq('Не указана')
    end
  end
  
  describe '#extract_technologies' do
    it 'извлекает технологии из описания' do
      vacancy = described_class.new(
        description: 'Ищем Ruby on Rails разработчика с опытом PostgreSQL и Docker'
      )
      
      technologies = vacancy.extract_technologies
      expect(technologies).to include('Ruby', 'Rails', 'PostgreSQL', 'Docker')
    end
    
    it 'возвращает пустой массив если описание пустое' do
      vacancy = described_class.new(description: nil)
      expect(vacancy.extract_technologies).to eq([])
    end
  end
end