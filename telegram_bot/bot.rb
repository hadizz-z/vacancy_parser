# telegram_bot/bot.rb
require 'faraday'
require 'telegram/bot'
require_relative 'states'
require_relative 'ui_helpers'

TOKEN = '8765953866:AAENBh7dMB5yzEwJWcpCp9PWOooypxSAmOg'

puts "🚀 Initializing bot..."

def send_main_menu(bot, chat_id)
  keyboard = [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Начать поиск", callback_data: "search"),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Помощь", callback_data: "help")
    ]
  ]

  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

  bot.api.send_message(
    chat_id: chat_id,
    text: "Введите название профессии (например, Python developer):",
    reply_markup: markup
  )
end

def send_help(bot, chat_id)
  help_text = """? Помощь

Справка по боту
Я помогу тебе проанализировать рынок труда России.
1. Нажми **Начать поиск**
2. Введи профессию (например: Ruby Developer)
3. Получи отчет и изучи навыки!"""

  bot.api.send_message(chat_id: chat_id, text: help_text, parse_mode: 'Markdown')
  
  # После помощи показываем кнопку начала поиска
  keyboard = [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Начать поиск", callback_data: "search")
    ]
  ]
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  
  bot.api.send_message(
    chat_id: chat_id,
    text: "Введите название профессии (например, Python developer):",
    reply_markup: markup
  )
end

def send_initial_prompt(bot, chat_id)
  keyboard = [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Начать поиск", callback_data: "search"),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Помощь", callback_data: "help")
    ]
  ]
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  
  bot.api.send_message(
    chat_id: chat_id,
    text: "Введите название профессии (например, Python developer):",
    reply_markup: markup
  )
end

def process_search(bot, chat_id, keyword)
  States.set(chat_id, States::IDLE)

  bot.api.send_chat_action(chat_id: chat_id, action: 'typing')

  bot.api.send_message(
    chat_id: chat_id,
    text: "Ищу вакансии по запросу '#{keyword}'. Пожалуйста, подождите..."
  )

  result = JobMarketAnalytics.analyze_and_report(keyword)

  if result[:error]
    bot.api.send_message(chat_id: chat_id, text: "Ошибка: #{result[:error]}")
  else
    # Форматируем результат 
    report = """
Найдено вакансий: #{result[:vacancies_count]}
Средняя ЗП: #{result[:average_salary].to_i} ₽
Медиана: #{result[:median_salary].to_i} ₽

Используй кнопки ниже для деталей
    """

    keyboard = [
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: "📊 Подробная статистика", callback_data: "full_stats:#{keyword}"),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: "⭐ Топ навыков", callback_data: "top_skills:#{keyword}")
      ],
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: "📄 HTML отчет", callback_data: "html_report:#{keyword}"),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: "🔄 Новый поиск", callback_data: "new_search")
      ]
    ]

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

    bot.api.send_message(
      chat_id: chat_id,
      text: report,
      reply_markup: markup
    )

    # Отправляем HTML отчет если есть
    if result[:report_path] && File.exist?(result[:report_path])
      bot.api.send_document(
        chat_id: chat_id,
        document: Faraday::UploadIO.new(result[:report_path], 'text/html')
      )
    end

    States.save_search_result(chat_id, keyword, result)
  end
end

def show_full_statistics(bot, chat_id, keyword)
  last_search = States.get_last_search(chat_id)
  
  if last_search && last_search[:keyword] == keyword
    data = last_search[:result]
    
    # Форматируем полную статистику
    stats = UiHelpers.full_statistics(data)
    
    # Добавляем оценку ЗП 
    avg = data[:average_salary].to_i
    median = data[:median_salary].to_i
    salary_eval = if avg > median * 1.2
      "📈 #{avg}/#{median}/#{data[:min_salary] || 0}"
    elsif avg < median * 0.8
      "📉 #{avg}/#{median}/#{data[:min_salary] || 0}"
    else
      "⚖️ #{avg}/#{median}/#{data[:min_salary] || 0}"
    end
    
    stats += "\n\nОценка ЗП: #{salary_eval}"
    
    bot.api.send_message(chat_id: chat_id, text: stats, parse_mode: 'Markdown')
  else
    bot.api.send_message(chat_id: chat_id, text: "⚠️ Данные не найдены. Выполните новый поиск.")
  end
end

