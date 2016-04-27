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

$repl_tbl = {
  /０/ => '0', /１/ => '1', /２/ => '2', /３/ => '3', /４/ => '4',
  /５/ => '5', /６/ => '6', /７/ => '7', /８/ => '8', /９/ => '9',
  /＋/ => '+', /－/ => '-', /×/ => '*', /÷/ => '/', /＊/ => '*'
}
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
  list = str.split("\n")
  if list.count >= 2
    return list.map { |s| str_to_hanshin(s) }.join("\n")
  end
  $repl_tbl.each do |k, v|
    str.gsub!(k, v)
  end
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
  md_fb = data['text'].strip.downcase.match(/^fizzbuzz ([0-9\+\-\*\/\(\)]+)$/)
  unless md_fb.nil?
    v = expr_to_v(md_fb[1])
    break if v.nil?
    v = 100 if v > 100
    han = Hanshin.new
    res = str_to_hanshin((1..v).map { |i| i % 3 == 0 ? (i % 5 == 0 ? 'FizzBuzz' : 'Fizz') : (i % 5 == 0 ? 'Buzz' : i) }.join(' '))
    rt_client.message text: res, channel: data['channel']
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

