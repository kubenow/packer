#get_current_version.sh v1
#Author: carmat88

#!/bin/bash 

#Get current_version
export current_version=v$(git describe --tags --always | tr -d .)

regex='^v[0-9]{3}([ab][0-9]{1,}|rc[0-9]{1,})?$'

#Checking whether or not current version is tagged as release
if [[ $current_version =~ $regex ]]; then
	echo "Current version tagged as release"
else
	export current_version="current"
fi

echo "Current version is: $current_version"
