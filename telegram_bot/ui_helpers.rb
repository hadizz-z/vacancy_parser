module UiHelpers
  MAX_BAR_LEN = 20
  
  def self.bar_chart(percent)
    filled = (percent / 100.0 * MAX_BAR_LEN).round
    "#" * filled + "-" * (MAX_BAR_LEN - filled)
  end
  
  def self.format_experience(exp_hash)
    return "Нет данных" if exp_hash.nil? || exp_hash.empty?
    
    mapping = {
      "noExperience" => "БЕз опыта",
      "between1And3" => "1-3 года",
      "between3And6" => "3-6 лет",
      "moreThan6" => "Более 6 лет"
    }
    
    total = exp_hash.values.sum.to_f
    return "Нет данных" if total == 0
    
    exp_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      "#{mapping[key] || key}: #{bar_chart(percent)} #{percent}% (#{count} vakanciy)"
    end.join("\n")
  end
  
  def self.format_schedule(schedule_hash)
    return "Нет данных" if schedule_hash.nil? || schedule_hash.empty?
    
    mapping = {
      "fullDay" => "Полный день",
      "remote" => "Удаленка",
      "flexible" => "Гибкий график",
      "shift" => "Сменный"
    }
    
    total = schedule_hash.values.sum.to_f
    return "Нет данных" if total == 0
    
    schedule_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      "#{mapping[key] || key}: #{bar_chart(percent)} #{percent}%"
    end.join("\n")
  end
  
  def self.format_top_skills(skills_array, limit = 10)
    return "Навыки не найдены" if skills_array.nil? || skills_array.empty?
    
    skills_array.first(limit).map.with_index(1) do |(skill, count), idx|
      "  #{idx}. #{skill} - встречается в #{count} вакансиях"
    end.join("\n")
  end
  
  def self.format_top_employers(employers_array, limit = 5)
    return "Нет данных" if employers_array.nil? || employers_array.empty?
    
    employers_array.first(limit).map.with_index(1) do |(name, count), idx|
      "  #{idx}. #{name} — #{count} вакансий"
    end.join("\n")
  end
  
  def self.short_teaser(vacancies_count, avg_salary, median_salary, top_skills)
    text = "Статистика\n\n"
    text += "Всего вакансий: #{vacancies_count}\n"
    text += "Средняя зарплата: #{avg_salary.to_i} rub.\n"
    text += "Медианная зп: #{median_salary.to_i} rub.\n\n"
    
    if top_skills && !top_skills.empty?
      text += "Самые частые навыки:\n"
      text += format_top_skills(top_skills, 3)
    end
    
    text
  end
  
  def self.full_statistics(data)
    text = "Полная статистика\n\n"
    text += "Зарплата:\n"
    text += "  Средняя: #{data[:average_salary].to_i} rub.\n"
    text += "  Медианная: #{data[:median_salary].to_i} rub.\n\n"
    text += "Опыт работы:\n"
    text += format_experience(data[:experience]) + "\n\n"
    text += "График работы:\n"
    text += format_schedule(data[:schedule]) + "\n\n"
    text += "Топ работодателей:\n"
    text += format_top_employers(data[:top_employers], 5) + "\n\n"
    text += "Топ навыков:\n"
    text += format_top_skills(data[:top_skills], 10)
    text
  end
end
