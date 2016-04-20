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

$p_expr = /^(.*?)([0-9\+\-\*\/\(\)]+)/

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

def str_to_hanshin(str)
  md = str.match($p_expr)
  return nil if md.nil?
  text = ''
  if md[2] == str
    v = expr_to_v(md[2])
    post = true unless v.nil?
    expr = (v.nil?) ? nil : $hanshin.get(v)
    text += (expr.nil?) ? ":no_good: #{v.to_s} :no_good:" : expr
  else
    until md.nil?
      v = expr_to_v(md[2])
      post = true unless v.nil?
      expr = (v.nil?) ? nil : $hanshin.get(v)
      text += md[1] + ' ('
      text += (expr.nil?) ? ":no_good: #{v.to_s} :no_good:" : expr
      text += ') '
      str = str[(md[0].length)..(str.length)]
      md = str.match($p_expr)
    end
    text += str
  end
  return post ? text : nil
end

rt_client.on :message do |data|
  next if data['user'] == rt_client.self['id']
  next unless channels.include?(data['channel'])
  if data['text'].strip == '33-4'
    rt_client.message text: 'なんでや！阪神関係ないやろ！', channel: data['channel']
    next
  end
  res = str_to_hanshin(data['text'])
  if res.nil?
    if data['text'].include?('時') || data['text'].include?('日')
      str = DateTime.now.strftime('%Y年%m月%d日 %H時%M分%S秒')
      rt_client.message text: str_to_hanshin(str), channel: data['channel']
    end
  else
    rt_client.message text: res, channel: data['channel']
  end
end

rt_client.start!

