require_relative 'message_processor'

class Mqttesla
  def initialize(
    mqtt_client: MQTT::Client.connect(),
    logger:Logger.new(STDOUT),
    mqtt_topic: 'mqttesla'
  )
    @mqtt_client = mqtt_client
    @logger = logger
    @mqtt_topic = mqtt_topic
  end

  def start(max_retries: 3)
    @mqtt_client.get(@mqtt_topic) do |_, raw_message|
      log_info(raw_message)
      result = process_message(JSON.parse(raw_message, symbolize_names: true), max_retries)
      log_info(result)
    end
  end

  private

  def process_message(message, max_retries)
    MessageProcessor.new(message, max_retries).run
  rescue MessageProcessorError => e
    log_error(e)
  end

  def log_info(message)
    @logger.info(self.class.name) { message }
  end

  def log_error(message)
    @logger.error(self.class.name) { message }
  end
end
