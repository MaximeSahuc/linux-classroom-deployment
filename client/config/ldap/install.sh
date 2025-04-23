sudo apt update
sudo apt install requirements.txt

sudo echo "session required pam_mkhomedir.so skel=/etc/skel umask=0022" >> /etc/pam.d/common-session
