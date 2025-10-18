@echo off
chcp 65001
echo 运行Lua测试...

REM 切换到脚本所在目录
cd /d %~dp0

REM 设置Lua路径
SET LUA_PATH=..\Content\Script\?.lua;.\?.lua;.\?\init.lua;.\DataLayer\?.lua

REM 运行所有测试
lua DataLayer\DataLayerTest.lua

pause