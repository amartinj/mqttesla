require_relative '../lib/mqttesla'
require 'mqtt'
require 'json'

describe Mqttesla do
  class DummyMqttClient
    def get(mqtt_topic, &block)
      @block = block
      @mqtt_topic = mqtt_topic
    end

    def receive_message(topic, message)
      @block.call(topic, message)
    end
  end

  let(:mqtt_client) { DummyMqttClient.new }
  let(:logger) { double(Logger, info: nil, error: nil) }
  let(:mqtt_topic) { 'mqttesla' }
  let(:json_message) { { irrelevant: 'json' } }
  let(:message) { json_message.to_json }
  let(:message_process_result) { :irrelevant_result }
  let(:message_processor) { double(MessageProcessor, run: message_process_result) }
  let(:max_retries) { 3 }

  subject { Mqttesla.new(mqtt_client: mqtt_client, logger: logger, mqtt_topic: mqtt_topic) }

  before do
    allow(MessageProcessor).to receive(:new).with(json_message, max_retries).and_return(message_processor)
  end

  after do
    mqtt_client.receive_message(mqtt_topic, message)
  end

  context '#start' do
    it 'binds to MQTT topic' do
      expect(mqtt_client).to receive(:get).with(mqtt_topic).once.and_call_original

      subject.start(max_retries: max_retries)
    end

    it 'logs the message and the result' do
      expect_logger_to_receive(:info, message)
      expect_logger_to_receive(:info, message_process_result)

      subject.start(max_retries: max_retries)
    end

    it 'processes received message' do
      expect(message_processor).to receive(:run).once

      subject.start(max_retries: max_retries)
    end

    it 'logs an error when an exception is thrown' do
      e = MessageProcessorError.new
      expect(message_processor).to receive(:run).and_raise(e).once
      expect_logger_to_receive(:error, e)

      subject.start(max_retries: max_retries)
    end

    shared_examples 'handles errors' do |error_message|
      it 'logs the error' do
        expect_logger_to_receive(:error, error_message)

        subject.start(max_retries: max_retries)
      end

      it 'does not raise the error' do
        subject.start(max_retries: max_retries)
      end
    end

    context 'and a JSONParser error occurs' do
      before { expect(JSON).to receive(:parse).and_raise(JSON::ParserError) }
      it_behaves_like 'handles errors', 'Invalid JSON message!!!'
    end

    context 'and an unexpected error occurs' do
      exception = StandardError.new
      before { expect(message_processor).to receive(:run).and_raise(exception) }
      it_behaves_like 'handles errors', "Unexpected error: #{exception}"
    end

    private
    def expect_logger_to_receive(level, message)
      expect(logger).to receive(level).with('Mqttesla') do |*_, &block|
        expect(Proc.new { message }.call).to eq(block.call)
      end.once.ordered
    end
  end
end
