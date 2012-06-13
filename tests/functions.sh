#!/usr/bin/env bash

# Tests for DevStack functions

TOP=$(cd $(dirname "$0")/.. && pwd)

# Import common functions
source $TOP/functions

# Import configuration
source $TOP/openrc


echo "Testing die_if_not_set()"

bash -cx "source $TOP/functions; X=`echo Y && true`; die_if_not_set X 'not OK'"
if [[ $? != 0 ]]; then
    echo "die_if_not_set [X='Y' true] Failed"
else
    echo 'OK'
fi

bash -cx "source $TOP/functions; X=`true`; die_if_not_set X 'OK'"
if [[ $? = 0 ]]; then
    echo "die_if_not_set [X='' true] Failed"
fi

bash -cx "source $TOP/functions; X=`echo Y && false`; die_if_not_set X 'not OK'"
if [[ $? != 0 ]]; then
    echo "die_if_not_set [X='Y' false] Failed"
else
    echo 'OK'
fi

bash -cx "source $TOP/functions; X=`false`; die_if_not_set X 'OK'"
if [[ $? = 0 ]]; then
    echo "die_if_not_set [X='' false] Failed"
fi


echo "Testing INI functions"

cat >test.ini <<EOF
[default]
# comment an option
#log_file=./log.conf
log_file=/etc/log.conf
handlers=do not disturb

[aaa]
# the commented option should not change
#handlers=cc,dd
handlers = aa, bb

[bbb]
handlers=ee,ff
EOF

# Test with spaces

VAL=$(iniget test.ini aaa handlers)
if [[ "$VAL" == "aa, bb" ]]; then
    echo "OK: $VAL"
else
    echo "iniget failed: $VAL"
fi

iniset test.ini aaa handlers "11, 22"

VAL=$(iniget test.ini aaa handlers)
if [[ "$VAL" == "11, 22" ]]; then
    echo "OK: $VAL"
else
    echo "iniget failed: $VAL"
fi


# Test without spaces, end of file

VAL=$(iniget test.ini bbb handlers)
if [[ "$VAL" == "ee,ff" ]]; then
    echo "OK: $VAL"
else
    echo "iniget failed: $VAL"
fi

iniset test.ini bbb handlers "33,44"

VAL=$(iniget test.ini bbb handlers)
if [[ "$VAL" == "33,44" ]]; then
    echo "OK: $VAL"
else
    echo "iniget failed: $VAL"
fi


# Test section not exist

VAL=$(iniget test.ini zzz handlers)
if [[ -z "$VAL" ]]; then
    echo "OK: zzz not present"
else
    echo "iniget failed: $VAL"
fi

iniset test.ini zzz handlers "999"

VAL=$(iniget test.ini zzz handlers)
if [[ -n "$VAL" ]]; then
    echo "OK: zzz not present"
else
    echo "iniget failed: $VAL"
fi


# Test option not exist

VAL=$(iniget test.ini aaa debug)
if [[ -z "$VAL" ]]; then
    echo "OK aaa.debug not present"
else
    echo "iniget failed: $VAL"
fi

iniset test.ini aaa debug "999"

VAL=$(iniget test.ini aaa debug)
if [[ -n "$VAL" ]]; then
    echo "OK aaa.debug present"
else
    echo "iniget failed: $VAL"
fi

# Test comments

inicomment test.ini aaa handlers

VAL=$(iniget test.ini aaa handlers)
if [[ -z "$VAL" ]]; then
    echo "OK"
else
    echo "inicomment failed: $VAL"
fi

rm test.ini


echo "Testing is_package_installed()"

if [[ -z "$os_PACKAGE" ]]; then
    GetOSVersion
fi

if [[ "$os_PACKAGE" = "deb" ]]; then
    is_package_installed dpkg
    VAL=$?
else
    is_package_installed rpm
    VAL=$?
fi
if [[ "$VAL" -eq 0 ]]; then
    echo "OK"
else
    echo "is_package_installed() on existing package failed"
fi

is_package_installed zzzZZZzzz
VAL=$?
if [[ "$VAL" -ne 0 ]]; then
    echo "OK"
else
    echo "is_package_installed() on non-existing package failed"
fi


echo "Testing map_package()"

# We force testing with "SUSE LINUX"
os_VENDOR="SUSE LINUX"

# Test a package with a map
grep -q "^httpd apache2$" "$TOP/files/package-maps/$os_VENDOR" || echo "Invalid test for map_package() on a package with a map"
VAL=$(map_package httpd)
if [[ "$VAL" = "apache2" ]]; then
    echo "OK"
else
    echo "map_package() on a package with a map failed: $VAL != apache2"
fi

# Test a package with no map (same name)
grep -q "^#gcc$" "$TOP/files/package-maps/$os_VENDOR" || echo "Invalid test for map_package() on a package with a map"
VAL=$(map_package gcc)
if [[ "$VAL" = "gcc" ]]; then
    echo "OK"
else
    echo "map_package() on a package with no map failed: $VAL != gcc"
fi

# Test two packages
VAL=$(map_package httpd gcc | xargs echo)
if [[ "$VAL" = "apache2 gcc" ]]; then
    echo "OK"
else
    echo "map_package() on two package failed: \"$VAL\" != \"apache2 gcc\""
fi

# Test non-existing package (~ no map)
grep -q "non-existing" "$TOP/files/package-maps/$os_VENDOR" && echo "Invalid test for map_package() on a package with a map"
VAL=$(map_package non-existing)
if [[ "$VAL" = "non-existing" ]]; then
    echo "OK"
else
    echo "map_package() on a non-existing package failed: $VAL != non-existing"
fi
