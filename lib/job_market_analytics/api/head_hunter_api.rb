require 'net/http'
require 'json'

module JobMarketAnalytics
  module Api
    class HeadHunterApi
      attr_reader :total_salary, :error

      def initialize
        @total_salary = 0
        @error = nil
      end

      def vacancy_request(keywords)
        @total_salary = 0
        @error = nil
        
        uri = URI("https://api.hh.ru/vacancies?text=#{URI.encode_www_form_component(keywords)}")
        
        begin
          result = Net::HTTP.get(uri)
          parsed_data = JSON.parse(result)
          
          if parsed_data['items'].nil?
            @error = "API вернул некорректный ответ"
            return []
          end

          vacancies_data = parsed_data['items'].map do |item|
            salary_from = item.dig('salary', 'from') || 0
            @total_salary += salary_from

            {
              title: item['name'],
              salary: salary_from,
              description: [item.dig('snippet', 'requirement'), item.dig('snippet', 'responsibility')].compact.join(' '),
              employer: item.dig('employer', 'name'),
              url: item['alternate_url'],
              published_at: item['published_at']
            }
          end

          vacancies_data
          
        rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          @error = "Сайт hh.ru недоступен. Проверьте интернет-соединение."
          []
          
        rescue JSON::ParserError => e
          @error = "Ошибка при обработке данных от сервера"
          []
          
        rescue StandardError => e
          @error = "Произошла ошибка: #{e.message}"
          []
        end
      end

      def success?
        @error.nil?
      end
    end
  end
end
