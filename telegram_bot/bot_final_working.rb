require 'net/http'
require 'json'
require 'uri'

# Подключаем ваш гем
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'job_market_analytics'

TOKEN = 'ВАШ_ТОКЕН_СЮДА'

def send_message(chat_id, text)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/sendMessage")
  Net::HTTP.post_form(uri, {'chat_id' => chat_id, 'text' => text})
end

def get_updates(offset = nil)
  uri = URI.parse("https://api.telegram.org/bot#{TOKEN}/getUpdates")
  params = {'timeout' => 30}
  params['offset'] = offset if offset
  uri.query = URI.encode_www_form(params)
  response = Net::HTTP.get_response(uri)
  JSON.parse(response.body)
end

puts "Bot started"

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
        
        if text == '/start'
          send_message(chat_id, "Job Bot\nSend /search")
          
        elsif text == '/search'
          waiting_for_keyword[chat_id] = true
          send_message(chat_id, "Enter profession:")
          
        elsif waiting_for_keyword[chat_id]
          waiting_for_keyword.delete(chat_id)
          send_message(chat_id, "Searching for '#{text}'...")
          
          begin
            api = JobMarketAnalytics::Api::HeadHunterApi.new
            vacancies_data = api.vacancy_request(text)
            
            if vacancies_data.nil? || vacancies_data.empty?
              send_message(chat_id, "No vacancies found")
            else
              send_message(chat_id, "Found #{vacancies_data.size} vacancies")
            end
            
          rescue => e
            send_message(chat_id, "Error: #{e.message}")
          end
          
        else
          send_message(chat_id, "Send /search")
        end
      end
    end
  end
  
  sleep(1)
end