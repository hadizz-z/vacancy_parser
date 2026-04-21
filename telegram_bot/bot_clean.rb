require 'json'

TOKEN = '8682482122:AAFwBJuzwaPQpExqAiR9SMoQq_X1vY7kxxs'

puts "=== Job Market Bot ==="
puts "Starting..."

def send_message(chat_id, text)
  cmd = "curl -s -X POST https://api.telegram.org/bot#{TOKEN}/sendMessage -d chat_id=#{chat_id} -d text=\"#{text.gsub('"', '\"')}\""
  `#{cmd}`
  puts "Sent: #{text[0..50]}"
end

def get_updates(offset = nil)
  url = "https://api.telegram.org/bot#{TOKEN}/getUpdates?timeout=25"
  url += "&offset=#{offset}" if offset
  response = `curl -s "#{url}"`
  JSON.parse(response)
rescue
  {"ok" => false, "result" => []}
end

puts "Bot is running! Find it at: https://t.me/my_jod_analyst_bot"
puts "Waiting for messages..."

last_id = nil
waiting = {}

loop do
  updates = get_updates(last_id)
  
  if updates["ok"] && updates["result"] && updates["result"].any?
    updates["result"].each do |update|
      last_id = update["update_id"] + 1
      
      if update["message"]
        chat_id = update["message"]["chat"]["id"]
        text = update["message"]["text"]
        
        puts "Received: #{text}"
        
        case text
        when "/start"
          send_message(chat_id, "Job Market Bot\nCommands:\n/search - find vacancies\n/help - info")
          
        when "/help"
          send_message(chat_id, "How to use:\n1. Send /search\n2. Enter profession (e.g., Ruby developer, Python)\n3. Get statistics")
          
        when "/search"
          waiting[chat_id] = true
          send_message(chat_id, "Enter profession name (e.g., Ruby developer, Python, Java):")
          
        else
          if waiting[chat_id]
            waiting.delete(chat_id)
            send_message(chat_id, "Searching for '#{text}'... Please wait (10-20 seconds)")
            
            begin
              # Подключаем ваш гем
              $LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
              require 'job_market_analytics'
              
              api = JobMarketAnalytics::Api::HeadHunterApi.new
              vacancies_data = api.vacancy_request(text)
              
              if vacancies_data && vacancies_data.any?
                # Считаем зарплаты
                salaries = []
                vacancies_data.each do |v|
                  if v['salary'] && v['salary']['from']
                    salaries << v['salary']['from']
                  end
                end
                
                avg_salary = salaries.sum / salaries.size if salaries.any?
                min_salary = salaries.min if salaries.any?
                max_salary = salaries.max if salaries.any?
                
                response = "RESULTS for '#{text}':\n\n"
                response += "Vacancies found: #{vacancies_data.size}\n"
                response += "Average salary: #{avg_salary.to_i} rub\n" if avg_salary
                response += "Min salary: #{min_salary} rub\n" if min_salary
                response += "Max salary: #{max_salary} rub\n" if max_salary
                response += "\nSend /search to try another profession"
                
                send_message(chat_id, response)
              else
                send_message(chat_id, "No vacancies found for '#{text}'\nTry different keywords or check spelling")
              end
              
            rescue => e
              send_message(chat_id, "Error: #{e.message}")
              puts "Error details: #{e.message}"
              puts e.backtrace.first if e.backtrace
            end
          else
            send_message(chat_id, "Send /search to find vacancies")
          end
        end
      end
    end
  end
  
  sleep(1)
end