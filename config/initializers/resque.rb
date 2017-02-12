rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'
ENV['REDIS_HOST'] ||= 'localhost'

Resque.redis = {host: ENV['REDIS_HOST'], port: 6379}
Resque.logger = Logger.new(Rails.root.join('log', "#{Rails.env}_resque.log"))