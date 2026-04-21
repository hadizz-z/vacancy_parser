require 'json'
require 'net/http'
require 'uri'

puts "--- Инициализация бота ---"

# Подключаем файлы. Используем __dir__ для надежности путей
$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))
require 'job_market_analytics'
require_relative 'states'
require_relative 'ui_helpers'

TOKEN = '8682482122:AAFwBJuzwaPQpExqAiR9SMoQq_X1vY7kxxs'

def send_message(chat_id, text)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/sendMessage")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Post.new(uri)
  request.set_form_data({'chat_id' => chat_id, 'text' => text})
  
  response = http.request(request)
  puts "-> Отправлено (#{chat_id}): #{text[0..30]}..."
rescue => e
  puts "! Ошибка отправки: #{e.message}"
end

def get_updates(offset = nil)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/getUpdates")
  params = {'timeout' => 20}
  params['offset'] = offset if offset
  uri.query = URI.encode_www_form(params)
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 25
  
  # Используем request_uri для надежности
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  
  JSON.parse(response.body)
rescue Net::ReadTimeout
  # Таймаут - это нормально при long polling, если никто не пишет
  {"ok" => true, "result" => []}
rescue => e
  puts "! Ошибка получения обновлений: #{e.class} - #{e.message}"
  {"ok" => false, "result" => []}
end

puts "=== Бот запущен! Ожидание сообщений... ==="

last_id = nil
waiting = {}

loop do
  updates = get_updates(last_id)
  
  if updates["ok"] && updates["result"] && updates["result"].any?
    updates["result"].each do |update|
      last_id = update["update_id"] + 1
      
      if update["message"] && update["message"]["text"]
        chat_id = update["message"]["chat"]["id"]
        text = update["message"]["text"]
        
        puts "<- Получено от #{chat_id}: #{text}"
        
        case text
        when "/start"
          send_message(chat_id, "Бот-аналитик HH.ru\nКоманды:\n/search - найти вакансии")
        when "/search"
          waiting[chat_id] = true
          send_message(chat_id, "Введи название профессии (например, Ruby developer):")
        else
          if waiting[chat_id]
            waiting.delete(chat_id)
            send_message(chat_id, "Анализирую '#{text}'. Загружаю 5 страниц с HH, подожди...")
            
            # ВАЖНО: Используем твой метод интеграции вместо старого кода
            result = JobMarketAnalytics.analyze_and_report(text)
            
            if result[:error]
              send_message(chat_id, "Ошибка: #{result[:error]}")
            else
              # Используем UiHelpers для красивого вывода
              teaser = UiHelpers.short_teaser(
                result[:vacancies_count],
                result[:average_salary],
                result[:median_salary],
                result[:top_skills]
              )
              send_message(chat_id, teaser)
              send_message(chat_id, "Отчет сохранен на сервере: #{result[:report_path]}")
            end
          else
            send_message(chat_id, "Нажми /search чтобы начать поиск.")
          end
        end
      end
    end
  end
  sleep(1)
end