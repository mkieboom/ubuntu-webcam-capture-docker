#!/bin/bash

# Kill finder docker if currently running
docker ps | awk '{ print $1,$2 }' | grep ubuntu-webcam-capture-docker | awk '{print $1 }' | xargs -I {} docker kill {}

# build the coaintainer
docker build -t mkieboom/ubuntu-webcam-capture-docker ~/ubuntu-webcam-capture-docker/

# Run the webcamp capture docker container
docker run -d \
--restart=always \
-v /tmp/webcam:/tmp/webcam \
--device /dev/video0:/dev/video0 \
-e MAPR_USER=mapr \
-e MAPR_PASSWORD=mapr \
-e MAPR_HOST=172.16.4.44 \
-e MAPR_VOLUME=/image-classification/input/ \
-e MAPR_IMAGE=images/ \
-e MAPR_STREAM=streams/imageclassification-stream \
-e MAPR_STREAM_TOPIC=image-events \
mkieboom/ubuntu-webcam-capture-docker
