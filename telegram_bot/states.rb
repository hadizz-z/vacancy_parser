module States
  IDLE = :idle
  AWAITING_KEYWORD = :awaiting_keyword
  
  @user_states = {}
  @user_data = {}
  
  def self.get(user_id)
    @user_states[user_id] || IDLE
  end
  
  def self.set(user_id, state)
    @user_states[user_id] = state
  end
  
  def self.clear(user_id)
    @user_states.delete(user_id)
  end
  
  def self.save_data(user_id, keyword, data)
    @user_data[user_id] = {
      keyword: keyword,
      data: data,
      timestamp: Time.now
    }
  end
  
  def self.get_data(user_id)
    data = @user_data[user_id]
    if data && (Time.now - data[:timestamp]) < 1800
      data
    else
      nil
    end
  end
end
