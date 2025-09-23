#!/bin/bash

# install dependencies for ROS 2
brew install asio assimp bison bullet cmake console_bridge cppcheck \
  cunit eigen freetype graphviz opencv openssl orocos-kdl pcre poco \
  pyqt@5 python qt@5 sip spdlog tinyxml2


# make ROS directory
mkdir -p ~/ros_kilted

# Add the openssl dir for DDS-Security
export OPENSSL_ROOT_DIR=$(brew --prefix openssl)
export CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH:$(brew --prefix qt@5)
export PATH=$PATH:$(brew --prefix qt@5)/bin

# setup python environment
cd ~/ros_kilted
uv init --python 3.11
# install pygraphviz and pydot
uv pip install pygraphviz pydot
uv pip install -U \
  --config-settings="--global-option=build_ext" \
  --config-settings="--global-option=-I$(brew --prefix graphviz)/include/" \
  --config-settings="--global-option=-L$(brew --prefix graphviz)/lib/" \
  argcomplete catkin_pkg colcon-common-extensions coverage \
  cryptography empy flake8 flake8-blind-except==0.1.1 flake8-builtins \
  flake8-class-newline flake8-comprehensions flake8-deprecated \
  flake8-import-order flake8-quotes \
 importlib-metadata jsonschema lark==1.1.1 lxml matplotlib mock mypy==0.931 netifaces \
  psutil pydot pygraphviz pyparsing==2.4.7 \
  pytest-mock rosdep rosdistro setuptools==59.6.0 vcstool

# Create a workspace and clone all repos
mkdir -p ~/ros2_kilted/src
cd ~/ros2_kilted
vcs import --input https://raw.githubusercontent.com/ros2/ros2/kilted/ros2.repos src

# build the worksoace
cd ~/ros2_kilted/
colcon build --symlink-install --packages-skip-by-dep python_qt_binding

# Source the ROS 2 setup file:
. ~/ros2_kilted/install/setup.zsh

# try some examples
ros2 run demo_nodes_cpp talker
#ros2 run demo_nodes_py listener
