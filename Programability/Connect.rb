require './environment'
require 'mysql2'
require 'aws-sdk-v1'

#Connect to the Database 
#Something Something Something
@db_host = ENV['db_host']
@db_user = ENV['db_user']
@db_pass = ENV['db_password']
@db_name = ENV['db_name']


@db = Mysql2::Client.new(:host => @db_host, :username => @db_user, :password => @db_pass, :database => @db_name)

#Connect to the queue
AWS.config(:access_key_id => ENV['access_key_id'], :secret_access_key => ENV['secret_access_key'])
sqs = AWS::SQS.new
url = ENV['sqs-url']
@queue = sqs.queues[url]