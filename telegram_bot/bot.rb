require 'telegram/bot'


puts " Инициализация бота "

# Подключаем файлы
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'job_market_analytics'
require_relative 'states'
require_relative 'ui_helpers'

TOKEN = '8765953866:AAENBh7dMB5yzEwJWcpCp9PWOooypxSAmOg'

puts " Бот запущен! Ожидание сообщений... "

Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    # Заворачиваем в begin/rescue, чтобы бот не умирал от случайных ошибок сети
    begin
      # Пропускаем, если это не текстовое сообщение (например, стикер)
      next unless message.text 
      
      chat_id = message.chat.id
      text = message.text
      
      puts "<- Получено от #{chat_id}: #{text}"
      
      case text
      when "/start"
        bot.api.send_message(chat_id: chat_id, text: "Бот-аналитик HH.ru\nКоманды:\n/search - найти вакансии")
      
      when "/search"
        # Используем ВАШУ машину состояний из states.rb
        States.set(chat_id, States::AWAITING_KEYWORD)
        bot.api.send_message(chat_id: chat_id, text: "Введи название профессии (например, Ruby developer):")
      
      else
        # Проверяем состояние пользователя
        if States.get(chat_id) == States::AWAITING_KEYWORD
          # Сбрасываем состояние
          States.set(chat_id, States::IDLE)
          bot.api.send_message(chat_id: chat_id, text: "Анализирую '#{text}'. Загружаю 5 страниц с HH, подожди...")
          
          # Вызов аналитики
          result = JobMarketAnalytics.analyze_and_report(text)
          
          if result[:error]
            bot.api.send_message(chat_id: chat_id, text: "Ошибка: #{result[:error]}")
          else
            # Формируем и отправляем текст
            report = UiHelpers.short_teaser(
              result[:vacancies_count],
              result[:average_salary],
              result[:median_salary],
              result[:top_skills]
            )
            bot.api.send_message(chat_id: chat_id, text: report)
            
            # ОТПРАВКА HTML-ФАЙЛА (Этап 3)
            # Гем использует Faraday под капотом, поэтому файл передается так:
            bot.api.send_document(
              chat_id: chat_id, 
              document: Faraday::UploadIO.new(result[:report_path], 'text/html')
            )
          end
        else
          bot.api.send_message(chat_id: chat_id, text: "Нажми /search чтобы начать поиск.")
        end
      end
      
    rescue => e
      puts "!!! Ошибка при обработке сообщения: #{e.message}"
      # Если нужно, можно и боту сообщать: bot.api.send_message(chat_id: message.chat.id, text: "Упс, что-то пошло не так на сервере.")
    end
  end
end