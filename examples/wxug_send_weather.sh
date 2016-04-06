#!/bin/bash

WXUG_PASSWORD=""
WXUG_ID=""
WXUG_ACTION=""
WXUG_DATEUTC=""

# Read sensor
TEMP_RH=$(PATH_TO_READ_SENSOR)

if [[ -z $TEMP_RH ]]; then
	echo "No data. Exiting."
	exit
fi

IFS=" "
TEMP_RH_ARR=($TEMP_RH)

CELSIUS=${TEMP_RH_ARR[0]}
FAHRENHEIT=$(echo "scale=2;((9/5) * $CELSIUS) + 32" | bc)
RH=${TEMP_RH_ARR[1]}

# Validate RH
if [[ ! $(echo "scale=3; $RH <= 100" | bc) -eq 1 ]]; then
	exit
fi

# Calculate Dew Point F
DEWPTC=$(echo "243.04*(l($RH/100)+((17.625*$CELSIUS)/(243.04+$CELSIUS)))/(17.625-l($RH/100)-((17.625*$CELSIUS)/(243.04+$CELSIUS)))" | bc -l)
DEWPTF=$(echo "scale=2; ($DEWPTC*1.8/1)+32" | bc)	# Divide by 1 to round to scale

echo "$FAHRENHEIT  tempf"
echo "$RH% humidity"
echo "$DEWPTF  dew point"

# Get recent nearby reading
EPOCH_NOW=$(date -d '5 minutes ago' +%s)
#NEARBY_TEMP_F=$(echo "select temp_f from db.table WHERE timestamp_utc > $EPOCH_NOW ORDER BY timestamp_utc DESC LIMIT 1" | mysql -sN -u user -ppass)

# Check to see if sensor's reading confirms nearby readings
if [ ! -z $NEARBY_TEMP_F ]; then	# Not Undefined
	DIFFERENCE=$(echo "$NEARBY_TEMP_F - $FAHRENHEIT" | bc)
	DIFFERENCE_ABSOLUTE=${DIFFERENCE#-}
	# Within threshold of x degrees?
	TEMP_IS_ACCEPTABLE=$(echo "$DIFFERENCE_ABSOLUTE < 10" | bc)
	if [ $TEMP_IS_ACCEPTABLE -eq 0 ]; then
		exit # Possible anamoly reading - do nothing
	fi
fi

echo "Sending..."
REQUEST="http://weatherstation.wunderground.com/weatherstation/updateweatherstation.php?action=updateraw&PASSWORD=$WXUG_PASSWORD&ID=$WXUG_ID&dateutc=$WXUG_DATEUTC&tempf=$FAHRENHEIT&humidity=$RH&dewptf=$DEWPTF"
echo $REQUEST
curl $REQUEST
