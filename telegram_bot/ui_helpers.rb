# telegram_bot/ui_helpers.rb
module UiHelpers
  MAX_BAR_LEN = 20
  
  def self.bar_chart(percent)
    filled = (percent / 100.0 * MAX_BAR_LEN).round
    "█" * filled + "░" * (MAX_BAR_LEN - filled)
  end
  
  def self.format_experience(exp_hash)
    return "📋 Нет данных" if exp_hash.nil? || exp_hash.empty?
    
    mapping = {
      "noExperience" => "✨ Без опыта",
      "between1And3" => "📚 1-3 года",
      "between3And6" => "🚀 3-6 лет",
      "moreThan6" => "🏆 Более 6 лет"
    }
    
    total = exp_hash.values.sum.to_f
    return "📋 Нет данных" if total == 0
    
    exp_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      "#{mapping[key] || key}: #{bar_chart(percent)} #{percent}% (#{count} вакансий)"
    end.join("\n")
  end
  
  def self.format_schedule(schedule_hash)
    return "📋 Нет данных" if schedule_hash.nil? || schedule_hash.empty?
    
    mapping = {
      "fullDay" => "🏢 Полный день",
      "remote" => "🏠 Удаленка",
      "flexible" => "⚡ Гибкий график",
      "shift" => "🔄 Сменный"
    }
    
    total = schedule_hash.values.sum.to_f
    return "📋 Нет данных" if total == 0
    
    schedule_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      "#{mapping[key] || key}: #{bar_chart(percent)} #{percent}%"
    end.join("\n")
  end
  
  def self.format_top_skills(skills_array, limit = 10)
    return "⭐ Навыки не найдены" if skills_array.nil? || skills_array.empty?
    
    skills_array.first(limit).map.with_index(1) do |(skill, count), idx|
      "  #{idx}. #{skill} — встречается в #{count} #{decline_vacancy(count)}"
    end.join("\n")
  end
  
  def self.format_top_employers(employers_array, limit = 5)
    return "🏢 Нет данных" if employers_array.nil? || employers_array.empty?
    
    employers_array.first(limit).map.with_index(1) do |(name, count), idx|
      "  #{idx}. #{name} — #{count} #{decline_vacancy(count)}"
    end.join("\n")
  end
  
  def self.short_teaser(vacancies_count, avg_salary, median_salary, top_skills)
    text = "📊 Статистика\n\n"
    text += "📋 Всего вакансий: #{vacancies_count}\n"
    text += "💰 Средняя зарплата: #{avg_salary.to_i} ₽\n"
    text += "📈 Медианная ЗП: #{median_salary.to_i} ₽\n\n"
    
    if top_skills && !top_skills.empty?
      text += "⭐ Самые частые навыки:\n"
      text += format_top_skills(top_skills, 3)
    end
    
    text
  end
  
  def self.full_statistics(data)
    text = "📊 *Полная статистика*\n\n"
    text += "💰 *Зарплата:*\n"
    text += "  Средняя: #{data[:average_salary].to_i} ₽\n"
    text += "  Медианная: #{data[:median_salary].to_i} ₽\n"
    text += "  Минимальная: #{data[:min_salary].to_i} ₽\n"
    text += "  Максимальная: #{data[:max_salary].to_i} ₽\n\n"
    
    text += "📅 *Опыт работы:*\n"
    text += format_experience(data[:experience]) + "\n\n" if data[:experience]
    
    text += "⏰ *График работы:*\n"
    text += format_schedule(data[:schedule]) + "\n\n" if data[:schedule]
    
    text += "🏢 *Топ работодателей:*\n"
    text += format_top_employers(data[:top_employers], 5) + "\n\n" if data[:top_employers]
    
    text += "⭐ *Топ навыков:*\n"
    text += format_top_skills(data[:top_skills], 10) if data[:top_skills]
    
    text
  end
  
  def self.decline_vacancy(count)
    return "вакансий" if count.nil?
    if count % 10 == 1 && count % 100 != 11
      "вакансии"
    elsif [2, 3, 4].include?(count % 10) && ![12, 13, 14].include?(count % 100)
      "вакансиях"
    else
      "вакансиях"
    end
  end
end
