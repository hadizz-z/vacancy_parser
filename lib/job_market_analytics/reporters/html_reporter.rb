module JobMarketAnalytics
  module Reporters
    class HtmlReporter
      attr_reader :vacancies, :title, :output_path, :average_salary

      def initialize(vacancies, title = "Job Market Report", average_salary_formatted = "0", output_path = nil)
        @vacancies = vacancies
        @title = title
        @output_path = output_path || "report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.html"
        @average_salary = average_salary_formatted
      end

      def generate
        html = "<!DOCTYPE html>\n"
        html += "<html>\n<head>\n"
        html += "<meta charset='UTF-8'>\n"
        html += "<title>#{@title}</title>\n"
        html += "<style>\n"
        html += "body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }\n"
        html += "h1 { color: #333; }\n"
        html += ".stats { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; }\n"
        html += ".vacancy { background: white; margin: 20px 0; padding: 20px; border-radius: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }\n"
        html += ".vacancy-title { font-size: 1.2em; font-weight: bold; color: #667eea; }\n"
        html += ".vacancy-salary { color: #4caf50; font-weight: bold; margin: 10px 0; }\n"
        html += ".vacancy-description { color: #666; margin: 10px 0; }\n"
        html += ".tech-tag { display: inline-block; background: #e3f2fd; color: #1976d2; padding: 3px 8px; border-radius: 12px; font-size: 0.8em; margin-right: 5px; }\n"
        html += "</style>\n"
        html += "</head>\n<body>\n"
        html += "<h1>#{@title}</h1>\n"
        html += "<div class='stats'>\n"
        html += "<p>Total vacancies: <strong>#{@vacancies.size}</strong></p>\n"
        html += "<p>Average salary: <strong>≈#{@average_salary / @vacancies.size} руб.</strong></p>\n"
        html += "<p>Unique employers: <strong>#{unique_employers_count}</strong></p>\n"
        html += "</div>\n"
        
        @vacancies.each do |v|
          html += "<div class='vacancy'>\n"
          html += "<div class='vacancy-title'>#{escape_html(v.title)}</div>\n"
          html += "<div>Employer: #{escape_html(v.employer) || 'Not specified'}</div>\n"
          html += "<div class='vacancy-salary'>Salary: #{v.formatted_salary} руб.</div>\n"
          html += "<div class='vacancy-description'>#{escape_html(v.description || 'No description')}</div>\n"
          html += "<div>\n"
          v.extract_technologies.each do |tech|
            html += "<span class='tech-tag'>#{tech}</span>\n"
          end
          html += "</div>\n"
          if v.url
            html += "<a href='#{v.url}' target='_blank'>View details</a>\n"
          end
          html += "</div>\n"
        end
        
        html += "<hr><p style='text-align: center; color: #999;'>Generated: #{Time.now}</p>\n"
        html += "</body>\n</html>"
        
        File.write(@output_path, html)
        puts "HTML report saved to #{@output_path}"
        @output_path
      end

      def generate_and_open
        generate
        open_in_browser
      end

      private

      def average_salary
        salaries = @vacancies.map(&:average_salary).compact
        return 0 if salaries.empty?
        (salaries.sum / salaries.size).round
      end

      def unique_employers_count
        @vacancies.map(&:employer).compact.uniq.size
      end

      def escape_html(text)
        return "" if text.nil?
        text.to_s.gsub(/[&<>]/) do |match|
          case match
          when "&" then "&amp;"
          when "<" then "&lt;"
          when ">" then "&gt;"
          else match
          end
        end
      end

      def open_in_browser
        system("start #{@output_path}")
      end
    end
  end
end