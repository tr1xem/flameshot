#!/bin/bash

random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 7)
#Set it to screen audio by default 
audiodev="alsa_output.pci-0000_00_1b.0.analog-stereo.monitor"
focused_window=$(hyprctl activewindow)
app_name=$(echo "$focused_window" | grep "class:" | awk '{print $2}')
file="${random_string}-${app_name}"
output_file=~/Videos/Recordings/"${file}.mp4"

mkdir -p ~/Videos/Recordings

wl-screenrec --audio --audio-device "$audiodev" -f "$output_file" -g "$(slurp -d)" &

recording_pid=$!

cleanup() {
    pkill -USR2 -x record-screend  
    wait $recording_pid  
    notify-send "Uploading.." -a "wl-screenrec" 

    json_data=$(curl -s -F "secret=TOKEN" -F "file=@$output_file" "HOST")
    status=$(echo "$json_data" | jq -r '.status')

    if [[ $status == "error" ]]; then
        message=$(echo "$json_data" | jq -r '.message')
        notify-send "$message" -a "wl-screenrec" && exit 1
    fi

    video_url=$(echo "$json_data" | jq -r '.data.url')
    echo -n $video_url | xclip -sel c
    notify-send "Video URL copied to clipboard" "$video_url" -a "wl-screenrec"
}


trap cleanup SIGINT

wait $recording_pid

cleanup
