 Enverbridge stats collector [Lets-try-Solar][Lts]

get_solar.pl is a script to collect stats from the Envertec portal and will push these metrics into a InfluxDB. Additionally the script can send the data to a MQTT broker and to a CCU2.

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
  - ccu2_switch: switch if data should be send to a ccu2
  - ccu2: ccu2 IP
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
    "mqttswitch" : "n",
    "mqttbroker" : "MQTT-BROKER-IP",
    "mqttport" : "1883",
    "ccu2_switch" : "n",
    "ccu2" : "CCU2-IP",
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

### MQTT

To enable MQTT you have to configure the following variables in the config file.

  - mqttswitch: switch if mqtt should be used (y for yes and n for no)
  - mqttbroker: MQTT broker IP
  - mqttport: MQTT broker port

### CCU2

##### Requirements:

XML-API CCU Addon https://github.com/hobbyquaker/XML-API

To send data to a CCU you need to configure the following variables in the config file.

  - ccu2_switch: switch if data should be send to a ccu2
  - ccu2: ccu2 IP
 
Additionally the following variables have to be created in the CCU.

| Name | Description | Variable type | 
| ------ | ------ | ------ |
| allpower | Solar Gesamt Erzeugt | Number | 
| capacity | Solar Capacity | Number | 
| daypower | Solar daypower | Number | 
| efficiency | Solar efficiency | Number |
| etoday | Solar Etoday | Number | 
| income | Solar income | Number | 
| invtotal | Solar InvTotal | Number |
| monthpower | Solar monthpower | Number | 
| nowpower | Solar nowpower | Number | 
| nowpower_ | Solar _nowpower | Number | 
| peakpower | Solar Peakpower | Number | 
| power | Solar power | Number | 
| powerstr | Solar PowerStr | Number |
| strpeakpower | Solar StrPeakPower | Number |
| yearpower | Solar yearpower | Number | 

The script will read the variables from the CCU and use the IDs to update the variables.

### Todos

 - Bundle script into Docker container

License
----

MIT

   [Lts]: <https://www.lets-try-solar.de>
