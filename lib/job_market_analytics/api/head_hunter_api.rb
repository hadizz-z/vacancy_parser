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
        all_vacancies = []
        pages_to_fetch = 5 # Соберем до 5 страниц (500 вакансий максимум)
        
        begin
          pages_to_fetch.times do |page|
            # Добавили параметры per_page=100 и page
            uri = URI("https://api.hh.ru/vacancies?text=#{URI.encode_www_form_component(keywords)}&per_page=100&page=#{page}")
            result = Net::HTTP.get(uri)
            parsed_data = JSON.parse(result)
            
            break if parsed_data['items'].nil? || parsed_data['items'].empty?

            vacancies_data = parsed_data['items'].map do |item|
              salary_from = item.dig('salary', 'from') || 0
              @total_salary += salary_from

              # Очищаем описание от HTML-тегов (<highlighttext> и т.д.)
              raw_description = [item.dig('snippet', 'requirement'), item.dig('snippet', 'responsibility')].compact.join(' ')
              clean_description = raw_description.gsub(/<\/?[^>]*>/, "")

              {
                title: item['name'],
                salary: item['salary'], # Передаем весь хэш зарплаты, а не только from
                description: clean_description,
                employer: item.dig('employer', 'name'),
                url: item['alternate_url'],
                published_at: item['published_at'],
                experience: item.dig('experience', 'name'),
                schedule: item.dig('schedule', 'name')   
              }
            end

            all_vacancies.concat(vacancies_data)
            sleep(0.2) # Небольшая пауза, чтобы HH не забанил за спам запросами
          end
          
          all_vacancies
          
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
