require 'slack-ruby-client'
require 'logger'
require './hanshin'


FileUtils.mkdir('log') unless FileTest.exist?('log')
log = Logger.new('log/slack-hanshin.log')

Slack.configure do |conf|
  conf.token = File.read('slack-token').chomp
end

wb_client = Slack::Web::Client.new(logger: Logger.new('log/wb-client.log'))

hanshin = Hanshin.new

ops = ['+', '-', '*', '/']
ops.each do |op1|
  ops.each do |op2|
    expr = "3#{op1}3#{op2}4"
    hanshin.set expr
  end
end

