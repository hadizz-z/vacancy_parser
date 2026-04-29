# spec/telegram_bot_spec.rb
require_relative 'spec_helper'
require_relative '../telegram_bot/bot'
require 'webmock/rspec'

RSpec.describe 'Telegram Bot' do
  let(:chat_id) { 123456789 }
  let(:test_keyword) { 'Ruby' }
  
  before do
    
    stub_request(:post, /api.telegram.org\/bot.*\/sendMessage/)
      .to_return(status: 200, body: '{"ok":true}', headers: {})
    
    stub_request(:post, /api.telegram.org\/bot.*\/sendChatAction/)
      .to_return(status: 200, body: '{"ok":true}', headers: {})
    
    stub_request(:post, /api.telegram.org\/bot.*\/sendDocument/)
      .to_return(status: 200, body: '{"ok":true}', headers: {})
    
    stub_request(:post, /api.telegram.org\/bot.*\/answerCallbackQuery/)
      .to_return(status: 200, body: '{"ok":true}', headers: {})
    
    stub_request(:post, /api.telegram.org\/bot.*\/editMessageReplyMarkup/)
      .to_return(status: 200, body: '{"ok":true}', headers: {})
    
    
    stub_request(:get, /api.hh.ru\/vacancies/)
      .to_return(
        status: 200,
        body: {
          items: [
            {
              name: 'Ruby Developer',
              salary: { from: 100000, to: 150000, currency: 'RUR' },
              employer: { name: 'Tech Company' },
              snippet: { requirement: 'Ruby on Rails, PostgreSQL' }
            }
          ],
          found: 1
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
  
  after do
    # Очищаем тестовые файлы
    ['bot_states.json', 'test_states.json', 'bot_data.json'].each do |file|
      File.delete(file) if File.exist?(file)
    end
  end
  
  describe 'State management' do
    it 'сохраняет состояние пользователя' do
      manager = StateManager.new('test_states.json')
      manager.set(chat_id, :awaiting_keyword, { keyword: test_keyword })
      
      expect(manager.get(chat_id).awaiting_keyword?).to be true
      expect(manager.get(chat_id).context[:keyword]).to eq(test_keyword)
    end
    
    it 'сохраняет результат поиска' do
      manager = StateManager.new('test_states.json')
      manager.save_search(chat_id, test_keyword, { vacancies_count: 10, average_salary: 100000 })
      
      last_search = manager.get_last_search(chat_id)
      expect(last_search[:keyword]).to eq(test_keyword)
      expect(last_search[:result][:vacancies_count]).to eq(10)
    end
    
    it 'восстанавливает состояние после перезапуска' do
      test_file = 'test_states.json'
      
      # Первый запуск - сохраняем
      manager1 = StateManager.new(test_file)
      manager1.set(chat_id, :awaiting_keyword)
      manager1.save_search(chat_id, test_keyword, { vacancies_count: 5 })
      
      # Второй запуск - загружаем (симуляция перезапуска бота)
      manager2 = StateManager.new(test_file)
      
      expect(manager2.get(chat_id).awaiting_keyword?).to be true
      expect(manager2.get_last_search(chat_id)[:keyword]).to eq(test_keyword)
      
      File.delete(test_file) if File.exist?(test_file)
    end
    
    it 'очищает данные пользователя' do
      manager = StateManager.new('test_states.json')
      manager.set(chat_id, :awaiting_keyword)
      manager.save_search(chat_id, test_keyword, { vacancies_count: 5 })
      
      manager.clear(chat_id)
      
      expect(manager.get(chat_id).idle?).to be true
      expect(manager.get_last_search(chat_id)).to be_nil
    end
  end
  
  describe 'UI Helpers' do
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
      expect(bar_chart(30)).to eq('▓▓▓░░░░░░░')
    end
    
    it 'склоняет слово "вакансия"' do
      expect(decline_vacancy(1)).to eq('вакансия')
      expect(decline_vacancy(2)).to eq('вакансии')
      expect(decline_vacancy(5)).to eq('вакансий')
      expect(decline_vacancy(11)).to eq('вакансий')
      expect(decline_vacancy(21)).to eq('вакансия')
      expect(decline_vacancy(22)).to eq('вакансии')
    end
    
    it 'форматирует опыт работы' do
      exp = {
        'noExperience' => 10,
        'between1And3' => 25,
        'between3And6' => 15,
        'moreThan6' => 5
      }
      
      result = format_experience(exp)
      
      expect(result).to include('Без опыта')
      expect(result).to include('1-3 года')
      expect(result).to include('3-6 лет')
      expect(result).to include('Более 6 лет')
      expect(result).to include('▓') # проверяем что bar chart есть
    end
    
    it 'обрабатывает пустой опыт работы' do
      expect(format_experience({})).to eq('  • Нет данных')
      expect(format_experience(nil)).to eq('  • Нет данных')
    end
    
    it 'форматирует график работы' do
      schedule = {
        'fullDay' => 20,
        'remote' => 15,
        'flexible' => 10
      }
      
      result = format_schedule(schedule)
      
      expect(result).to include('Полный день')
      expect(result).to include('Удаленка')
      expect(result).to include('Гибкий график')
    end
    
    it 'форматирует топ навыков' do
      skills = [['Ruby', 10], ['Python', 8], ['JavaScript', 5]]
      result = format_top_skills_preview(skills)
      
      expect(result).to include('Ruby')
      expect(result).to include('Python')
      expect(result).to include('JavaScript')
    end
  end
  
  describe 'Market evaluation' do
    it 'оценивает сбалансированный рынок' do
      data = { average_salary: 100000, median_salary: 95000, vacancies_count: 50 }
      expect(evaluate_market(data)).to eq('⚖️ Сбалансированный рынок труда')
    end
    
    it 'оценивает неравномерный рынок' do
      data = { average_salary: 150000, median_salary: 80000, vacancies_count: 50 }
      expect(evaluate_market(data)).to eq('📈 Рынок неравномерный, есть высокие предложения')
    end
    
    it 'оценивает низкий рынок' do
      data = { average_salary: 80000, median_salary: 100000, vacancies_count: 50 }
      expect(evaluate_market(data)).to eq('📉 Рынок смещен в сторону низких зарплат')
    end
    
    it 'обрабатывает мало данных' do
      data = { average_salary: 100000, median_salary: 95000, vacancies_count: 3 }
      expect(evaluate_market(data)).to eq('📊 Мало данных для анализа')
    end
  end
  
  describe 'Keyboard buttons' do
    it 'создает главное меню' do
      menu = KeyboardBuilder.main_menu
      
      expect(menu).to be_an(Array)
      expect(menu.flatten.size).to be >= 4
      expect(menu.flatten.first.text).to include('Поиск')
      expect(menu.flatten.map(&:text)).to include(a_string_matching(/Помощь/))
    end
    
    it 'создает кнопки результатов поиска' do
      buttons = KeyboardBuilder.search_result_buttons('Ruby')
      
      texts = buttons.flatten.map(&:text)
      expect(texts).to include(a_string_matching(/статистика/i))
      expect(texts).to include(a_string_matching(/навык/i))
      expect(texts).to include(a_string_matching(/отчет/i))
      expect(texts).to include(a_string_matching(/новый поиск/i))
    end
  end
end
