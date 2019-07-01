#!/bin/bash

flowusername="useremail@location.com"
flowpassword="yourpassword"

cd /home/ajorians/temp

rm KLAN.xml
wget http://w1.weather.gov/xml/current_obs/KLAN.xml

getxml() { # $1 = xml file, $2 = xpath expression
    echo "cat $2" | xmllint --shell $1 |\
    sed -n 's/[^\"]*\"\([^\"]*\)\"[^\"]*/\1/gp'
}

read_dom () {
    local IFS=\>
    read -d \< ENTITY CONTENT
}

postwalkiemessage () {
  #Replace double quotes with escaped ones such that I can do a REST post
   local message=$(echo $1|sed 's/\"/\\\"/g')

   local exactmessage="$message"

   local postdata="{\"event\":\"message\",\"external_user_name\":\"BillWaterson\",\"content\":\"$exactmessage\"}"


local result=$(curl --header "Content-Type: application/json" \
  --request POST \
  --data "$postdata" \
  -u "$flowusername:$flowpassword" \
  https://api.flowdock.com/flows/$2/$3/messages)

local id=$(echo $result | jq '.id')

echo "$id"

   local emojipostdata="{\"type\": \"add\", \"emoji\": \"footprints\" }"

curl --header "Content-Type: application/json" \
  --request POST \
  --data "$emojipostdata" \
  -u "$flowusername:$flowpassword" \
  https://api.flowdock.com/flows/$2/$3/messages/$id/emoji_reaction

}

filename=$(find KLAN.xml)

if [ -n "$filename" ]; then
	echo $filename
	fullpath="/home/aorians/Temp/$filename"
	echo $fullpath

        tempf="";
        while read_dom; do
           if [[ $ENTITY = "temp_f" ]] ; then
              tempf=$CONTENT
           fi
        done < KLAN.xml

	tempc="";
	while read_dom; do
           if [[ $ENTITY = "temp_c" ]] ; then
              tempc=$CONTENT
           fi
        done < KLAN.xml

        resultk=$(echo "scale=2; $tempc+273.15" | bc)
        tempk=$resultk
	#echo "IN KELVIN: $tempk"

        temperature_string="";
        while read_dom; do
           if [[ $ENTITY = "temperature_string" ]] ; then
              temperature_string=$CONTENT
           fi
        done < KLAN.xml

        wind_string="";
        while read_dom; do
           if [[ $ENTITY = "wind_string" ]] ; then
              wind_string=$CONTENT
           fi
        done < KLAN.xml

        weather_string="";
        while read_dom; do
           if [[ $ENTITY = "weather" ]] ; then
              weather_string=$CONTENT
           fi
        done < KLAN.xml

	year=`date +"%Y"`
        year=$(echo "$year-28" | bc)

        comic=`date +"http://camtasiatest.techsmith.com/a.orians/calvinhobbes/$year%m%d.gif"`

        message="Current weather conditions: $weather_string $temperature_string ($tempk K) with wind: $wind_string #walkies $comic"

	echo $message

   postwalkiemessage "$message" "techsmith" "camtasia-win"
   postwalkiemessage "$message" "techsmith" "rimshot"
   postwalkiemessage "$message" "techsmith" "macdevroom"
   postwalkiemessage "$message" "techsmith" "relay-wordz-n-stuff"

fi


