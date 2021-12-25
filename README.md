# mqttesla
MQTT to Tesla gateway. It subscribes to a MQTT topic and forwards the received messages to the [Tesla API](https://github.com/timdorr/tesla-api).

## Dependencies
A `Gemfile` is provided, so [bundler](https://bundler.io/) is required, along with [Ruby](https://www.ruby-lang.org/en/downloads/).

## Usage
A launcher, `main.rb`, is included. It uses the following environment variables:
 * `MQTT_HOST` the host hosting the MQTT server. Defaults to `127.0.0.1`.
 * `MQTT_PORT` port of the MQTT server. Defaults to MQTT default: `1883`.
 * `MQTT_SSL` enables SSL connection with the MQTT server when set to `true`
 * `MQTT_TOPIC` the topic to subscribe for receiving messages. Defaults to `mqttesla`
 * `MAX_API_RETRIES` the number of retries when an API call fails for any reason.

```shell
MQTT_HOST=192.168.2.2 bundle exec ruby main.rb
```

## Message format
Mqttesla expects JSON messages with the following fields:
 * `access_token`: a valid API token for tesla-api. See the [tesla-api readme](https://github.com/timdorr/tesla-api#usage).
 * `method`: method of the API to be called. See [this](https://github.com/timdorr/tesla-api/blob/e17a447c65e1441f9fcfc687576ce99534384148/lib/tesla_api/vehicle.rb) for references.
 * `arguments`: array of arguments to be passed to `method`
 * `vehicle_id`: The index of the array of vehicles returned by `TeslaApi::Client#vehicles`. You will only havee trouble here if you are lucky enough to own more than one Tesla. `0` should work for most cases, LOL.

### Examples
For reducing the charge power:
```json
{
    "access_token": "i_wont_share_my_token_with_you",
    "method": "set_charging_amps",
    "arguments": [10],
    "vehicle_id": 0,
}
```
or for stopping the charge:
```json
{
    "access_token": "i_wont_share_my_token_with_you",
    "method": "charge_stop",
    "arguments": [],
    "vehicle_id": 0,
}
```
Those messages can be easily sent to MQTT server using `mosquitto-client`, that can be downloaded from [its website](https://mosquitto.org/download/):
```shell
MESSAGE='{
    "access_token": "i_wont_share_my_token_with_you",
    "method": "set_charging_amps",
    "arguments": [10],
    "vehicle_id": 0
}'
mosquitto_pub -h 192.168.2.2 -t mqttesla -m "$MESSAGE"
```

## Recommendations
If you install [TeslaMate](https://github.com/adriankumpf/teslamate), it takes care of maintaining a valid and updated `token` in its database that can be obtained with the following query to its database:
```postgresql
SELECT access FROM tokens LIMIT 1;
```
It also provides interesting stats about the car.
![](https://github.com/adriankumpf/teslamate/blob/master/website/static/screenshots/drive.png?raw=true)

[Nodered](https://nodered.org/) can help you create your own rules for managing the car based on different inputs, such as power meters for solar production or instant power consumption at home.