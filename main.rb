require 'mqtt'
require 'tesla_api'
require_relative 'lib/mqttesla'

def log_device
  ENV['LOG_DEVICE']&.upcase == 'STDOUT' ? STDOUT : STDERR
end


mqtt_host = ENV['MQTT_HOST'] || '127.0.0.1'
mqtt_port = ENV['MQTT_PORT'] || '1883'
mqtt_ssl = ENV['MQTT_SSL'] == 'true'
mqtt_topic = ENV['MQTT_TOPIC'] || 'mqttesla'
max_api_retries = ENV['MAX_API_RETRIES'] || 3

mqtt = MQTT::Client.connect(
  host: mqtt_host,
  port: mqtt_port,
  ssl: mqtt_ssl
)

logger = Logger.new(log_device)

logger.info { "Starting MQTTesla listening on #{mqtt_ssl ? 'mqtts' : 'mqtt'}://#{mqtt_host}:#{mqtt_port}/#{mqtt_topic}" }
Mqttesla.new(
  mqtt_client: mqtt,
  logger: logger,
  mqtt_topic: mqtt_topic
).start(max_retries: max_api_retries)
