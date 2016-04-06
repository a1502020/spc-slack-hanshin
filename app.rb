require 'slack-ruby-client'
require 'logger'


FileUtils.mkdir('log') unless FileTest.exist?('log')
log = Logger.new('log/slack-hanshin.log')

Slack.configure do |conf|
  conf.token = File.read('slack-token').chomp
end

wb_client = Slack::Web::Client.new(logger: Logger.new('log/wb-client.log'))

p wb_client.auth_test

