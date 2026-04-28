# telegram_bot/bot.rb
require 'faraday'
require 'telegram/bot'
require_relative 'states'
require_relative 'ui_helpers'

TOKEN = '8765953866:AAENBh7dMB5yzEwJWcpCp9PWOooypxSAmOg'

puts "Initializing bot..."

def send_main_menu(bot, chat_id)
  keyboard = [
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Search Vacancies", callback_data: "search"),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Statistics", callback_data: "stats")
    ],
    [
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "Help", callback_data: "help"),
      Telegram::Bot::Types::InlineKeyboardButton.new(text: "About", callback_data: "about")
    ]
  ]

  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

  bot.api.send_message(
    chat_id: chat_id,
    text: "Main Menu\n\nI can analyze job vacancies from HH.ru",
    reply_markup: markup
  )
end

def send_help(bot, chat_id)
  help_text = """
Help Information

Available commands:
/search - start searching for vacancies
/help - show this help

How to use:
1. Press 'Search Vacancies' button or type /search
2. Enter a profession (e.g., Ruby, Python, Java)
3. Get statistics and HTML report

Examples:
- Ruby developer
- Python
- Java backend
  """

  bot.api.send_message(chat_id: chat_id, text: help_text)
  send_main_menu(bot, chat_id)
end

def process_search(bot, chat_id, keyword)
  States.set(chat_id, States::IDLE)

  bot.api.send_chat_action(chat_id: chat_id, action: 'typing')

  bot.api.send_message(
    chat_id: chat_id,
    text: "Analyzing '#{keyword}'. Loading data from HH.ru, please wait..."
  )

  result = JobMarketAnalytics.analyze_and_report(keyword)

  if result[:error]
    bot.api.send_message(chat_id: chat_id, text: "Error: #{result[:error]}")
  else
    report = UiHelpers.short_teaser(
      result[:vacancies_count],
      result[:average_salary],
      result[:median_salary],
      result[:top_skills]
    )

    keyboard = [
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "Full Statistics",
          callback_data: "full_stats:#{keyword}"
        ),
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "Save Result",
          callback_data: "save:#{keyword}"
        )
      ],
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: "New Search",
          callback_data: "new_search"
        )
      ]
    ]

    markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)

    bot.api.send_message(
      chat_id: chat_id,
      text: report,
      reply_markup: markup
    )

    bot.api.send_document(
      chat_id: chat_id,
      document: Faraday::UploadIO.new(result[:report_path], 'text/html')
    )

    States.save_search_result(chat_id, keyword, result)
  end

  send_main_menu(bot, chat_id)
end

def handle_callback(bot, callback_query)
  chat_id = callback_query.message.chat.id
  message_id = callback_query.message.message_id
  data = callback_query.data

  bot.api.answer_callback_query(callback_query_id: callback_query.id)

  case data
  when "search"
    States.set(chat_id, States::AWAITING_KEYWORD)
    bot.api.send_message(chat_id: chat_id, text: "Enter profession name:")
  when "stats"
    last_search = States.get_last_search(chat_id)
    if last_search
      bot.api.send_message(chat_id: chat_id, text: "Last search: #{last_search[:keyword]}")
    else
      bot.api.send_message(chat_id: chat_id, text: "No previous searches found. Press 'Search Vacancies' first.")
    end
  when "help"
    send_help(bot, chat_id)
    return
  when "about"
    bot.api.send_message(
      chat_id: chat_id,
      text: "Bot: HH.ru Vacancy Analyzer\nVersion: 1.0\n\nAnalyzes job market and helps find best offers"
    )
  when "new_search"
    States.set(chat_id, States::AWAITING_KEYWORD)
    bot.api.send_message(chat_id: chat_id, text: "Enter new profession for search:")
  when /^save:(.+)$/
    keyword = $1
    bot.api.send_message(chat_id: chat_id, text: "Search result for '#{keyword}' saved to history")
  when /^full_stats:(.+)$/
    keyword = $1
    bot.api.send_message(chat_id: chat_id, text: "Loading full statistics for '#{keyword}'...")
  end

  bot.api.edit_message_reply_markup(
    chat_id: chat_id,
    message_id: message_id,
    reply_markup: nil
  )
end

# Main bot loop
begin
  Telegram::Bot::Client.run(TOKEN) do |bot|
    puts "Bot is running. Waiting for messages..."

    # Handle text messages
    Thread.new do
      begin
        bot.listen do |message|
          begin
            next unless message.text

            chat_id = message.chat.id
            text = message.text

            puts "Received from #{chat_id}: #{text}"

            case text
            when "/start"
              send_main_menu(bot, chat_id)
            when "/search"
              States.set(chat_id, States::AWAITING_KEYWORD)
              bot.api.send_message(chat_id: chat_id, text: "Enter profession name (e.g., Ruby developer):")
            when "/help"
              send_help(bot, chat_id)
            else
              if States.get(chat_id) == States::AWAITING_KEYWORD
                process_search(bot, chat_id, text)
              else
                send_main_menu(bot, chat_id)
              end
            end
          rescue => e
            puts "Error processing message: #{e.message}"
            puts e.backtrace
          end
        end
      rescue => e
        puts "Error in message listener thread: #{e.message}"
      end
    end

    # Handle button callbacks
    Thread.new do
      begin
        bot.listen do |callback_query|
          begin
            handle_callback(bot, callback_query)
          rescue => e
            puts "Error processing callback: #{e.message}"
            puts e.backtrace
          end
        end
      rescue => e
        puts "Error in callback listener thread: #{e.message}"
      end
    end

    sleep
  end
rescue => e
  puts "Fatal error: #{e.message}"
  puts e.backtrace
end
