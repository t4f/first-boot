#!/bin/bash

# Constants
apt="apt-get -qq -o=Dpkg::Use-Pty=0"  # Suppress output

# Defaults
user="user"
host="debian"
port="$(( ( RANDOM % 50000 ) + 10000 ))"


echo -n "Finding IP address... "
ip=`curl --silent icanhazip.com`
echo "Done. IP=$ip"

# Prompt user, if required
if [ ! -n "$PUBKEY" ]; then
    read -e -p "Username: " -i "$user" user
    read -e -p "Hostname: " -i "$host" host
    read -e -p "SSH Port: " -i "$port" port
    read -p "Public key (run \`ssh-keygen -t ed25519 -f ~/.ssh/$host -q -N \"\" && cat ~/.ssh/$host.pub\` and paste output): " PUBKEY
fi

# Update packages
echo -n "Updating and upgrading apt packages... "
$apt update > /dev/null
$apt upgrade -y > /dev/null
echo "Done"

# Create new user
useradd -m $user
usermod -aG sudo $user
echo "Created new user '$user'"

# Setup SSH
cp sshd_config /etc/ssh/sshd_config
echo "Port $port" >> /etc/ssh/sshd_config
chmod 0644 /etc/ssh/sshd_config
SSH_DIR=/home/$user/.ssh
mkdir $SSH_DIR
chmod 0700 $SSH_DIR
echo "$PUBKEY" > $SSH_DIR/authorized_keys
chmod 0600 $SSH_DIR/authorized_keys
chown -R $user:$user $SSH_DIR
service ssh restart 
echo "Updated ssh config"

# Install Docker
echo  -n "Installing docker... "
$apt install -y \
    apt-transport-https \
    ca-certificates \
    software-properties-common > /dev/null

curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
add-apt-repository "deb https://apt.dockerproject.org/repo/ debian-$(lsb_release -cs) main"
$apt update > /dev/null
$apt install -y docker-engine > /dev/null
echo "Done"

### Update rc.local
# Remove any auto-added root ssh keys
echo '' > /etc/rc.local
echo "(sleep 15 && rm -rf /root/.ssh) &" >> /etc/rc.local
echo "exit 0" >> /etc/rc.local
echo "Updated rc.local"

# Change hostname
ORIGINAL_HOST=`cat /etc/hostname`
sed -i -e "s/$ORIGINAL_HOST/$host/g" /etc/hosts
echo $host > /etc/hostname

# Set user password (for invoking sudo)
passwd $user

# Lock root user
passwd --lock root

# Print login 
echo "To login, run \`ssh -i ~/.ssh/$host -p $port $user@$ip\`"

exit 0

