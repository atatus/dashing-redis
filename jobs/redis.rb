require "redis"

redis_config = YAML.load File.open("redis.yml")
redis_host = redis_config[:redis_host]
redis_password = redis_config[:redis_password]

if redis_host.include? ":"
    t = redis_host.split(":")
    redis = Redis.new({:host => t[0], :port => t[1].to_i, :password => redis_password})
elsif redis_host[-5, 5] == ".sock"
    redis = Redis.new({ :path => redis_host })
end

SCHEDULER.every('5m', first_in: '1s') {
    info = redis.info

    send_event('redis_connected_clients', {
        current: info["connected_clients"],
        moreinfo: "Number of connected clients"
    })

    # Send memory usage stats in bytes
    send_event('redis_used_memory', {
        # Use peak memory as maximum in case no hard limit was defined in redis.conf
        max: [info["used_memory_peak"].to_i, redis.config("GET", "maxmemory")[1].to_i].max,
        value: info["used_memory"].to_i
    })
}