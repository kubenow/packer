#This script's purpose is to copying the latest Kubenow-current AMI across all the regions.
#Although there exists a flag within the packer builder, the pitfall of such process is to end up with multiple copies of kubenow-current.
#In fact while aws does not allow to CREATE ami with the same name (-force flag with packer is necessary to deregister first old one),
#it is possible to copy an AMI with the same name from one region to another becasuse differentiation is based on the key "AMI ID"
#Author: carmat88

#!/bin/bash
#Current list of regions we work with
aws_regions=("ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "us-east-1" "us-east-2" "us-west-1" "us-west-2")

#Given the source region, we are fetching the latest kubenow-current AMI id
aws ec2 describe-images --filters Name=name,Values=kubenow-current > current_image.json
export LATEST_AMI_ID
LATEST_AMI_ID=$(jq '.Images[0] | .ImageId' current_image.json | sed -e 's/^"//' -e 's/"$//')
printf "Latest kubenow-current AMI id: %s\n" "$LATEST_AMI_ID"

#We are saving the source region in a variable for easy of use and portability instead of hard-coding it
source_region=$(aws configure get default.region)

#Now we start the process of copying the latest Kubenow AMI across all the other regions
for reg in ${aws_regions[*]}; do
            #Optmizing performance by avoiding to copy AMI within the source region itself.
            if [ "$reg" != "$source_region" ]
                then 
                    printf "\nRegion: %s\n" "$reg"
                    #We update the default region so to correctly perform checks in each region via awscli
                    aws configure set default.region "$reg"
                    printf "New default region is: %s\n" "$reg"
                    #Before copying we check if there are old "latest" Kubenow AMI. Best scenario: 0, we skip. Worst scenario: N, we deregister them first.
                    aws ec2 describe-images --filters Name=name,Values=kubenow-current > out_images.json
                    #Next lines should be easy to understand
                    counter=$(cat out_images.json | grep ImageId | wc -l)
                    
                    if [ $counter -gt "0" ]
                        then
                            printf "Proceeding to deregister old kubenow AMIs...\n"
                            i="0"
                            while [ $i -lt $counter ]; do
                                ami_id_to_deregister=$(jq ".Images[$i] | .ImageId" out_images.json | sed -e 's/^"//' -e 's/"$//')
                                printf "Deregisterering old kubenow AMI: %s...\n" "$ami_id_to_deregister"
                                aws ec2 deregister-image --image-id "$ami_id_to_deregister"
                                i=$[$i+1]
                            done
                    fi      
                    # Finally copying the latest kubenow-current AMI onto a different region
                    printf "Copying %s in %s\n" "$LATEST_AMI_ID" "$reg"
                    printf "Copied AMI id:\n"
                    aws ec2 copy-image --source-image-id "$LATEST_AMI_ID" --source-region "$source_region" --region "$reg" --name "kubenow-current"               
            fi
done
# Re-setting deafult region with the source one
aws configure set default.region "$source_region"
printf "\nResetting default region to original source: %s\n" "$source_region"

#Cleaning up output files
rm current_image.json out_images.json