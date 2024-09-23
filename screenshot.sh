#!/bin/bash

#file name formatting
random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 7)
focused_window=$(hyprctl activewindow)
app_name=$(echo "$focused_window" | grep "class:" | awk '{print $2}')
time=$(date "+%d-%b_%H-%M-%S")
#file="${app_name}_${time}_${random_string}.png"
file="${random_string}-${app_name}.png"

temp_file="/tmp/${file}"
flameshot gui -r > $temp_file

#grim -g "$(slurp)" - >"$temp_file"

if [[ $(file --mime-type -b $temp_file) != "image/png" ]]; then
        rm $temp_file
        notify-send "Screenshot aborted" -a "Flameshot" && exit 1
#Uploading logics
fi
json_data=$(curl -s -F "secret=***"  -F "file=@/tmp/${file}" "host url")
status=$(echo "$json_data" | jq -r '.status')

if [[ $status == "error" ]]; then
        message=$(echo "$json_data" | jq -r '.message')
        notify-send "$message" -a "Flameshot" && exit 1
fi
image_url=$(echo "$json_data" | jq -r '.data.url')

echo -n $image_url | xclip -sel c
notify-send "Image URL copied to clipboard" "$image_url" -a "Flameshot" -i $temp_file
rm $temp_file
