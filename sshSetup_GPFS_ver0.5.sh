#!/bin/sh

### Inspired by Oracle RAC Script ##

# Command line arguments
numargs=$#
HOSTNAME=$(hostname)
HELP=false
i=1
USR=$USER

# Test if $TEMP env variable already exists
if test -z "$TEMP"
then
	TEMP=/tmp
fi

IDENTITY=id_rsa
#Date Usage - 'date + Format' 
LOGFILE=$TEMP/gpfsSshSetup_$(date +%F-%H-%M-%S).log


while [ $i - le $numargs ]
do
	j=$1
	if [ $j = "-hosts" ]
	then
		HOSTS=$2
		shift 1
		i=($expr $i + 1)
	fi
	if [ $j = "-user" ]
	then
		USR=$2
		shift 1
		i=($expr $i + 1)
	fi
	
	if [ $j = "-help" ]
	then
		HELP=true
	fi
	
	
#	else
#	echo Wrong Syntax, use -help argument to read the usage.
#	exit 1	
#	if [ $j = "--help" ]
#	then
#		echo 
#	fi
done

if [ $HELP = "true" ]
then
	echo "Usage $0 -user <user name> [ -hosts \"<space separated hostlist>\" | [-help]"
fi


if test -z $1
then
echo "-user <user name> [ -hosts \"<space separated hostlist>\" |  [-help] [-usePassphrase] [-noPromptPassphrase]"
exit 1
fi


# Paths for ssh, scp, ssh-keygen excutables
SSH="/usr/bin/ssh"
SCP="/usr/bin/scp"
SSH_KEYGEN="/usr/bin/ssh-keygen"
determineOS()
{
	platform=$(uname -s)
	case "$platform"
	in
		"SunOS") os=solaris;;
		"Linux") os=linux;;
		"HP-UX") os=hpunix;;
		  "AIX") os=aix;;
		      *) echo "Sorry, $platform is not supported."
			  
				 exit 1;;
	esac
	
	echo "Platform:- $platform"
		
	
}
determinOS
ENCR_TYPE="rsa"

hostok=""
hostnotok=""
if [ $platform = "Linux" ]
then
	PING="/bin/ping"
else
	PING="/sbin/ping"
fi

PATH_ERROR=0
if test ! -x $SSH ; then
	echo "ssh not found at $SSH."
	PATH_ERROR=1
fi
if [ ! -x $SCP ]; then
	echo "ssh not found at $SSH."
	PATH_ERROR=1
fi
if test ! -x $SSH_KEYGEN ; then
	echo "ssh not found at $SSH."
	PATH_ERROR=1
fi
if test ! -x $PING ; then
	echo "ssh not found at $SSH."
	PATH_ERROR=1
fi
if [ $PATH_ERROR = 1 ]; then
	echo "ERROR: one or more of the required executable files not found, aborting..."
	exit 1
fi

echo Checking the remote hosts...
for host in $HOSTS
do
 if [ $platform = "SunOS" ]; then
       $PING -s $host 5 5
   elif [ $platform = "HP-UX" ]; then
       $PING $host -n 5 -m 5
   else
       $PING -c 5 -w 5 $host
   fi
  exitcode=`echo $?`
  if [ $exitcode = 0 ]
  then
     hostok="$hostok $host"
  else
     hostnotok="$hostnotok $host"
  fi
done

if [ -z "$hostnotok" ]
then
	echo Ping to hosts succeeded: $hostok
else
	echo One or more hosts did not respond.
	echo Succeeded: $hostok
	echo failed: $hostnotok
	exit 1
fi



ssh-keygen -t rsa -f $HOME/.ssh/$(hostname) -N ''
for host in $HOSTS
do
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" ssh-keygen -t rsa -f .ssh/$host -N '';	mkdir -p .ssh ; chmod og-w . .ssh;   touch .ssh/authorized_keys .ssh/known_hosts;  chmod 644 .ssh/authorized_keys  .ssh/known_hosts; cp  .ssh/authorized_keys .ssh/authorized_keys.tmp ;  cp .ssh/known_hosts .ssh/known_hosts.tmp; echo \\"Host *\\" > .ssh/config.tmp; echo \\"ForwardX11 no\\" >> .ssh/config.tmp; if test -f  .ssh/config ; then cp -f .ssh/config .ssh/config.backup; fi ; mv -f .ssh/config.tmp .ssh/config\""
done

#create ssh-keygen on all hosts
for host in $HOSTS
do
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" ssh-keygen -t rsa -f .ssh/$host -N \""
	
	
# Sending key files among hosts
for targethost in $HOSTS
do
	for remotehost in $HOSTS
	do
		scp $USR@$targethost:.ssh/${IDENTITY}.pub $USR@$remotehost:.ssh/${IDENTITY}.pub.$targethost
	done
	

# Update 'authorized_keys' entries on all hosts
for host in $HOSTS
do
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" cat .ssh/${IDENTITY}.pub* >> .ssh/authorized_keys\""
done

# Restore backup .ssh configuration
for host in $HOSTS
do
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" cat .ssh/known_hosts.tmp >> .ssh/known_hosts; cat .ssh/authorized_keys.tmp >> .ssh/authorized_keys\""
done

echo SSH Setup has successfully finished.