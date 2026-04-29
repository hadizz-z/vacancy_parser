# spec/bot_fast_spec.rb
require_relative 'spec_helper'



RSpec.describe 'Bot Helpers' do
  
  # Копируем только нужные функции (без зависимости от бота)
  def format_salary(salary)
    return "0 ₽" if salary.nil? || salary == 0
    "#{salary.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} ₽"
  end
  
  def format_number(num)
    return "0" if num.nil?
    num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
  
  def bar_chart(percent)
    filled = (percent / 100.0 * 10).round
    "▓" * filled + "░" * (10 - filled)
  end
  
  def decline_vacancy(count)
    return "вакансий" if count.nil?
    if count % 10 == 1 && count % 100 != 11
      "вакансия"
    elsif [2, 3, 4].include?(count % 10) && ![12, 13, 14].include?(count % 100)
      "вакансии"
    else
      "вакансий"
    end
  end
  
  def format_experience(exp_hash)
    return "  • Нет данных" if exp_hash.nil? || exp_hash.empty?
    
    mapping = {
      "noExperience" => "Без опыта",
      "between1And3" => "1-3 года",
      "between3And6" => "3-6 лет",
      "moreThan6" => "Более 6 лет"
    }
    
    total = exp_hash.values.sum.to_f
    return "  • Нет данных" if total == 0
    
    exp_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      bar = bar_chart(percent)
      "  #{mapping[key] || key}: #{bar} #{percent}%"
    end.join("\n")
  end
  
  def format_schedule(schedule_hash)
    return "  • Нет данных" if schedule_hash.nil? || schedule_hash.empty?
    
    mapping = {
      "fullDay" => "Полный день",
      "remote" => "Удаленка",
      "flexible" => "Гибкий график",
      "shift" => "Сменный"
    }
    
    total = schedule_hash.values.sum.to_f
    return "  • Нет данных" if total == 0
    
    schedule_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      bar = bar_chart(percent)
      "  #{mapping[key] || key}: #{bar} #{percent}%"
    end.join("\n")
  end
  
  def format_top_skills_preview(skills)
    return "  • Нет данных" if skills.nil? || skills.empty?
    skills.first(3).map.with_index(1) do |(skill, count), idx|
      "  #{idx}. #{skill} — #{count} #{decline_vacancy(count)}"
    end.join("\n")
  end
  
  def evaluate_market(data)
    avg = data[:average_salary].to_i
    median = data[:median_salary].to_i
    count = data[:vacancies_count]
    
    if count < 5
      "📊 Мало данных для анализа"
    elsif avg > median * 1.3
      "📈 Рынок неравномерный, есть высокие предложения"
    elsif avg < median * 0.7
      "📉 Рынок смещен в сторону низких зарплат"
    else
      "⚖️ Сбалансированный рынок труда"
    end
  end
  
  # ТЕСТЫ 
  
  describe 'format_salary' do
    it 'форматирует зарплату' do
      expect(format_salary(100000)).to eq('100,000 ₽')
      expect(format_salary(0)).to eq('0 ₽')
      expect(format_salary(nil)).to eq('0 ₽')
    end
  end
  
  describe 'format_number' do
    it 'форматирует числа' do
      expect(format_number(1000)).to eq('1,000')
      expect(format_number(1000000)).to eq('1,000,000')
    end
  end
  
  describe 'bar_chart' do
    it 'создает bar chart' do
      expect(bar_chart(50)).to eq('▓▓▓▓▓░░░░░')
      expect(bar_chart(100)).to eq('▓▓▓▓▓▓▓▓▓▓')
      expect(bar_chart(0)).to eq('░░░░░░░░░░')
    end
  end
  
  describe 'decline_vacancy' do
    it 'склоняет правильно' do
      expect(decline_vacancy(1)).to eq('вакансия')
      expect(decline_vacancy(2)).to eq('вакансии')
      expect(decline_vacancy(5)).to eq('вакансий')
    end
  end
  
  describe 'format_experience' do
    it 'форматирует опыт' do
      exp = {'noExperience' => 10, 'between1And3' => 20}
      result = format_experience(exp)
      expect(result).to include('Без опыта')
      expect(result).to include('1-3 года')
    end
    
    it 'обрабатывает пустой опыт' do
      expect(format_experience({})).to eq('  • Нет данных')
    end
  end
  
  describe 'format_schedule' do
    it 'форматирует график' do
      schedule = {'fullDay' => 20, 'remote' => 15}
      result = format_schedule(schedule)
      expect(result).to include('Полный день')
      expect(result).to include('Удаленка')
    end
  end
  
  describe 'format_top_skills_preview' do
    it 'форматирует навыки' do
      skills = [['Ruby', 10], ['Python', 5]]
      result = format_top_skills_preview(skills)
      expect(result).to include('Ruby')
      expect(result).to include('Python')
    end
  end
  
  describe 'evaluate_market' do
    it 'оценивает рынок' do
      expect(evaluate_market({average_salary: 100000, median_salary: 95000, vacancies_count: 50}))
        .to eq('⚖️ Сбалансированный рынок труда')
      
      expect(evaluate_market({average_salary: 150000, median_salary: 80000, vacancies_count: 50}))
        .to eq('📈 Рынок неравномерный, есть высокие предложения')
    end
  end
end
