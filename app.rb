require 'slack-ruby-client'
require 'logger'
require 'json'
require './hanshin'
require './rat-evaluator'


FileUtils.mkdir('log') unless FileTest.exist?('log')
log = Logger.new('log/slack-hanshin.log')

Slack.configure do |conf|
  conf.token = File.read('slack-token').chomp
end

wb_client = Slack::Web::Client.new(logger: Logger.new('log/wb-client.log'))
rt_client = Slack::RealTime::Client.new(logger: Logger.new('log/rt-client.log'))

$hanshin = Hanshin.new
$rat = RatEvaluator.new
channels = JSON.parse(File.read('channels'))

p_expr = /^(.*?)([0-9\+\-\*\/\(\)]+)/

def expr_to_v(expr)
  $hanshin.set expr
  begin
    v = $rat.eval(expr).numerator
  rescue
    return nil
  end
  return nil if v.denominator != 1
  return v.numerator
end

rt_client.on :message do |data|
  next if data['user'] == rt_client.self['id']
  next unless channels.include?(data['channel'])
  str = data['text']
  md = str.match(p_expr)
  next if md.nil?
  text = ''
  post = false
  if md[2] == str
    v = expr_to_v(md[2])
    post = true unless v.nil?
    expr = $hanshin.get(v)
    text += (expr.nil?) ? v : expr
  else
    until md.nil?
      v = expr_to_v(md[2])
      post = true unless v.nil?
      expr = (v.nil?) ? nil : $hanshin.get(v)
      text += md[1] + ' ('
      text += (expr.nil?) ? v : expr
      text += ') '
      str = str[(md[0].length)..(str.length)]
      md = str.match(p_expr)
    end
    text += str
  end
  rt_client.message text: text, channel: data['channel'] if post
end

rt_client.start!

