require 'socksify/http'
require 'json'
require 'net/http'
require 'uri'

TOKEN = '8682482122:AAFwBJuzwaPQpExqAiR9SMoQq_X1vY7kxxs'
PROXY_ADDR = '127.0.0.1'
PROXY_PORT = 10808

puts "=== Job Market Bot ==="
puts "Starting..."

def send_message(chat_id, text)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/sendMessage")
  http = Net::HTTP.SOCKSProxy(PROXY_ADDR, PROXY_PORT).new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  
  request = Net::HTTP::Post.new(uri)
  request.set_form_data({'chat_id' => chat_id, 'text' => text})
  
  http.request(request)
  puts "Sent: #{text[0..50]}"
rescue => e
  puts "Send error: #{e.message}"
end

def get_updates(offset = nil)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/getUpdates")
  params = {'timeout' => 25}
  params['offset'] = offset if offset
  uri.query = URI.encode_www_form(params)
  
  http = Net::HTTP.SOCKSProxy(PROXY_ADDR, PROXY_PORT).new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 10
  http.read_timeout = 10
  
  response = http.request(Net::HTTP::Get.new(uri))
  JSON.parse(response.body)
rescue => e
  puts "Get updates error: #{e.message}"
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
          send_message(chat_id, "How to use:\n1. Send /search\n2. Enter profession\n3. Get statistics")
          
        when "/search"
          waiting[chat_id] = true
          send_message(chat_id, "Enter profession name (e.g., Ruby developer, Python):")
          
        else
          if waiting[chat_id]
            waiting.delete(chat_id)
            send_message(chat_id, "Searching for '#{text}'... Please wait")
            
            begin
              $LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
              require 'job_market_analytics'
              
              api = JobMarketAnalytics::Api::HeadHunterApi.new
              vacancies_data = api.vacancy_request(text)
              
              if vacancies_data && vacancies_data.any?
                salaries = []
                vacancies_data.each do |v|
                  if v['salary'] && v['salary']['from']
                    salaries << v['salary']['from']
                  end
                end
                
                avg_salary = salaries.sum / salaries.size if salaries.any?
                
                response = "RESULTS for '#{text}':\n\n"
                response += "Vacancies found: #{vacancies_data.size}\n"
                response += "Average salary: #{avg_salary.to_i} rub\n" if avg_salary
                response += "\nSend /search to try another profession"
                
                send_message(chat_id, response)
              else
                send_message(chat_id, "No vacancies found for '#{text}'")
              end
              
            rescue => e
              send_message(chat_id, "Error: #{e.message}")
              puts "Error: #{e.message}"
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