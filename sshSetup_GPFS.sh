#!/bin/sh



ssh cluster 인증 과정 (node1, 2 ... n)
00. 사용법
	./sshSetup_GPFS.sh [{-user <user name>} {-hosts <node1, node2, ...,node n> | <-help> | <--h>]
0. OS 환경 파악 (Linux, AIX, HP-UX, Solaris...)
1. ping test - (node1, 2 ... n)
2. 모든 호스트 간 통신해서 known_host update ## 일단 제외
	node1) ssh $USER @ $node1, node2, node3 ; exit
	node2) ssh -x $USER @ $node1, node2, node3; exit
	node3) ssh -x $USER @ $node1, node2, node3; exit
	
# ssh-keygen -t rsa -b <bits> -f $HOME/.ssh/`hostname` -N ''
-N을 ""로 주면 을 passphrase 없이 진행 가능 non prompt
	
# ssh -x -l root bl870ci2 "/bin/sh -c \"echo hello\""
x11 forwarding사용, login name 지정, 그 다음 호스트 사용할 쉘, 커맨드

	
3. 각 서버에서 `ssh-keygen`; enter; enter
	node1) ssh-keygen
	node2) ssh -x   ## 2번에 추가해도 괜찮을 듯.
4.  node1)scp node1_rsa.pub -> node2 node3
	node2)ssh -x node2_rsa.pub -> node1 node3
	node3)ssh -x node3_rsa.pub -> node1 node2
## 각 노드에서 node1, node2 node3 모든 pub 있음

5. 각 노드에서 pub key authorized_keys에 추가
node1) cat node1,2,3_rsa.pub >> authorized_keys
node2) ssh -x node1,2,3_rsa.pub >> authorized_keys
node3) ssh -x node1,2,3_rsa.pub >> authorized_keys

6. chmod로 .ssh 디렉터리 변경하기
chmod [a,o,u,g] [+,-,=] [r,w,x] file
all, other, user, group을 의미함

# Command line arguments
numargs=$#
HOSTNAME=$(hostname)
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
	
	if [ $j = "--help" ]
	then
		echo 
	fi
done

if [ $HELP = "true" ]
then
	echo "Usage $0 -user <user name> [ -hosts \"<space separated hostlist>\" **Localhost should come to the first in hostlist ** | -hostfile <absolute path of cluster configuration file> ] [ -advanced ]  [ -verify] [ -exverify ] [ -logfile <desired absolute path of logfile> ] [-confirm] [-shared] [-help] [-usePassphrase] [-noPromptPassphrase]"
	
	echo "Insan's comment"
fi


if test -z $1
then
echo "-user <user name> [ -hosts "<space separated hostlist>" |  [-help] [-usePassphrase] [-noPromptPassphrase]"
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

#crate ssh-keygen on all hosts
# ** Distruptive process, does not continue when identity files already exist **
ssh-keygen -t rsa -f $HOME/.ssh/$(hostname) -N ''
for host in $HOSTS
do
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" mkdir -p .ssh ; chmod og-w . .ssh;   touch .ssh/authorized_keys .ssh/known_hosts;  chmod 644 .ssh/authorized_keys  .ssh/known_hosts; cp  .ssh/authorized_keys .ssh/authorized_keys.tmp ;  cp .ssh/known_hosts .ssh/known_hosts.tmp; echo \\"Host *\\" > .ssh/config.tmp; echo \\"ForwardX11 no\\" >> .ssh/config.tmp; if test -f  .ssh/config ; then cp -f .ssh/config .ssh/config.backup; fi ; mv -f .ssh/config.tmp .ssh/config\""
done

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
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" cat .ssh/${IDENTITY}.pub* >> .ssh/authorized_keys"
done

