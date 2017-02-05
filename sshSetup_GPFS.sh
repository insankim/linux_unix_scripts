#!/bin/sh

ssh cluster 인증 과정 (node1, 2 ... n)
0. OS 환경 파악 (Linux, AIX, HP-UX, Solaris...)
1. ping test - (node1, 2 ... n)
2. 모든 호스트 간 통신해서 known_host update
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

