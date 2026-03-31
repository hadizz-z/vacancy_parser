    module JobMarketAnalytics
  module Models
    class Vacancy
      attr_reader :title, :salary, :description, :employer, :url, :published_at

      def initialize(attributes = {})
        @title = attributes[:title] || attributes['title']
        @salary = attributes[:salary] || attributes['salary']
        @description = attributes[:description] || attributes['description']
        @employer = attributes[:employer] || attributes['employer']
        @url = attributes[:url] || attributes['url']
        @published_at = attributes[:published_at] || attributes['published_at']
      end

      def salary_present?
        !@salary.nil?
      end

      def formatted_salary
        return "Не указана" unless @salary
        
        if @salary.is_a?(Hash)
          parts = []
          parts << "от #{@salary[:from]}" if @salary[:from]
          parts << "до #{@salary[:to]}" if @salary[:to]
          parts << @salary[:currency] if @salary[:currency]
          parts.join(" ")
        else
          @salary.to_s
        end
      end

      def average_salary
        return nil unless salary_present? && @salary.is_a?(Hash)
        
        if @salary[:from] && @salary[:to]
          (@salary[:from] + @salary[:to]) / 2.0
        elsif @salary[:from]
          @salary[:from].to_f
        elsif @salary[:to]
          @salary[:to].to_f
        end
      end

      def extract_technologies
        return [] unless @description
        
        techs = ['Ruby', 'Rails', 'Python', 'JavaScript', 'React', 'Java', 'PostgreSQL', 'Docker']
        techs.select { |tech| @description.include?(tech) }
      end
    end
  end
end
