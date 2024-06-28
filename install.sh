#!/bin/sh

start(){
    sudo apt-get update
    sudo apt-get upgrade -y --no-install-recommends
    sudo apt-get -y --no-install-recommends install apt-transport-https ca-certificates curl software-properties-common dig
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get -y update
    sudo apt-get -y --no-install-recommends install docker-ce
}

change_Source(){
    echo "正在自动换源..."
    if [ -f /etc/os-release ]; then
    . /etc/os-release
    VERSION_ID=$(echo "$VERSION_ID" | tr -d '"')
    IFS='.' read -r major minor <<< "$VERSION_ID"
    if [ "$major" -lt 24 ] || { [ "$major" -eq 24 ] && [ "$minor" -lt 4 ]; }; then
        sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list
        echo "换源成功！"
    else
        sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources
        echo "换源成功！"
    fi
    else
        echo "/etc/os-release 文件不存在，无法确定系统版本信息。"
        echo "换源失败，请手动换源！"
    fi
}

login_docker(){
    while true; do
        read -p "输入阿里云镜像服务用户名: " username
        read -p "输入阿里云镜像服务密码: " password
        read -p "输入阿里云镜像服务公网地址: " address
        out=$(echo $password | sudo docker login --username=$username $address 2>&1)
        if echo "$login_command_output" | grep -q "Login Succeeded"; then
            echo "登录成功!"
            sed -i "s|DOCKER_USERNAME|$username|g" ./config/gz/appsettings.json
            sed -i "s|DOCKER_PASSWORD|$password|g" ./config/gz/appsettings.json
            sed -i "s|DOCKER_ADDRESS|$address|g" ./config/gz/appsettings.json
            break
        else
            echo "登录失败，用户名或密码错误，请重新输入！"
        fi
    done
}

set_smtp(){
    read -p "请输入smtp服务器地址: " smtp_server
    read -p "请输入smtp服务器端口: " smtp_port
    read -p "请输入smtp服务器用户名: " smtp_username
    read -p "请输入smtp服务器密码: " smtp_password
    read -p "请输入发件人邮箱: " smtp_sender
    sed -i "s|SMTP_SERVER|$smtp_server|g" ./config/gz/appsettings.json
    sed -i "s|SMTP_PORT|$smtp_port|g" ./config/gz/appsettings.json
    sed -i "s|SMTP_USERNAME|$smtp_username|g" ./config/gz/appsettings.json
    sed -i "s|SMTP_PASSWORD|$smtp_password|g" ./config/gz/appsettings.json
    sed -i "s|SMTP_SENDER|$smtp_sender|g" ./config/gz/appsettings.json
}


echo "=========================================================="
echo "||                                                      ||"
echo "||  ____ _________ _____ _____       _         _        ||"
echo "|| / ___|__  / ___|_   _|  ___|     / \  _   _| |_ ___  ||"
echo "||| |  _  / / |     | | | |_ _____ / _ \| | | | __/ _ \ ||"
echo "||| |_| |/ /| |___  | | |  _|_____/ ___ \ |_| | || (_) |||"
echo "|| \____/____\____| |_| |_|      /_/   \_\__,_|\__\___/ ||"
echo "||                                                      ||"
echo "=========================================================="
echo "请选择是否自动换源（目前只支持ubuntu）："
echo "1) 是"
echo "2) 否（手动换源）"
while true; do
    read -p "请输入您的选择: " changeSource

    case $changeSource in
        1)
            echo "设置自动换源..."
            change_Source
            break
            ;;
        2)
            echo "设置手动换源..."
            break
            ;;
        *)
            echo "无效的选择，请重新输入！"
            ;;
    esac
done

echo "正在执行初始化，请稍后..."
start
echo "初始化成功！请继续配置"

