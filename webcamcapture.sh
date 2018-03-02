#!/bin/bash

while true; do
  # Set the output folder and filename to store the image
  outputfolder=/tmp/webcam/
  filename=webcam-$(date +"%Y%m%d-%H%M%S").jpg

  # URL Encode the MapR Volume path to use in the MapR Streams REST API
  MAPR_VOLUME_URLENCODED=$(echo $MAPR_VOLUME | sed -e "s|/|%2F|g")
  MAPR_STREAM_URLENCODED=$(echo $MAPR_STREAM | sed -e "s|/|%2F|g")
  MAPR_IMAGE_URLENCODED=$(echo $MAPR_IMAGE | sed -e "s|/|%2F|g")

  # Check if the webcam is connected
  #if [ -f "/dev/video0" ]
  #then
    # Capture a webcam image
    fswebcam -d /dev/video0 --resolution 640x480 --jpeg 85 --frames 1 $outputfolder/$filename

    # Check if the webcam successfully created an image, if so push it to MapR
    if [ -f "$outputfolder/$filename" ]
    then
      # Push the captured image to MapR-FS
      curl -i -X PUT "http://$MAPR_HOST:14000/webhdfs/v1$MAPR_VOLUME$MAPR_IMAGE$filename?op=CREATE&permission=444&user.name=mapr"
      curl -i -X PUT -T $outputfolder/$filename -H "Content-Type:application/octet-stream" "http://$MAPR_HOST:14000/webhdfs/v1$MAPR_VOLUME$MAPR_IMAGE$filename?op=CREATE&overwrite=true&op=SETPERMISSION&permission=444&data=true&user.name=mapr"

      # Push an event on MapR Streams to tell a new image has been uploaded
      echo "Pushing new file ('"$filename"') event on MapR Streams using Kafka REST API"
      curl -X POST -H "Content-Type: application/vnd.kafka.json.v1+json" \
         --data '{"records":[{"value": {"fileInfo": {"filename" : "'$filename'" , "path" : "'$outputfolder'"}}}]}' \
         http://$MAPR_USER:$MAPR_PASSWORD@$MAPR_HOST:8082/topics/$MAPR_VOLUME_URLENCODED$MAPR_STREAM_URLENCODED%3A$MAPR_STREAM_TOPIC
      echo "\nPush finished"

      # Once processed, remove the file to avoid the filesystem to fload
      echo "Removing file '"$filename"'"
      rm -rf $outputfolder/$filename

      # Logging to /tmp/webcam/webcam_docker.log
      echo "# MapR-FS REST API call:" >> /tmp/webcam/webcam_docker.log
      echo curl -i -X PUT "http://$MAPR_HOST:14000/webhdfs/v1$MAPR_VOLUME$MAPR_IMAGE$filename?op=CREATE&permission=444&user.name=mapr" > /tmp/webcam/webcam_docker.log
      echo curl -i -X PUT -T $outputfolder/$filename -H "Content-Type:application/octet-stream" "http://$MAPR_HOST:14000/webhdfs/v1$MAPR_VOLUME$MAPR_IMAGE$filename?op=CREATE&overwrite=true&op=SETPERMISSION&permission=444&data=true&user.name=mapr" >> /tmp/webcam/webcam_docker.log
      # Logging to /tmp/webcam/webcam_docker.log
      echo "# MapR Streams REST API call:" >> /tmp/webcam/webcam_docker.log
      echo curl -X POST -H "Content-Type: application/vnd.kafka.json.v1+json"  >> /tmp/webcam/webcam_docker.log
      echo   --data '{"records":[{"value": {"fileInfo": {"filename" : "'$filename'" , "path" : "'$outputfolder'"}}}]}'  >> /tmp/webcam/webcam_docker.log
      echo   http://$MAPR_USER:$MAPR_PASSWORD@$MAPR_HOST:8082/topics/$MAPR_VOLUME_URLENCODED$MAPR_STREAM_URLENCODED%3A$MAPR_STREAM_TOPIC >> /tmp/webcam/webcam_docker.log

    else
      echo "No webcam image found. Is the webcam connected? Pausing for 5 seconds"
    sleep 5
    fi
  #else
  # echo "No webcam connected to /dev/video0. Pausing for 5 seconds"
  #  sleep 5
  #fi
done;