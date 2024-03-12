#!/bin/bash
export HOME="/home/ubuntu"
sudo su - deploy
sudo chown -R ubuntu:ubuntu /usr/local/rvm/
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y \
    curl g++ gcc autoconf automake bison libc6-dev libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev \
    libtool libyaml-dev make pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev \
    git build-essential libreadline6-dev libdb-dev gh
gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ../../etc/profile.d/rvm.sh
rvm install ruby-3.3.0
rvm use ruby-3.3.0 --default
gem install rails
mkdir ror-project
sudo git clone https://rajrtd:<fine grain token>@github.com/rajrtd/ror-project.git /home/ubuntu/ror-project/ # use fine grain token
sudo chown -R ubuntu:ubuntu /home/ubuntu/ror-project/
cd /home/ubuntu/ror-project
bundle install
rails server -b 0.0.0.0 -p 3000