echo "请选择部署方式："
echo "1) docker部署（适用于小型比赛单机部署）"
echo "2) docker+k3s部署（适用于大型比赛单机或多机部署）"
while true; do
    read -p "请输入您的选择: " setup

    case $setup in
        1)
            echo "选择docker部署..."
            sed -i "s|SETUPTYPE|Docker|g" ./config/gz/appsettings.json
            sed -i "s|#K3S||g" ./config/gz/appsettings.json
            sed -i "s|# - \"/var/run/docker.sock:/var/run/docker.sock\"|- \"/var/run/docker.sock:/var/run/docker.sock\"|g" ./config/gz/docker-compose.yaml
            break
            ;;
        2)
            echo "选择docker+k3s部署..."
            sed -i "s|SETUPTYPE|Kubernetes|g" ./config/gz/appsettings.json
            sed -i "s|#K3S|,\"KubernetesConfig\": {\"Namespace\": \"gzctf-challenges\",\"ConfigPath\": \"kube-config.yaml\",\"AllowCIDR\": [\"10.0.0.0/8\"],\"DNS\": [\"8.8.8.8\",\"223.5.5.5\"]}|g" ./config/gz/appsettings.json
            sed -i "s|# - \"./kube-config.yaml:/app/kube-config.yaml:ro\"|- \"./kube-config.yaml:/app/kube-config.yaml:ro\"|g" ./config/gz/docker-compose.yaml
            read -p "请输入k3s节点机器数量（本机除外）： " hostNum
            case $hostNum in
                *)
                    echo "设置 $hostNum 个节点..."
                    ;;
            esac
            break
            ;;
        *)
            echo "无效的选择，请重新输入："
            ;;
    esac
done

echo "请选择赛题镜像拉取站点："
echo "1) dockerhub（需设置docker镜像源）"
echo "2) 阿里云镜像服务（需登录阿里云docker账号）"
while true; do
    read -p "请输入您的选择: " source

    case $source in
        1)
            echo "选择dockerhub..."
            read -p "输入镜像源（默认内置源）: " source_add

            if [ -z "$source_add" ]; then
                source_add="https://docker.huhstsec.top"
            fi
            echo "使用的镜像源是: $source_add"
            sed -i "s|\[\"[^\"]*\"\]|\[\"$source_add\"\]|g" ./config/docker/daemon.json
            sed -i "s|https://docker.huhstsec.top|$source_add|g" ./config/agent/agent-temp.sh
            break
            ;;
        2)
            echo "选择阿里云镜像服务..."
            login_docker
            break
            ;;
        *)
            echo "无效的选择，请重新输入："
            ;;
    esac
done

echo "请选择是否开启流量代理："
echo "1) 是"
echo "2) 否"
while true; do
    read -p "请输入您的选择: " proxy

    case $proxy in
        1)
            echo "选择开启流量代理..."
            sed -i "s|Default|PlatformProxy|g" ./config/gz/appsettings.json
            sed -i "s|#PROXY|networks:\n      - default\n      - challenges|g" ./config/gz/docker-compose.yaml
            sed -i "s|#NETWORK|networks:\n  challenges:\n    external: true|g" ./config/gz/docker-compose.yaml
            docker network create challenges -d bridge --subnet 10.2.0.0/16
            break
            ;;
        2)
            echo "选择关闭流量代理.."
            break
            ;;
        *)
            echo "无效的选择，请重新输入："
            ;;
    esac
done

echo "请选择是否开启smtp邮件服务："
echo "1) 是"
echo "2) 否"
while true; do
    read -p "请输入您的选择: " smtp

    case $smtp in
        1)
            echo "选择开启smtp邮件服务..."
            set_smtp
            break
            ;;
        2)
            echo "选择关闭smtp邮件服务.."
            break
            ;;
        *)
            echo "无效的选择，请重新输入："
            ;;
    esac
done

read -p "请输入解析的域名: " domain
public_ip=$(curl -s https://api.ipify.org)

domain_ip=$(dig +short "$domain")

if [ "$public_ip" = "$domain_ip" ]; then
    echo "设置域名 $domain 成功..."
    sed -i "s|DOMAIN|$domain|g" ./config/gz/appsettings.json
    sed -i "s|PUBLIC_IP|$public_ip|g" ./config/gz/appsettings.json
    sed -i "s|SERVER|$public_ip|g" ./config/agent/agent-temp.sh
else
    echo "域名 $domain 解析的 IP ($domain_ip) 不是本机的公网 IP ($public_ip)"
fi

read -p "请设置管理员密码: " adminpasswd
sed -i "s|ADMIN_PASSWD|$adminpasswd|g" ./config/gz/docker-compose.yaml

echo "开始部署..."

systemctl disable --now ufw && systemctl disable --now iptables
mv ./docker/daemon.json /etc/docker/
sudo systemctl daemon-reload && sudo systemctl restart docker
curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_EXEC="--kube-controller-manager-arg=node-cidr-mask-size=16" INSTALL_K3S_EXEC="--docker" INSTALL_K3S_MIRROR=cn sh -
token=$(sudo cat /var/lib/rancher/k3s/server/token)
sed -i "s|mynodetoken|$token|g" ./config/agent/agent-temp.sh
