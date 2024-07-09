# GZCTF-Auto
  
## GZCTF
项目地址：https://github.com/GZTimeWalker/GZCTF
官方文档：https://docs.ctf.gzti.me/zh

## 项目介绍&使用方法
GZCTF 一键部署  
现已支持单 `docker` 以及 `docker+k3s` 部署  
更多功能持续更新......  
测试环境：ubuntu 22.04 全新机  
使用方式：  
```
wget -O install.sh https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/install.sh && chmod +x install.sh && ./install.sh
```
## 更新计划
|功能|状态|
|--|--|
|qq机器人|暂无排期|
|AWD(P)平台|暂无排期，预计发布在新项目|
## 赞助鸣谢
### DKDUN
<img src="https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/moran/main/QQ%E5%9B%BE%E7%89%8720240630210148.png" alt="DKDUN 图标" width="150" height="150">
官网：https://www.dkdun.cn/  

ctf专区群: 727077055  
<img src="https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/moran/main/20240630210630.png" alt="DKDUN-CTF QQ群" width="150" height="150">  
公众号：DK盾
  
dkdun 推出 ctfer 赞助计划  
为各位热爱 ctf 的师傅提供优惠服务器  
详情查看：https://mp.weixin.qq.com/s/38xWMM1Z0sO6znfg9TIklw
  
更多服务器优惠请入群查看！  
  
## 更新历史
### 2024.7.3
fix:修复一些小bug  
update:提供内网以及未解析域名时的端口修改服务  
### 2024.7.2
fix:修复纯内网使用场景部署时部署出错的问题  
### 2024.7.1
fix:修复平台代理功能开启无法访问的问题  
fix:修复k3s连接脚本在VPC网络中无法连接master节点问题  
update:更新临时新加机器时的连接脚本生成脚本  
update:弃用nginx反代，使用caddy反代  
### 2024.6.30
fix:修复可以设置弱密码导致无法登录的bug  
issue:发布首发版本  