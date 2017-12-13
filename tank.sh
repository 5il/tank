#!/bin/bash

if [[ $(uname -r) != *"kali"* ]]; then
 echo "This is meant to be run on Kali..."
 exit 1
fi

apt -y install masscan eyewitness nfs-common smbclient

if [ -f exclude.ips ]; then
  sed -i "s/ *//g" exclude.ips
  sed -i "s/,/\n/g" exclude.ips
  exclude_range="--excludefile exclude.ips"
else
  exclude_range=""
fi

mkdir reports

c="1"
for ip_range in $(cat *.ips | sed "s/ *//g"); do
 echo "[*] Scanning $ip_range"
 #masscan -p21,22,23,25,80,111,137,139,443,445,554,1048,2049,3260,3306,3389,8080,8443 -oG $c --rate=1000 $ip_range
 maxrtt="100ms"
 nmap -v -oG $c.tmp -p21,22,23,25,80,111,137,139,443,445,554,1048,2049,3260,3306,3389,8080,8443 --max-scan-delay 5ms --max-retries 2 --max-rtt-timeout $maxrtt $exclude_range $ip_range
 let "c++"
done

grep -h "^Host" *.tmp > full.gnmap
rm *.tmp

for port in 80 443 8080 8443; do grep "$port\/open" full.gnmap | awk -v rep="$port" '{print $2 ":" rep}' >> http.txt; done
#Need to make this conditional...
eyewitness --web -f $(pwd)/http.txt --no-prompt
rm http.txt

grep "21/open" full.gnmap | sed "s/Host: //" | sed "s/ (.*//" > ftp.ips
nmap -v -iL ftp.ips -p21 --script=ftp-anon -oN reports/anon_ftp.nmap
rm ftp.ips

for ip in $(grep "2049/open" full.gnmap | sed "s/Host: //" | sed "s/ (.*//"); do
 printf "\n\nHost: $ip" >> reports/nfs_shares.txt
 showmount -e $ip >> reports/nfs_shares.txt
done

for ip in $(grep "445/open" full.gnmap | sed "s/Host: //" | sed "s/ (.*//"); do
 printf "\n\nHost: $ip" >> reports/smb_shares.txt
 smbclient --list=$ip -N >> reports/smb_shares.txt
done

for ip in $(grep "25/open" full.gnmap | sed "s/Host: //" | sed "s/ (.*//"); do
 printf "\n\nHost: $ip" >> reports/openRelayList.txt
 python scripts/testRelay.py $ip >> reports/openRelayList.txt
done

mv full.gnmap reports/
