##
# Connect Redis Cloud
if Rails.application.secrets.redis_uri
    $redis = Redis.new(url: Rails.application.secrets.redis_uri)
end
