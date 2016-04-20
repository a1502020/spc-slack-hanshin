require 'slack-ruby-client'
require 'logger'
require 'json'
require 'date'
require './hanshin'


FileUtils.mkdir('log') unless FileTest.exist?('log')
log = Logger.new('log/slack-procon.log')

Slack.configure do |conf|
  conf.token = File.read('slack-token').chomp
end

wb_client = Slack::Web::Client.new(logger: Logger.new('log/procon-wb-client.log'))

hanshin = Hanshin.new

channels = JSON.parse(File.read('channels'))

day_procon = Date.new(2016, 10, 8)
dt_diff = day_procon - Date.today
days = dt_diff.numerator

if days >= -1
  if days == 0
    text = "プロコン #{hanshin.get(1)} 日目です！頑張ってください！"
  elsif days == -1
    text = "プロコン #{hanshin.get(2)} 日目です！頑張ってください！"
  else
    expr = hanshin.get(days)
    text = "プロコンまであと #{expr} 日です。"
  end

  wb_client.chat_postMessage text: text, channel: channels[0], as_user: true
end

