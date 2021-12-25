require 'tesla_api'
require_relative '../lib/message_processor'

describe MessageProcessor do
  context '#run' do
    let(:max_retries) { 3 }
    let(:arg1) { :irrelevant_argument_1 }
    let(:arg2) { :irrelevant_argument_2 }
    let(:access_token) { :irrelevant_access_token }
    let(:supported_method_name) { :some_method }
    let(:method_arguments) { [arg1, arg2] }
    let(:vehicle1) do
      double(TeslaApi::Vehicle,
             public_methods: [supported_method_name],
             some_method: nil,
             wake_up: nil)
    end
    let(:vehicle2) {nil}
    let(:api) { double(TeslaApi::Client, vehicles: [vehicle1, vehicle2]) }

    let(:json_message) {
      {
        access_token: access_token,
        method: supported_method_name.to_s,
        vehicle_id: 0,
        arguments: method_arguments
      }
    }

    subject {MessageProcessor.new(json_message, max_retries)}

    before do
      allow(TeslaApi::Client).to receive(:new).with(access_token: access_token).and_return(api)
    end

    it 'initializes the API only once' do
      expect(TeslaApi::Client).to receive(:new).with(access_token: access_token).once.and_return(api)

      subject.run
      subject.run
    end

    context 'with unsupported Tesla API method' do
      before do
        allow(vehicle1).to receive(:public_methods).and_return([])
      end

      it 'does nothing' do
        subject.run
      end
    end

    context 'with supported Tesla API method' do
      it 'wakes up the car before invoking the requested method' do
        expect(vehicle1).to receive(:wake_up).once

        subject.run
      end

      it 'calls method with specified arguments' do
        expect(vehicle1).to receive(supported_method_name).with(*method_arguments).once

        subject.run
      end
    end

    context 'with errors risen' do
      it 'retries specified times' do
        expect(vehicle1).to receive(:wake_up).exactly(max_retries + 1).times
        expect(vehicle1).to receive(supported_method_name).
          with(*method_arguments).
          exactly(max_retries + 1).times.
          and_raise(StandardError)

        expect { subject.run }.to raise_error(MessageProcessorError)
      end

      it 'returns expected result if retries are not exceeded' do
        expect(vehicle1).to receive(:wake_up).exactly(2).times
        expect(vehicle1).to receive(supported_method_name).with(*method_arguments).once.and_raise(StandardError).ordered
        expect(vehicle1).to receive(supported_method_name).with(*method_arguments).once.and_return(:response).ordered

        expect(subject.run).to eq(:response)
      end
    end
  end
end