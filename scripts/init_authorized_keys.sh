#!/bin/bash

USERNAME=testuser

if [ "$AUTHORIZED_KEY" == "" ]
then
    echo "No key provided to inject..."
    echo "You will not be able to ssh into user $USERNAME until when you don't"
    echo "setup the authorized_keys (via docker exec)"

else
    file_size=`wc -c /home/testuser/.ssh/authorized_keys | cut -f 1 -d\ `
    if [ "$file_size" -lt 3 ]
    then
	echo "$AUTHORIZED_KEY" >> /home/$USERNAME/.ssh/authorized_keys
        echo "You should now be able to ssh into user $USERNAME with the provided key"
    else
        echo "authorized_keys file not empty: I do NOT inject the key"
   fi
fi
