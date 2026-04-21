module UiHelpers
  MAX_BAR_LEN = 20
  
  def self.bar_chart(percent)
    filled = (percent / 100.0 * MAX_BAR_LEN).round
    "#" * filled + "-" * (MAX_BAR_LEN - filled)
  end
  
  def self.format_experience(exp_hash)
    return "Net dannyh" if exp_hash.nil? || exp_hash.empty?
    
    mapping = {
      "noExperience" => "Bez opyta",
      "between1And3" => "1-3 goda",
      "between3And6" => "3-6 let",
      "moreThan6" => "Bolee 6 let"
    }
    
    total = exp_hash.values.sum.to_f
    return "Net dannyh" if total == 0
    
    exp_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      "#{mapping[key] || key}: #{bar_chart(percent)} #{percent}% (#{count} vakanciy)"
    end.join("\n")
  end
  
  def self.format_schedule(schedule_hash)
    return "Net dannyh" if schedule_hash.nil? || schedule_hash.empty?
    
    mapping = {
      "fullDay" => "Polny den",
      "remote" => "Udalenka",
      "flexible" => "Gibkiy grafik",
      "shift" => "Smenny"
    }
    
    total = schedule_hash.values.sum.to_f
    return "Net dannyh" if total == 0
    
    schedule_hash.map do |key, count|
      percent = (count / total * 100).round(1)
      "#{mapping[key] || key}: #{bar_chart(percent)} #{percent}%"
    end.join("\n")
  end
  
  def self.format_top_skills(skills_array, limit = 10)
    return "Navyki ne naydeny" if skills_array.nil? || skills_array.empty?
    
    skills_array.first(limit).map.with_index(1) do |(skill, count), idx|
      "  #{idx}. #{skill} — vstrechaetsya v #{count} vakansiyah"
    end.join("\n")
  end
  
  def self.format_top_employers(employers_array, limit = 5)
    return "Net dannyh" if employers_array.nil? || employers_array.empty?
    
    employers_array.first(limit).map.with_index(1) do |(name, count), idx|
      "  #{idx}. #{name} — #{count} vakansiy"
    end.join("\n")
  end
  
  def self.short_teaser(vacancies_count, avg_salary, median_salary, top_skills)
    text = "REZULTATY ANALIZA\n\n"
    text += "Vsego vakansiy: #{vacancies_count}\n"
    text += "Srednyaya zarplata: #{avg_salary.to_i} rub.\n"
    text += "Mediannaya zarplata: #{median_salary.to_i} rub.\n\n"
    
    if top_skills && !top_skills.empty?
      text += "Samye chastye navyki:\n"
      text += format_top_skills(top_skills, 3)
    end
    
    text
  end
  
  def self.full_statistics(data)
    text = "POLNAYA STATISTIKA\n\n"
    text += "Zarplata:\n"
    text += "  Srednyaya: #{data[:average_salary].to_i} rub.\n"
    text += "  Mediannaya: #{data[:median_salary].to_i} rub.\n\n"
    text += "Opyt raboty:\n"
    text += format_experience(data[:experience]) + "\n\n"
    text += "Grafik raboty:\n"
    text += format_schedule(data[:schedule]) + "\n\n"
    text += "Top rabotodateley:\n"
    text += format_top_employers(data[:top_employers], 5) + "\n\n"
    text += "Top navykov (vse):\n"
    text += format_top_skills(data[:top_skills], 10)
    text
  end
end
