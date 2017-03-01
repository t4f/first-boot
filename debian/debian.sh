#!/bin/bash

# Defaults
user="user"
host="debian"
port="$(( ( RANDOM % 50000 ) + 10000 ))"
ip=`curl icanhazip.com`

# Prompt user, if required
if [ ! -n "$PUBKEY" ]; then
    read -e -p "Username: " -i "$user" user
    read -e -p "Hostname: " -i "$host" host
    read -e -p "SSH Port: " -i "$port" port
    read -p "Public key (run \`ssh-keygen -t ed25519 -f ~/.ssh/$host -q -N \"\" && cat ~/.ssh/$host.pub\` and paste output): " PUBKEY
fi

# Update packages
apt update
apt upgrade -y

# Create new user
useradd -m $user

# Sudo
echo "### USER ADDED TO SUDOERS ###" >> /etc/sudoers 
echo "$user\t(ALL:ALL) ALL\n" >> /etc/sudoers

# Setup SSH
cp sshd_config /etc/ssh/sshd_config
echo "Port $port" >> /etc/ssh/sshd_config
SSH_DIR=/home/$user/.ssh
mkdir $SSH_DIR
chmod 0755 $SSH_DIR
echo "$PUBKEY/n" > $SSH_DIR/authorized_keys
chmod 0600 $SSH_DIR/autthorized_keys
chown -R $user:$user $SSH_DIR
service ssh restart

# Install Docker
apt install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common

curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
add-apt-repository "deb https://apt.dockerproject.org/repo/ debian-$(lsb_release -cs) main"
apt update
apt install -y docker-engine

### Update rc.local
# Remove any auto-added root ssh keys
echo '' > /etc/rc.local
echo "(sleep 15 && rm -rf /root/.ssh) &\n" >> /etc/rc.local
echo "exit 0\n" >> /etc/rc.local

# Change hostname
ORIGINAL_HOST=`cat /etc/hostname`
sed -i -e "s/$ORIGINAL_HOST/$HOST/g" /etc/hosts
echo $HOST > /etc/hostname

# Set user password (for invoking sudo)
passwd $USER

# Print login 
echo "To login, run \`ssh -i ~/.ssh/$host -p $port $user@$ip\`"

# Reboot
echo "Rebooting..."
sleep 3
reboot

exit 0

