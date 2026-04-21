module JobMarketAnalytics
  class StatisticsCalculator
    attr_reader :vacancies

    def initialize(vacancies)
      @vacancies = vacancies
      @salaries = @vacancies.map(&:average_salary).compact.sort
    end

    def total_count
      @vacancies.size
    end

    def with_salary_count
      @salaries.size
    end

    def average_salary
      return 0 if @salaries.empty?
      (@salaries.sum / @salaries.size).round
    end

    def median_salary
      return 0 if @salaries.empty?
      len = @salaries.size
      (len % 2 == 1 ? @salaries[len/2] : (@salaries[len/2 - 1] + @salaries[len/2]) / 2.0).round
    end

    def top_employers(limit = 10)
      employers = @vacancies.map(&:employer).compact
      counts = employers.each_with_object(Hash.new(0)) { |emp, hash| hash[emp] += 1 }
      counts.sort_by { |_, count| -count }.first(limit).to_h
    end

    def top_skills(limit = 15)
      all_skills = @vacancies.flat_map(&:extract_technologies)
      counts = all_skills.each_with_object(Hash.new(0)) { |skill, hash| hash[skill] += 1 }
      counts.sort_by { |_, count| -count }.first(limit).to_h
    end

    def experience_distribution
      experiences = @vacancies.map(&:experience).compact
      experiences.each_with_object(Hash.new(0)) { |exp, hash| hash[exp] += 1 }
    end

    def schedule_distribution
      schedules = @vacancies.map(&:schedule).compact
      schedules.each_with_object(Hash.new(0)) { |sch, hash| hash[sch] += 1 }
    end
  end
end