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
        
        clean_keywords = keywords.to_s.strip
        return [] if clean_keywords.empty?

        begin
          # API TrudVsem. Используем поиск по тексту.
          # Можно добавить параметр &region=61, если нужен только Ростов-на-Дону
          uri = URI("https://opendata.trudvsem.ru/api/v1/vacancies")
          uri.query = URI.encode_www_form({
            text: clean_keywords,
            limit: 100 # Максимальное количество за один запрос
          })

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          
          request = Net::HTTP::Get.new(uri)
          # TrudVsem не требует сложного User-Agent, но оставим для порядка
          request['User-Agent'] = 'JobAnalysisBot/1.0'

          response = http.request(request)

          if response.code != '200'
            @error = "Ошибка портала TrudVsem: #{response.code}"
            return []
          end

          parsed_data = JSON.parse(response.body)
          
          # У TrudVsem структура: results -> vacancies -> [ { vacancy: {...} }, ... ]
          raw_results = parsed_data.dig('results', 'vacancies') || []
          
          if raw_results.empty?
            return []
          end

          all_vacancies = raw_results.map do |wrapper|
            item = wrapper['vacancy']
            
            # Приводим зарплату к формату, который ожидает твой класс Vacancy
            salary_from = item['salary_min'] || 0
            @total_salary += salary_from

            {
              title: item['job-name'],
              salary: {
                from: item['salary_min'],
                to: item['salary_max'],
                currency: 'руб.'
              },
              # Собираем описание из обязанностей и требований
              description: [item['duty'], item.dig('requirement', 'content')].compact.join(' '),
              employer: item.dig('company', 'name'),
              url: item['vac_url'],
              published_at: item['creation-date'],
              experience: item.dig('requirement', 'experience'),
              schedule: item['schedule']
            }
          end

          all_vacancies
          
        rescue StandardError => e
          @error = "Ошибка сети или парсинга: #{e.message}"
          []
        end
      end

      def success?
        @error.nil?
      end
    end
  end
end