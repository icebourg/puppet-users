#!/bin/sh

PASSWORD=`openssl rand -base64 12`
CRYPTED=`/usr/bin/mkpasswd -5 $PASSWORD`
USER=$1
HOST=`/bin/uname -n`

# Going to set $USER's password to $PASSWORD.

/usr/sbin/usermod -p $CRYPTED $USER

# Need to email the user. Assuming that GECOS contains the email address.

EMAIL=`cat /etc/passwd | grep $USER | cut -f 5 -d :`

mail -s "New Account on $HOST" $EMAIL <<EOF

Hello $USER --

You have a new account on $HOST. Your password is $PASSWORD

You can change this randomly generated password by issuing the passwd command.

Have a nice day.

the puppetmaster


.
EOF;
