require 'net/http'
require 'json'
require 'uri'

# Подключаем ваш гем
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'job_market_analytics'

TOKEN = '8682482122:AAFwBJuzwaPQpExqAiR9SMoQq_X1vY7kxxs'

def send_message(chat_id, text)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/sendMessage")
  Net::HTTP.post_form(uri, {'chat_id' => chat_id, 'text' => text})
rescue => e
  puts "Send error: #{e.message}"
end

def get_updates(offset = nil)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/getUpdates")
  params = {'timeout' => 30}
  params['offset'] = offset if offset
  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
rescue => e
  puts "Get updates error: #{e.message}"
  {'ok' => false, 'result' => []}
end

puts "Bot started!"
puts "Find your bot at: https://t.me/my_jod_analyst_bot"
puts "Send /start to begin"

last_update_id = nil
waiting_for_keyword = {}

loop do
  updates = get_updates(last_update_id)
  
  if updates['ok'] && updates['result'].any?
    updates['result'].each do |update|
      last_update_id = update['update_id'] + 1
      
      if update['message']
        chat_id = update['message']['chat']['id']
        text = update['message']['text']
        username = update['message']['from']['first_name'] || 'User'
        
        if text == '/start'
          send_message(chat_id, "Hello #{username}!\n\nJob Market Analytics Bot\n\nCommands:\n/search - find vacancies\n/help - help")
          
        elsif text == '/help'
          send_message(chat_id, "How to use:\n1. Send /search\n2. Enter profession (e.g., Ruby developer, Python, Java)\n3. Wait for results")
          
        elsif text == '/search'
          waiting_for_keyword[chat_id] = true
          send_message(chat_id, "Enter profession name:\nExamples: Ruby developer, Python, Java, Data Scientist")
          
        elsif waiting_for_keyword[chat_id]
          waiting_for_keyword.delete(chat_id)
          send_message(chat_id, "Searching for '#{text}'... Please wait (10-20 seconds)")
          
          begin
            # Используем ваш API
            api = JobMarketAnalytics::Api::HeadHunterApi.new
            vacancies_data = api.vacancy_request(text)
            
            if vacancies_data.nil? || vacancies_data.empty?
              send_message(chat_id, "No vacancies found for '#{text}'\nTry different keywords")
            else
              # Создаем объекты Vacancy
              vacancies = vacancies_data.map { |data| JobMarketAnalytics::Models::Vacancy.new(data) }
              
              # Считаем зарплаты
              salaries = []
              vacancies.each do |v|
                if v.respond_to?(:salary_from) && v.salary_from && v.salary_from.to_i > 0
                  salaries << v.salary_from.to_i
                end
              end
              
              avg_salary = salaries.sum / salaries.size if salaries.any?
              min_salary = salaries.min if salaries.any?
              max_salary = salaries.max if salaries.any?
              
              # Формируем ответ
              response = "📊 RESULTS FOR: #{text}\n\n"
              response += "📈 Vacancies found: #{vacancies.size}\n"
              response += "💰 Average salary: #{avg_salary.to_i} rub\n" if avg_salary
              response += "📉 Min salary: #{min_salary} rub\n" if min_salary
              response += "📈 Max salary: #{max_salary} rub\n" if max_salary
              
              send_message(chat_id, response)
              
              # Генерируем HTML отчет
              begin
                report_path = JobMarketAnalytics.save_report(vacancies_data, "Report for #{text}")
                send_message(chat_id, "📄 HTML report saved: #{report_path}")
              rescue => e
                puts "Report error: #{e.message}"
              end
            end
            
          rescue => e
            send_message(chat_id, "Error: #{e.message}")
            send_message(chat_id, "Make sure your gem is properly installed")
            puts "Error details: #{e.backtrace.first}"
          end
          
        else
          send_message(chat_id, "Send /search to find vacancies or /help for commands")
        end
      end
    end
  end
  
  sleep(1)
end