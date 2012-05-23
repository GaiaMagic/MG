require "redis"
require "redis-namespace"
require "redis/objects"

redis_config = YAML.load_file("#{Rails.root}/config/redis.yml")[Rails.env]

Redis::Objects.redis = Redis.new(:host => redis_config['host'], :port => redis_config['port'], :db => redis_config['db'])

Resque::Mailer.default_queue_name = "mailer"
Resque.redis = Redis.new(:host => redis_config['host'], :port => redis_config['port'], :db => redis_config['db'])
Resque.redis.namespace = "resque:mg_forum"
