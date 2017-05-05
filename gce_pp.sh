#This Script will be executed during the post-processor of the GCE packer builder
#It downloads the compressed image just created, extracts it and converts to a QCOW format (to be used for OpenStack providers)
#Author: carmat88

#!/bin/bash

#Setting acls to public for new created image in Google storage so that it can be imported
echo "Setting new created Google image as shared publicly..."
gsutil acl ch -u AllUsers:R gs://kubenow-images/kubenow-current.tar.gz

#Donwloading kubenow-current compressed image from Google Storage
echo "Downloading kubenow compressed image from Google bucket..."
wget -nv https://storage.googleapis.com/kubenow-images/kubenow-current.tar.gz

#Extracting it
echo "Extracting image tar..."
tar -xvzf kubenow-current.tar.gz

#Converting image from raw to qcow format
echo "Converting RAW image into QCOW2 format..."
qemu-img convert -f raw -O qcow2 disk.raw kubenow-current.qcow2

#Checking whether there are previous kubenow-current object
aws s3 ls kubenow-us-east-1 | grep kubenow-current.qcow2 > s3_object_list.txt
counter=$(cat s3_object_list.txt | wc -l)
if [ $counter -gt "0" ]
    then
        echo "Previous kubenow-current object has been found. Proceeding to delete it... "
        aws s3 rm s3://kubenow-us-east-1/kubenow-current.qcow2 --dryrun
fi      

#Uploading the new image format back to the Google Storage bucket
echo "Uploading new image format into AWS S3 bucket: kubenow-us-east-1 ..."
aws s3 cp kubenow-current.qcow2 s3://kubenow-us-east-1 --acl public-read

#Cleaning up a bit
rm kubenow-current.tar.gz disk.raw kubenow-current.qcow2 s3_object_list.txt