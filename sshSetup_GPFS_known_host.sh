# Register known host entries in hosts.
echo Type password for each host to update known_hosts file.
for host in $HOSTS
	
	for remotehost in $HOSTS
		do
		ssh $USER @ $host
		
		done
		
		
#create ssh-keygen on all hosts
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
done

1: 2, 3
2: 1, 3
3: 1, 2

# Update 'authorized_keys' entries on all hosts

for host in $HOSTS
do
	$SSH -o StrictHostKeyChecking=no -x -l $USR $host "/bin/sh -c \" cat .ssh/${IDENTITY}.pub* >> .ssh/authorized_keys"
done
