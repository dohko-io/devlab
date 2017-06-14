#!/bin/bash
#
#     Copyright (C) 2013-2017  the original author or authors.
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License,
#     any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>
#

set -e

source /etc/maven
source /etc/dohko
source /etc/h2

MAVEN_HOME="/opt/maven/bin/mvn"
export PATH=$PATH:$MAVEN_HOME/bin

cd /home/vagrant
git clone https://github.com/alessandroleite/dohko.git 
cd /home/vagrant/dohko

mvn install
cd services
mvn clean package -Djar.finalName=dohko -Dorg.excalibur.service.standalone=true

mkdir -p /opt/dohko/server
cp -R target/lib /opt/dohko/server
cp target/dohko.jar /opt/dohko/server

cd ../client
mvn clean package -Djar.finalName=dohko-client -Dorg.excalibur.client.console=true

mkdir -p /opt/dohko/client
cp -R target/lib /opt/dohko/client
cp target/dohko-client.jar /opt/dohko/client
