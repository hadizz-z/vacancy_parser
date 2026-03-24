require 'net/http'
require 'json'

module JobMarketAnalytics
  module Api
    class HeadHunterApi
      attr_reader :total_salary

      def initialize
        @total_salary = 0
      end

      def vacancy_request(keywords)
        uri = URI("https://api.hh.ru/vacancies?text=#{URI.encode_www_form_component(keywords)}")
        result = Net::HTTP.get(uri)
        parsed_data = JSON.parse(result)

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
      end
    end
  end
end
