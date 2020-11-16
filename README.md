# Enverbridge stats collector [Lets-try-Solar][Lts]

get_solar.pl is a script to collect stats from the Envertec portal and will push these metrics into a InfluxDB.

# Setup 

#### Clone the repository to your machine
```
git clone https://github.com/lets-try-solar/enverbridge.git
```
#### Enter the directory
```sh
cd enverbridge
```
#### Create a configuration file

  - id: keep it empty (the script will collect the stationID from the envertec portal automatically)
  - dbcon: IP of your InfluxDB host
  - database: InfluxDB database name
  - mqttswitch: switch if mqtt should be used (y for yes and n for no)
  - mqttbroker: MQTT broker IP
  - mqttport: MQTT broker port
  - influxtag: Influx tag for the metrics
  - username: The email address you are using to login to the Envertec portal
  - password: The password which you use on the Envertec portal

#### Configuration file example

```sh
vi envertech_config.json
```
```
{
    "id" : "",
    "dbcon" : "INFLUXDB:8086",
    "database" : "enverbridge",
    "influxtag" : "enverbridge",
    "mqttswitch" : "y",
    "mqttbroker" : "MQTT-BROKER-IP",
    "mqttport" : "1883",
    "username" : "EMAIL",
    "password" : "PASSWORD"
}
```

#### Make the script executable

 ```sh
 chmod +x get_solar.pl
```

# Execute the script

```sh
./get_solar.pl envertech_config.json
```

### Sample output
```
StationID: 1234
Capacity: 0.0
Etoday: 0.00
InvTotal: 0
power: 000.00
PowerStr: 000.00
income: 000.00
StrPeakPower: 000.00
monthpower: 00.00
daypower: 0.00
allpower: 0.00
yearpower: 000.00
```

### Todos

 - Bundle script into Docker container

License
----

MIT

   [Lts]: <https://www.lets-try-solar.de>

