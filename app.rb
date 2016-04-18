require 'slack-ruby-client'
require 'logger'
require 'json'
require './hanshin'


FileUtils.mkdir('log') unless FileTest.exist?('log')
log = Logger.new('log/slack-hanshin.log')

Slack.configure do |conf|
  conf.token = File.read('slack-token').chomp
end

wb_client = Slack::Web::Client.new(logger: Logger.new('log/wb-client.log'))
rt_client = Slack::RealTime::Client.new(logger: Logger.new('log/rt-client.log'))

hanshin = Hanshin.new

channels = JSON.parse(File.read('channels'))

rt_client.on :message do |data|
  next unless channels.include?(data['channel'])
  md = /([1-9][0-9]*)/.match(data['text'])
  next if md.nil?
  v = md[1].to_i
  expr = hanshin.get(v)
  if expr.nil?
    rt_client.message text: 'わかんない＞＜', channel: data['channel']
  else
    rt_client.message text: expr, channel: data['channel']
  end
end

rt_client.start!

