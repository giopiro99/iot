#!/bin/bash

echo "configurazione ssh iniziata"

SSH_PATH="/home/vagrant/.ssh"
KEYS_PATH="/vagrant/ssh-keys"

cp $KEYS_PATH/id_rsa.pub $SSH_PATH/id_rsa.pub
cp $KEYS_PATH/id_rsa $SSH_PATH/id_rsa

cat $KEYS_PATH/id_rsa.pub >> $SSH_PATH/authorized_keys

chown -R vagrant:vagrant $SSH_PATH

chmod 755 ~
chmod 700 $SSH_PATH
chmod 644 $SSH_PATH/id_rsa.pub
chmod 600 $SSH_PATH/authorized_keys $SSH_PATH/id_rsa
echo "configurazione ssh finita"
