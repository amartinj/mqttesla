class MessageProcessorError < StandardError; end

class MessageProcessor
  def initialize(json_message, max_retries)
    @json_message = json_message
    @max_retries = max_retries
  end

  def run
    retries = 0
    begin
      return unless method_supported?
      vehicle.wake_up
      vehicle.public_send(method_name, *method_arguments)
    rescue StandardError => e
      retry if (retries += 1) <= max_retries
      raise MessageProcessorError.new(e)
    end
  end

  private
  attr_reader :max_retries

  def method_supported?
    vehicle.public_methods.include?(method_name)
  end

  def vehicle
    api.vehicles[vehicle_id]
  end

  def api
    @api ||= TeslaApi::Client.new(access_token: access_token)
  end

  def access_token
    @json_message[:access_token]
  end

  def vehicle_id
    @json_message[:vehicle_id]
  end

  def method_name
    @json_message[:method].to_sym
  end

  def method_arguments
    @json_message[:arguments]
  end
end
