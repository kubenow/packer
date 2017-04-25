#!/bin/bash

# This Script will be executed during the post-processor of the GCE packer builder
# It downloads the compressed image just created, extracts it and converts to a QCOW format (to be used for OpenStack providers)


#Donwloading kubenow-current compressed image from Google Storage
echo "\nDownloading kubenow compressed image from Google bucket..."
gsutil cp gs://kubenow-images/kubenow-current.tar.gz .

#Extracting it
echo '\nExtracting image tar...'
tar -xvzf kubenow-current.tar.gz

#Converting image from raw to qcow format
echo '\nConverting RAW image into QCOW2 format...'
qemu-img convert -f raw -O qcow2 disk.raw kubenow-current.qcow2

#Uploading the new image format back to the Google Storage bucket
echo '\nUploading new image format back into the Google buket...'
gsutil cp -a public-read kubenow-current.qcow2 gs://kubenow-images/
