require 'telegram/bot'
require 'dotenv/load'
require 'logger'
require 'vacancy_parser'

require_relative 'states'
require_relative 'ui_helpers'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::INFO

class VacancyBot
  def initialize
    @token = ENV['TELEGRAM_BOT_TOKEN']
    unless @token && @token != 'YOUR_BOT_TOKEN_HERE'
      puts "ERROR: TELEGRAM_BOT_TOKEN not set in .env file"
      exit
    end
    @cache = {}
    LOGGER.info("Bot initialized")
  end
  
  def run
    LOGGER.info("Starting bot...")
    Telegram::Bot::Client.run(@token) do |bot|
      LOGGER.info("Bot started!")
      bot.listen do |message|
        handle_message(bot, message) if message.text
      end
    end
  end
  
  private
  
  def handle_message(bot, message)
    user_id = message.from.id
    text = message.text.strip
    
    case text
    when '/start'
      start_command(bot, message)
    when '/search'
      start_search(bot, message)
    else
      state = States.get(user_id)
      if state == States::AWAITING_KEYWORD
        process_search(bot, message, text)
      else
        show_menu(bot, message)
      end
    end
  end
  
  def start_command(bot, message)
    States.clear(message.from.id)
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Job market analytics bot\nType /search to begin",
      reply_markup: menu_keyboard
    )
  end
  
  def menu_keyboard
    Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: [[{ text: '/search' }]],
      resize_keyboard: true
    )
  end
  
  def show_menu(bot, message)
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Choose action:",
      reply_markup: menu_keyboard
    )
  end
  
  def start_search(bot, message)
    States.set(message.from.id, States::AWAITING_KEYWORD)
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "Enter profession:",
      reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    )
  end
  
  def process_search(bot, message, keyword)
    chat_id = message.chat.id
    bot.api.send_message(chat_id: chat_id, text: "Searching for '#{keyword}'...")
    
    begin
      if defined?(JobMarketAnalytics) && JobMarketAnalytics.respond_to?(:analyze_and_report)
        result = JobMarketAnalytics.analyze_and_report(keyword)
      else
        result = mock_result(keyword)
      end
      
      text = UiHelpers.short_teaser(
        result[:vacancies_count],
        result[:average_salary],
        result[:median_salary],
        result[:top_skills]
      )
      
      bot.api.send_message(chat_id: chat_id, text: text)
    rescue => e
      bot.api.send_message(chat_id: chat_id, text: "Error: #{e.message}")
    end
    
    States.set(message.from.id, States::IDLE)
    show_menu(bot, message)
  end
  
  def mock_result(keyword)
    {
      vacancies_count: 42,
      average_salary: 150000,
      median_salary: 140000,
      top_skills: [["Ruby", 30], ["Rails", 25], ["SQL", 20]],
      top_employers: [["Yandex", 10], ["Tinkoff", 8]],
      experience: {"between1And3" => 20, "between3And6" => 15},
      schedule: {"remote" => 25, "fullDay" => 15}
    }
  end
end

if __FILE__ == 
  bot = VacancyBot.new
  bot.run
end
