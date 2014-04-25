#!/bin/bash

# This wrapper script requires libmodbus and check_modbus ready
#
# Prepare your system:
#
# Download: https://github.com/AndreySV/check_modbus
# Download: http://libmodbus.org/download/
#
# Unpack both packages in comfortable place.
#
# Install libmodbus library:
# ./configure;make;make install;
#
# Install check_modbus:
# ./configure LDFLAGS=-L/usr/local/lib CPPFLAGS=-I/usr/local/include;
# make;make install;
#
# Thats it! your check_modbus should be now working.
# However, if it cannot find libmodbus, this might help:
#
# Create file /etc/ld.so.conf.d/libc.conf (must be root)
# Edit file /etc/ld.so.conf.d/libc.conf (must be root)
# Add "/usr/local/lib"
# Save File.
#
# Verify if library can now be seen by system.
# Run: ldconfig -v | grep libmodbus
#
# That should do it.
#

MODBUS=/usr/local/bin/check_modbus
EXPECTED_ARGS=14

REVISION='1.0.2 by leshcat'

E_OK=0
E_WARN=1
E_CRIT=2
E_UNKNOWN=3

usage()
{
    echo "usage: check_modbus.sh [-H hostname/ip] [-d device] [-F format] [-a address] [-f function] [-l lower limit] [-u upper limit]"
    echo "                     "
    echo "sample usage: check_modbus_2.sh -H 192.168.140.23 -d 1 -F 7 -a 3927 -f 3 -l 210 -u 240"
    echo "                     "
        echo "remember: its just a wrapper script that is designed to handle specific task, original check_modbus can do much more."
        echo "type: *man check_modbus* to learn more."
        echo "                     "
    echo Revision: $REVISION
    exit $E_CRIT
}

#checking if MODBUS exists and executable
if [ ! -x "$MODBUS" ]; then
    echo "Error: $MODBUS must exist and must be executable!"
    exit $E_UNKNOWN
fi

while getopts H:d:F:a:f:l:u: OPTNAME; do
    case "$OPTNAME" in
    H)
        HOSTNAME="$OPTARG" ;;
    d)
        device="$OPTARG" ;;
    F)
        FORMAT="$OPTARG" ;;
    a)
        address="$OPTARG" ;;
    f)
        function="$OPTARG" ;;
    l)
        lowcrit="$OPTARG" ;;
    u)
        upcrit="$OPTARG" ;;
    *)
        usage ;;
    esac
done

#echo count $#
if [ $# -ne $EXPECTED_ARGS ]
then
  usage;
fi

# critical borders check

if [ "$device" != "" -a "`echo $device | grep '^[0-9][0-9]*$'`" = "" ]; then
    echo "Error: Device must be a positive integer!"
    exit $E_UNKNOWN
fi

if [ "$function" != "" -a "`echo $function | grep '^[1-8]*$'`" = "" ]; then
    echo "Error: Function can be between [1-8] range!"
        echo "Type *man check_modbus* to learn the difference."
    exit $E_UNKNOWN
fi

if [ "$address" != "" -a "`echo $address | grep '^[0-9][0-9]*$'`" = "" ]; then
    echo "Error: Address must be a positive integer!"
    exit $E_UNKNOWN
fi

if [ "$function" != "" -a "`echo $function | grep '^[3-4]*$'`" = "" ]; then
    echo "Error: function can be between [3-4] range!"
    exit $E_UNKNOWN
fi

if [ "$lowcrit" != "" -a "`echo $lowcrit | grep '^[0-9][0-9]*$'`" = "" ]; then
    echo "Error: lower limit must be a positive integer!"
    exit $E_UNKNOWN
fi

if [ "$upcrit" != "" -a "`echo $upcrit | grep '^[0-9][0-9]*$'`" = "" ]; then
    echo "Error: upper limit must be a positive integer!"
    exit $E_UNKNOWN
fi

if [ "$lowcrit" -ge "$upcrit" ]; then
    echo "Error: warning_value must be less than critical_value!"
    exit $E_UNKNOWN
fi

#GET DATA
RESULT=`$MODBUS --ip=$HOSTNAME -d $device -F $FORMAT -a $address -f $function 2>&1`;

VALUE=`echo $RESULT | egrep -i "failed|timed|out"`

if [ "$VALUE" != "" ]; then
    echo Error: $VALUE
    exit $E_UNKNOWN
fi

#parse it
ROUNDED=`echo $RESULT | awk {'print$2'} | sed 's/\..*//'`

#PREDEFINED DATA
CODE=0
MSG="$ROUNDED Volts"

if (( $ROUNDED <= $lowcrit || $ROUNDED >= $upcrit )); then
        CODE=$E_CRIT;
fi

case $CODE in
0)
    STATUS=OK
    ;;
1)
    STATUS=WARNING
    ;;
2)
    STATUS=CRITICAL
    ;;
esac

echo "$STATUS - $MSG | $address=$ROUNDED;$lowcrit;$upcrit"

exit $CODE