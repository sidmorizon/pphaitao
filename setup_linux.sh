#!/bin/bash

# 相关环境包初始化，首次克隆项目的时候安装一次即可
# $ sh ~/workspace/setup_linux.sh

# 安装node
echo ----------------------- INSTALLING node
which node || sudo apt-get install nodejs
# 安装meteor
echo ----------------------- INSTALLING meteor
which meteor || curl https://install.meteor.com/ | sh
# 安装fish
echo ----------------------- INSTALLING fish
which fish || sudo apt-get install fish
# 安装node包：orion代码生成器
echo ----------------------- INSTALLING node orion-cli
npm list -g orion-cli || npm install -g orion-cli
# 安装git

