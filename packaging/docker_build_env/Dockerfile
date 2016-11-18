FROM ubuntu:xenial
MAINTAINER Tully Foote<tfoote@osrfoundation.org>

RUN apt-get update && echo TODO collapse me
RUN apt-get install -y git equivs curl mercurial lsb-release

RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 0xB01FA116

RUN apt-get install -y python-rosinstall python-wstool


RUN apt-get install -y libxslt1-dev libqwt-dev python-future libignition-transport-dev

# from Ardupilot
RUN apt-get install -y gawk make git curl python-serial python-argparse openocd flex bison libncurses5-dev \
          autoconf texinfo build-essential libftdi-dev libtool zlib1g-dev \
          zip genromfs python-empy libc6-i386 g++ python-pip python-setuptools python-matplotlib python-serial python-scipy python-opencv python-numpy python-pyparsing ccache realpath
