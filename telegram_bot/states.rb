
require 'json'

class StatesManager
  def initialize(storage_file = 'bot_data.json')
    @storage_file = storage_file
    @user_states = {}
    @user_data = {}
    load_data
  end

  IDLE = :idle
  AWAITING_KEYWORD = :awaiting_keyword

  def get(user_id)
    @user_states[user_id.to_s] || IDLE
  end

  def set(user_id, state)
    @user_states[user_id.to_s] = state
    save_data
  end

  def clear(user_id)
    @user_states.delete(user_id.to_s)
    @user_data.delete(user_id.to_s)
    save_data
  end

  def save_search_result(user_id, keyword, data)
    @user_data[user_id.to_s] = {
      keyword: keyword,
      data: data,
      timestamp: Time.now.to_i
    }
    save_data
  end

  def get_last_search(user_id)
    data = @user_data[user_id.to_s]
    if data && (Time.now.to_i - data[:timestamp]) < 1800
      data
    else
      nil
    end
  end

  private

  def load_data
    if File.exist?(@storage_file)
      data = JSON.parse(File.read(@storage_file), symbolize_names: true)
      @user_states = data[:user_states] || {}
      @user_data = data[:user_data] || {}
    end
  rescue => e
    puts "Error loading data: #{e.message}"
    @user_states = {}
    @user_data = {}
  end

  def save_data
    File.write(@storage_file, JSON.pretty_generate({
      user_states: @user_states,
      user_data: @user_data
    }))
  rescue => e
    puts "Error saving data: #{e.message}"
  end
end

# Create global instance for backward compatibility
States = StatesManager.new