def show_top_skills(bot, chat_id, keyword)
  last_search = States.get_last_search(chat_id)
  
  if last_search && last_search[:keyword] == keyword
    skills = last_search[:result][:top_skills]
    if skills && !skills.empty?
      text = "⭐ *Топ навыков для '#{keyword}':*\n\n"
      skills.first(10).each_with_index do |(skill, count), idx|
        text += "#{idx + 1}. #{skill} — #{count} #{decline_vacancy(count)}\n"
      end
      bot.api.send_message(chat_id: chat_id, text: text, parse_mode: 'Markdown')
    else
      bot.api.send_message(chat_id: chat_id, text: "⚠️ Навыки не найдены")
    end
  else
    bot.api.send_message(chat_id: chat_id, text: "⚠️ Данные не найдены. Выполните новый поиск.")
  end
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

def handle_callback(bot, callback_query)
  chat_id = callback_query.message.chat.id
  message_id = callback_query.message.message_id
  data = callback_query.data

  bot.api.answer_callback_query(callback_query_id: callback_query.id)

  case data
  when "search"
    States.set(chat_id, States::AWAITING_KEYWORD)
    bot.api.send_message(
      chat_id: chat_id, 
      text: "Введите название профессии (например, Python developer):"
    )
  when "help"
    send_help(bot, chat_id)
    return
  when "new_search"
    States.set(chat_id, States::AWAITING_KEYWORD)
    bot.api.send_message(
      chat_id: chat_id, 
      text: "Введите название профессии (например, Python developer):"
    )
  when /^full_stats:(.+)$/
    keyword = $1
    show_full_statistics(bot, chat_id, keyword)
  when /^top_skills:(.+)$/
    keyword = $1
    show_top_skills(bot, chat_id, keyword)
  when /^html_report:(.+)$/
    keyword = $1
    last_search = States.get_last_search(chat_id)
    if last_search && last_search[:keyword] == keyword && last_search[:result][:report_path]
      path = last_search[:result][:report_path]
      if File.exist?(path)
        bot.api.send_document(
          chat_id: chat_id,
          document: Faraday::UploadIO.new(path, 'text/html'),
          caption: "📄 HTML отчет по вакансиям '#{keyword}'"
        )
      else
        bot.api.send_message(chat_id: chat_id, text: "❌ Файл отчета не найден")
      end
    else
      bot.api.send_message(chat_id: chat_id, text: "⚠️ Отчет не найден. Выполните новый поиск.")
    end
  end

  # Убираем клавиатуру после нажатия (опционально)
  begin
    bot.api.edit_message_reply_markup(
      chat_id: chat_id,
      message_id: message_id,
      reply_markup: nil
    )
  rescue => e
    # Игнорируем ошибку, если сообщение уже было изменено
  end
end

# Main bot loop
begin
  Telegram::Bot::Client.run(TOKEN) do |bot|
    puts "✅ Bot is running. Waiting for messages..."

    # Обработка текстовых сообщений
    Thread.new do
      begin
        bot.listen do |message|
          begin
            next unless message&.text

            chat_id = message.chat.id
            text = message.text

            puts "📨 Received from #{chat_id}: #{text}"

            case text
            when "/start"
              send_initial_prompt(bot, chat_id)
            when "/search"
              States.set(chat_id, States::AWAITING_KEYWORD)
              bot.api.send_message(
                chat_id: chat_id, 
                text: "Введите название профессии (например, Python developer):"
              )
            when "/help"
              send_help(bot, chat_id)
            else
              if States.get(chat_id) == States::AWAITING_KEYWORD
                process_search(bot, chat_id, text)
              else
                send_initial_prompt(bot, chat_id)
              end
            end
          rescue => e
            puts "❌ Error processing message: #{e.message}"
            puts e.backtrace
          end
        end
      rescue => e
        puts "❌ Error in message listener thread: #{e.message}"
      end
    end

    # Обработка нажатий кнопок
    Thread.new do
      begin
        bot.listen do |callback_query|
          begin
            handle_callback(bot, callback_query)
          rescue => e
            puts "❌ Error processing callback: #{e.message}"
            puts e.backtrace
          end
        end
      rescue => e
        puts "❌ Error in callback listener thread: #{e.message}"
      end
    end

    sleep
  end
rescue => e
  puts "❌ Fatal error: #{e.message}"
  puts e.backtrace
end
