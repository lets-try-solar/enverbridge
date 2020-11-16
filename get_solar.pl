#!/usr/bin/perl

use strict;
use warnings;
use diagnostics;
use LWP::Simple;                	# From CPAN
use JSON qw( decode_json );     	# From CPAN
use Data::Dumper;               	# Perl core module
use JSON::Parse 'parse_json';
use Encode qw(decode encode);
use JSON;
use File::Basename;
use Net::MQTT::Simple;

my $dirname = dirname(__FILE__);

# declare the perl command line flags/options we want to allow
my $configfile=$ARGV[0];

my $configjson;
{
  local $/; #Enable 'slurp' mode
  open my $fh, "<", $configfile;
  $configjson = <$fh>;
  close $fh;
}

# config json example enverbridge_config.json
#{
#	"id" : ,
#	"dbcon" : "",
#	"database" : "",
#	"influxtag" : "",
#	"username" : "",
#	"password" : ""
#}

my $configdata = decode_json($configjson);

my $id=$configdata->{'id'};				# ID from the Solarsystem
my $dbcon=$configdata->{'dbcon'};			# InfluxDB connection details
my $database=$configdata->{'database'};			# InfluxDB Database name
my $influxtag=$configdata->{'influxtag'};		# InfluxDB tag
my $mqttswitch=$configdata->{'mqttswitch'};             # MQTT Broker Switch on/off
my $mqttbroker=$configdata->{'mqttbroker'};             # MQTT Broker IP
my $mqttport=$configdata->{'mqttport'};                 # MQTT Broker Port
my $username=quotemeta($configdata->{'username'});	# Envertech portal username
my $password=quotemeta($configdata->{'password'});	# Envertech portal password

my $mqtt;

# mapping as the variable names have changed
my %mapping = (
	Power => 'power',
	StrIncome => 'income',
	UnitEMonth => 'monthpower',
	UnitEToday => 'daypower',
	UnitETotal => 'allpower',
	UnitEYear => 'yearpower',
);

# check if StationID is available from config file, if not query it from Envertec portal and update config file
if ($id eq "")
{
	get_stationID();
	open my $fh, ">", $configfile;
	print $fh "\{ \"id\" : \"$id\", \"dbcon\" : \"$dbcon\", \"database\" : \"$database\", \"influxtag\" : \"$influxtag\", \"username\" : \"$configdata->{'username'}\", \"password\" : \"$configdata->{'password'}\" \}";
	close $fh;
}

print "StationID: $id\n\n";

# connect to mqtt if selected
connect_mqtt();

# login to get cookie
my $cookie = qx(curl --silent --cookie-jar /tmp/cookies -o /dev/null -X POST -H "Content-Type: application/json" -X "Content-Length: 1000" 'https://www.envertecportal.com/apiaccount/login?username=$username&pwd=$password');
# get data from portal
my $response = qx(curl --silent --cookie /tmp/cookies -X POST -d "" 'https://www.envertecportal.com/ApiStations/getStationInfo?stationId=$id');

my $ref_hash = decode_json($response);
my $value;
print "Overall Status:\n\n";
foreach my $item($ref_hash->{'Data'}){
	delete $item->{'CreateYear'};
	delete $item->{'CreateMonth'};
	delete $item->{'Lng'}; 
	delete $item->{'TimeZone'};
	delete $item->{'UnitCapacity'};
	delete $item->{'Installer'};
	delete $item->{'CreateTime'};
	delete $item->{'PwImg'};
	delete $item->{'Lat'};
	delete $item->{'StationName'};
	delete $item->{'StrTrees'};
	delete $item->{'StrCO2'};
	foreach my $key (sort keys %{$item}) { 
		$item->{$key} =~ s/[^\d\.]//g; 
		$value = encode('UTF-8',$item->{$key});
		if ( exists $mapping{$key} ) {
			$key = $mapping{$key};
		}
		print "$key: $value\n";
		system "curl --output /dev/null --silent -i -XPOST 'http://$dbcon/write?db=$database' --data-binary '$key,tag=$influxtag value=$value'";
		send_mqtt($key,$value);
	}
}

print "\n";

$response = qx(curl --silent --cookie /tmp/cookies -X POST -d "" --data-raw 'page=1&perPage=20&orderBy=GATEWAYSN&whereCondition=%7B%22STATIONID%22%3A%22$id%22%7D' 'https://www.envertecportal.com/ApiInverters/QueryTerminalReal');
$ref_hash = decode_json($response);
my $ivcount =  $ref_hash->{'Data'}{'TotalCount'};
for (my $i = 0;$i <= ($ivcount-1); $i++) {
#	print Dumper $ref_hash->{'Data'}{'QueryResults'}[$i];
	foreach my $item($ref_hash->{'Data'}{'QueryResults'}[$i]){
		delete $item->{'ACCURRENCY'};
		delete $item->{'SNID'};
		delete $item->{'SITETIME'};
		delete $item->{'STATIONID'};
		delete $item->{'GATEWAYALIAS'};
		my $sn = $item->{'SN'};
		delete $item->{'SN'};
		print "Inverter: $sn\n\n";
		foreach my $key (sort keys %{$item}) {
                	$item->{$key} =~ s/[^\d\.]//g;
                	$value = encode('UTF-8',$item->{$key});
			$key = lc $key;
			print "$key: $value\n";
			system "curl --output /dev/null --silent -i -XPOST 'http://$dbcon/write?db=$database' --data-binary '$key,tag=$influxtag,inverter=$sn value=$value'";
			send_mqtt($key,$value);
		}
		print "\n";
	}
}

disconnect_mqtt();

sub connect_mqtt {
	if ( $mqttswitch eq "y" ) {
		print "Connect to MQTT broker\n\n";
		$mqtt = Net::MQTT::Simple->new("$mqttbroker:$mqttport");
	} else {
		print "MQTT not selected\n";
	}
}
sub send_mqtt {
	if ( $mqttswitch eq "y" ) {
		my $mqtt_key = shift;
		my $mqtt_value = shift;
		$mqtt->publish("/homeassistant/solar/$mqtt_key", $mqtt_value);
	}
}

sub disconnect_mqtt {
	if ( $mqttswitch eq "y" ) {
		print "Disconnect MQTT broker\n";
		$mqtt->disconnect();
	}
}

# Get StationID from Envertec portal
sub get_stationID {
	system "wget -qO- -o /dev/null --keep-session-cookies --save-cookies $dirname/cookies.txt --post-data 'username=$configdata->{'username'}&pwd=$configdata->{'password'}' https://www.envertecportal.com/apiaccount/login > /dev/null 2>&1";
	system "wget -q --load-cookies $dirname/cookies.txt 'https://www.envertecportal.com/terminal/systemoverview' -O $dirname/systemoverview > /dev/null 2>&1";

	my $sofile = "$dirname/systemoverview";
	open my $fh, '<', $sofile or die "Could not open '$sofile' $!\n";
	my $idtemp;
	while (my $line = <$fh>) {
        	chomp $line;
        	my @strings = $line =~ /(?:^|\s)(var stationId =+.*$)/g;
        	foreach my $s (@strings) {
                	$idtemp = $s;
        	}
	}
	close($fh);
	system "rm $dirname/systemoverview";
	my @parts = split '\'', $idtemp;
	$id = $parts[1];
}
