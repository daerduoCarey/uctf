#!/bin/bash

set -o errexit

WS=`pwd`/ws
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_SPACE=/opt/sasc
REPOS=${SCRIPTDIR}/gazebo_uctf.rosinstall
OTHER_REPOS=${SCRIPTDIR}/other.rosinstall

# TODO(tfoote) add proper certs for NPS servers
export GIT_SSL_NO_VERIFY=true

if test -d ${INSTALL_SPACE}; then
  echo "Error: Install directory ${INSTALL_SPACE} exists. Please delete it and try again."
  exit 1
fi

mkdir -p ${WS}/src

echo "Cloning from ${REPOS} into ${WS}/src..."
if [ -e ${WS}/src/.rosinstall ]; then
  wstool merge -t ${WS}/src ${REPOS} --merge-replace
else
  wstool init ${WS}/src ${REPOS}
fi
(cd ${WS}/src/uctf && git submodule update --init --recursive)

echo "Downloading pacakge.xml files for Gazebo packages..."
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_gazebo.xml > ${WS}/src/gazebo/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-math.xml > ${WS}/src/ign-math/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-msgs.xml > ${WS}/src/ign-msgs/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_ign-tools.xml > ${WS}/src/ign-tools/package.xml
curl https://bitbucket.org/scpeters/unix-stuff/raw/master/package_xml/package_sdformat.xml > ${WS}/src/sdformat/package.xml

mkdir -p ${WS}/other_src
echo "Cloning from ${OTHER_REPOS} into ${WS}/other_src..."
if [ -e ${WS}/other_src/.rosinstall ]; then
  wstool merge --merge-replace -t ${WS}/other_src ${OTHER_REPOS}
else
  wstool init ${WS}/other_src ${OTHER_REPOS}
fi

echo "Installing dependencies with rosdep..."
. /opt/ros/kinetic/setup.bash
rosdep install --from-path ${WS}/src --ignore-src -y|| true
echo "Installing other dependencies..."
sudo apt-get install -y libxslt1-dev libqwt-dev python-future libignition-transport-dev

echo "Building Gazebo and friends..."
cd ${WS}
catkin config --init --extend /opt/ros/kinetic -i ${INSTALL_SPACE} --install --isolate-devel
sudo mkdir -p ${INSTALL_SPACE}
sudo chown -R ${USER}:${USER} ${INSTALL_SPACE}
catkin build
cp -r ${WS}/src/gazebo_models ${INSTALL_SPACE}/share

# echo "Cloning Ardupilot..."
# git clone https://github.com/tfoote/ardupilot.git -b uctf-dev
echo "Building Ardupilot..."
cd ${WS}/other_src/ardupilot
# export PATH=${PATH}:${WS}/ardupilot/Tools/autotest
# ./Tools/scripts/install-prereqs-ubuntu.sh Now in bootstrap image
git submodule update --init --recursive
./waf configure --prefix=${INSTALL_SPACE}
./waf
./waf install

echo "Installing mavproxy"
pip install mavproxy --system --target=${INSTALL_SPACE}/lib/python/site-packages/ --install-option="--install-scripts=${INSTALL_SPACE}/bin"

echo "installing qgroundcontrol"

wget https://s3-us-west-2.amazonaws.com/qgroundcontrol/latest/QGroundControl.AppImage -O /opt/sasc/bin/qgroundcontrol
chmod +x /opt/sasc/bin/qgroundcontrol

echo "Installing arbiter and dependencies"

VENV3=${INSTALL_SPACE}/venv3
mkdir -p ${VENV3}
pyvenv ${VENV3}
(. ${VENV3}/bin/activate && pip install wheel)
(. ${VENV3}/bin/activate && pip install image netifaces pyqt5 urllib3)

# TODO(tfoote) switch to upstream when merge complete https://gitlab.nps.edu/sasc/acs_lib/merge_requests/1
# git clone git@gitlab.nps.edu:tfoote_osrfoundation.org/acs_lib.git
(. ${VENV3}/bin/activate && cd ${WS}/other_src/acs_lib && python setup.py install)
# git clone git@gitlab.nps.edu:sasc/acs_dashboards.git
(. ${VENV3}/bin/activate && cd ${WS}/other_src/acs_dashboards && python setup.py install)
# git clone git@gitlab.nps.edu:sasc/arbiter.git
(. ${VENV3}/bin/activate && cd ${WS}/other_src/arbiter && python setup.py install)


echo "generating control file"

cp ${SCRIPTDIR}/sasc-control.base ${WS}/sasc-control
echo -n "Files:" >> ${WS}/sasc-control
find -L /opt/sasc -type f | xargs -I {} echo " {} /" >> ${WS}/sasc-control
sed -i '/^.*script (dev).tmpl.*/d' ${WS}/sasc-control
cd ${WS}
equivs-build ${WS}/sasc-control