# spec/telegram_bot_spec.rb
require_relative 'spec_helper'
require_relative '../telegram_bot/bot'
require 'webmock/rspec'

# Добавляем тег для группировки
RSpec.describe 'Telegram Bot', :type => :integration do
  
  let(:chat_id) { 123456789 }
  let(:test_keyword) { 'Ruby' }
  
  # Глобальный мок для всех HTTP запросов
  before(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
  
  before do
    # Мокаем все Telegram API запросы одним паттерном
    stub_request(:post, /api.telegram.org\/bot.*\//)
      .to_return(status: 200, body: '{"ok":true}', headers: {})
    
    # Мокаем HH.ru API
    stub_request(:get, /api.hh.ru\/vacancies/)
      .with(query: hash_including(text: test_keyword))
      .to_return(
        status: 200,
        body: {
          items: [
            {
              name: 'Ruby Developer',
              salary: { from: 100000, to: 150000, currency: 'RUR' },
              employer: { name: 'Tech Company' },
              snippet: { requirement: 'Ruby on Rails, PostgreSQL' },
              schedule: { name: 'fullDay' },
              experience: { id: 'between1And3' },
              alternate_url: 'https://hh.ru/vacancy/123'
            }
          ],
          found: 1,
          pages: 1,
          per_page: 100
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    # Мокаем любые другие запросы к HH.ru
    stub_request(:get, /api.hh.ru/)
      .to_return(status: 200, body: { items: [] }.to_json)
  end
  
  after do
    # Быстрая очистка тестовых файлов
    Dir.glob(['*_states.json', 'bot_data.json', 'test_*.json']).each do |file|
      File.delete(file) if File.exist?(file)
    end
  end
  
  describe 'State management' do
    let(:manager) { StateManager.new('test_states.json') }
    
    before do
      # Очищаем перед каждым тестом
      manager.clear(chat_id) if manager.get(chat_id)
    end
    
    it 'сохраняет состояние пользователя' do
      manager.set(chat_id, :awaiting_keyword, { keyword: test_keyword })
      
      state = manager.get(chat_id)
      expect(state.awaiting_keyword?).to be true
      expect(state.context[:keyword]).to eq(test_keyword)
    end
    
    it 'сохраняет результат поиска' do
      manager.save_search(chat_id, test_keyword, { vacancies_count: 10, average_salary: 100000 })
      
      last_search = manager.get_last_search(chat_id)
      expect(last_search[:keyword]).to eq(test_keyword)
      expect(last_search[:result][:vacancies_count]).to eq(10)
    end
    
    it 'восстанавливает состояние после перезапуска' do
      # Сохраняем
      manager.set(chat_id, :awaiting_keyword)
      manager.save_search(chat_id, test_keyword, { vacancies_count: 5 })
      
      # Загружаем заново (симуляция перезапуска)
      new_manager = StateManager.new('test_states.json')
      
      expect(new_manager.get(chat_id).awaiting_keyword?).to be true
      expect(new_manager.get_last_search(chat_id)[:keyword]).to eq(test_keyword)
    end
    
    it 'очищает данные пользователя' do
      manager.set(chat_id, :awaiting_keyword)
      manager.save_search(chat_id, test_keyword, { vacancies_count: 5 })
      
      manager.clear(chat_id)
      
      expect(manager.get(chat_id).idle?).to be true
      expect(manager.get_last_search(chat_id)).to be_nil
    end
  end
  
  describe 'UI Helpers' do
    # Группируем быстрые тесты форматирования
    describe 'formatting' do
      it 'форматирует зарплату' do
        expect(format_salary(100000)).to eq('100 000 ₽')
        expect(format_salary(0)).to eq('0 ₽')
        expect(format_salary(nil)).to eq('0 ₽')
      end
      
      it 'форматирует числа с разделителями' do
        expect(format_number(1000)).to eq('1,000')
        expect(format_number(1000000)).to eq('1,000,000')
        expect(format_number(1234567)).to eq('1,234,567')
      end
      
      it 'создает bar chart' do
        expect(bar_chart(50)).to eq('▓▓▓▓▓░░░░░')
        expect(bar_chart(100)).to eq('▓▓▓▓▓▓▓▓▓▓')
        expect(bar_chart(0)).to eq('░░░░░░░░░░')
      end
      
      it 'склоняет слово "вакансия"' do
        expect(decline_vacancy(1)).to eq('вакансия')
        expect(decline_vacancy(2)).to eq('вакансии')
        expect(decline_vacancy(5)).to eq('вакансий')
        expect(decline_vacancy(11)).to eq('вакансий')
        expect(decline_vacancy(21)).to eq('вакансия')
        expect(decline_vacancy(22)).to eq('вакансии')
      end
    end
    
    describe 'experience formatting' do
      let(:exp_hash) do
        {
          'noExperience' => 10,
          'between1And3' => 25,
          'between3And6' => 15,
          'moreThan6' => 5
        }
      end
      
      it 'форматирует опыт работы' do
        result = format_experience(exp_hash)
        
        expect(result).to include('Без опыта')
        expect(result).to include('1-3 года')
        expect(result).to include('3-6 лет')
        expect(result).to include('Более 6 лет')
      end
      
      it 'обрабатывает пустой опыт работы' do
        expect(format_experience({})).to eq('  • Нет данных')
        expect(format_experience(nil)).to eq('  • Нет данных')
      end
    end
    
    it 'форматирует график работы' do
      schedule = { 'fullDay' => 20, 'remote' => 15, 'flexible' => 10 }
      result = format_schedule(schedule)
      
      expect(result).to include('Полный день')
      expect(result).to include('Удаленка')
      expect(result).to include('Гибкий график')
    end
    
    it 'форматирует топ навыков' do
      skills = [['Ruby', 10], ['Python', 8], ['JavaScript', 5]]
      result = format_top_skills_preview(skills)
      
      expect(result).to include('Ruby', 'Python', 'JavaScript')
    end
  end
  
  describe 'Market evaluation' do
    # Параметризованные тесты для экономии времени
    [
      [100000, 95000, 50, '⚖️ Сбалансированный рынок труда'],
      [150000, 80000, 50, '📈 Рынок неравномерный, есть высокие предложения'],
      [80000, 100000, 50, '📉 Рынок смещен в сторону низких зарплат'],
      [100000, 95000, 3, '📊 Мало данных для анализа']
    ].each do |avg, med, count, expected|
      it "оценивает рынок с avg=#{avg}, med=#{med}, count=#{count}" do
        data = { average_salary: avg, median_salary: med, vacancies_count: count }
        expect(evaluate_market(data)).to eq(expected)
      end
    end
  end
  
  describe 'Keyboard buttons' do
    it 'создает главное меню' do
      menu = KeyboardBuilder.main_menu
      
      expect(menu).to be_an(Array)
      expect(menu.flatten.size).to be >= 4
      expect(menu.flatten.first.text).to include('Поиск')
    end
    
    it 'создает кнопки результатов поиска' do
      buttons = KeyboardBuilder.search_result_buttons('Ruby')
      texts = buttons.flatten.map(&:text)
      
      expect(texts).to include(
        a_string_matching(/статистика/i),
        a_string_matching(/навык/i),
        a_string_matching(/отчет/i),
        a_string_matching(/новый поиск/i)
      )
    end
  end
end
