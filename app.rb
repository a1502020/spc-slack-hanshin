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

p = /^(.*?)(-?[0-9]+)/

rt_client.on :message do |data|
  next if data['user'] == rt_client.self['id']
  next unless channels.include?(data['channel'])
  str = data['text']
  md = str.match(p)
  next if md.nil?
  text = ''
  if md[2] == str
    v = md[2].to_i
    expr = hanshin.get(v)
    text += (expr.nil?) ? v : expr
  else
    until md.nil?
      v = md[2].to_i
      expr = hanshin.get(v)
      text += md[1] + ' ('
      text += (expr.nil?) ? v : expr
      text += ') '
      str = str[(md[0].length)..(str.length)]
      md = str.match(p)
    end
    text += str
  end
  rt_client.message text: text, channel: data['channel']
end

rt_client.start!

