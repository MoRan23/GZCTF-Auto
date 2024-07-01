#!/bin/bash

start(){
    hostnamectl set-hostname k3s-master
    ip=$(curl -s https://api.ipify.org)
    echo "$ip k3s-master" >> /etc/hosts
    sudo apt-get -y update
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y --no-install-recommends -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install apt-transport-https ca-certificates curl software-properties-common dnsutils debian-keyring debian-archive-keyring
    curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
    sudo add-apt-repository -y "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get -y update
    sudo DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install docker-ce docker-compose-plugin caddy
    mkdir config-auto config-auto/agent config-auto/docker config-auto/gz config-auto/k3s config-auto/caddy
    wget -O config-auto/agent/agent-temp.sh https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/agent/agent-temp.sh
    wget -O config-auto/docker/daemon.json https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/docker/daemon.json
    wget -O config-auto/gz/appsettings.json https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/gz/appsettings.json
    wget -O config-auto/gz/docker-compose.yaml https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/gz/docker-compose.yaml
    wget -O config-auto/k3s/kubelet.config https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/k3s/kubelet.config
    wget -O config-auto/k3s/registries.yaml https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/k3s/registries.yaml
    wget -O config-auto/caddy/Caddyfile https://cdn.moran233.xyz/https://raw.githubusercontent.com/MoRan23/GZCTF-Auto/main/config-auto/caddy/Caddyfile
    sed -i "s|MASTER_IP|$ip|g" config-auto/agent/agent-temp.sh
}

change_Source(){
    echo "正在自动换源..."
    if [ -f /etc/os-release ]; then
    . /etc/os-release
    VERSION_ID=$(echo "$VERSION_ID" | tr -d '"')
    major=$(echo "$VERSION_ID" | cut -d '.' -f 1)
    minor=$(echo "$VERSION_ID" | cut -d '.' -f 2)
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
        out=$(echo $password | sudo -S docker login --username=$username --password-stdin $address 2>&1)
        if echo "$out" | grep -q "Login Succeeded"; then
            echo "登录成功!"
            sed -i "s|DOCKER_USERNAME|$username|g" ./config-auto/gz/appsettings.json
            sed -i "s|DOCKER_PASSWORD|$password|g" ./config-auto/gz/appsettings.json
            sed -i "s|DOCKER_ADDRESS|$address|g" ./config-auto/gz/appsettings.json
            sed -i "s|USER_OP|$username|g" ./config-auto/agent/agent-temp.sh
            sed -i "s|PASSWORD_OP|$password|g" ./config-auto/agent/agent-temp.sh
            sed -i "s|ADDRESS_OP|$address|g" ./config-auto/agent/agent-temp.sh
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
    sed -i "s|SMTP_SERVER|$smtp_server|g" ./config-auto/gz/appsettings.json
    sed -i "s|SMTP_PORT|$smtp_port|g" ./config-auto/gz/appsettings.json
    sed -i "s|SMTP_USERNAME|$smtp_username|g" ./config-auto/gz/appsettings.json
    sed -i "s|SMTP_PASSWORD|$smtp_password|g" ./config-auto/gz/appsettings.json
    sed -i "s|SMTP_SENDER|$smtp_sender|g" ./config-auto/gz/appsettings.json
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
            sed -i "s|SETUPTYPE|Docker|g" ./config-auto/gz/appsettings.json
            sed -i "s|#K3S||g" ./config-auto/gz/appsettings.json
            sed -i "s|# - \"/var/run/docker.sock:/var/run/docker.sock\"|- \"/var/run/docker.sock:/var/run/docker.sock\"|g" ./config-auto/gz/docker-compose.yaml
            break
            ;;
        2)
            echo "选择docker+k3s部署..."
            sed -i "s|SETUPTYPE|Kubernetes|g" ./config-auto/gz/appsettings.json
            sed -i "s|#K3S|,\"KubernetesConfig\": {\"Namespace\": \"gzctf-challenges\",\"ConfigPath\": \"kube-config.yaml\",\"AllowCIDR\": [\"10.0.0.0/8\"],\"DNS\": [\"8.8.8.8\",\"223.5.5.5\"]}|g" ./config-auto/gz/appsettings.json
            sed -i "s|# - \"./kube-config.yaml:/app/kube-config.yaml:ro\"|- \"./kube-config.yaml:/app/kube-config.yaml:ro\"|g" ./config-auto/gz/docker-compose.yaml
            while true; do
                read -p "请输入k3s节点机器数量（本机除外）： " hostNum
                if [ -z "$hostNum" ]; then
                    echo "输入为空，请重新输入。"
                elif ! echo "$hostNum" | grep -qE '^[0-9]+$'; then
                    echo "输入不是数字，请重新输入。"
                else
                    echo "设置 $hostNum 个节点..."
                    ip_array=()
                    for i in $(seq 1 $hostNum); do
                        while true; do
                            read -p "请输入k3s节点 $i 的ip地址（将会影响自动连接脚本）： " hostIP
                            echo "请确认k3s节点1的ip地址（必须无错误，否则会出现连接不上的情况）：$hostIP "
                            echo "1) 确认"
                            echo "2) 重新输入"
                            read -p "是否确认？: " confirm
                            case $confirm in
                                1)
                                    echo "确认节点 $i 的ip地址：$hostIP"
                                    ip_array+=($hostIP)
                                    break
                                    ;;
                                2)
                                    ;;
                                *)
                                    echo "无效的选择！"
                                    ;;
                            esac
                        done
                        sed -i "s|#AGENT_HOSTS|echo \"$hostIP k3s-agent-$i\" >> /etc/hosts\n#AGENT_HOSTS|g" config-auto/agent/agent-temp.sh
                        echo "$hostIP k3s-agent-$i" >> /etc/hosts
                    done
                    IP_ADDR=$(hostname -I | awk '{print $1}')
                    if [[ $IP_ADDR =~ ^10\. ]] || [[ $IP_ADDR =~ ^192\.168\. ]] || [[ $IP_ADDR =~ ^172\.1[6-9]\. ]] || [[ $IP_ADDR =~ ^172\.2[0-9]\. ]] || [[ $IP_ADDR =~ ^172\.3[0-1]\. ]]; then
                        echo "主机在VPC网络中..."
                        VPC=1
                    else
                        echo "主机在经典网络中..."
                        VPC=0
                    fi
                    break
                fi
            done
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
                source_add="https://hub.hk1.dkdun.com/"
            fi
            echo "使用的镜像源是: $source_add"
            sed -i "s|\[\"[^\"]*\"\]|\[\"$source_add\"\]|g" ./config-auto/docker/daemon.json
            sed -i "s|https://hub.hk1.dkdun.com/|$source_add|g" ./config-auto/agent/agent-temp.sh
            sed -i "s|https://hub.hk1.dkdun.com/|$source_add|g" ./config-auto/k3s/registries.yaml
            break
            ;;
        2)
            echo "选择阿里云镜像服务..."
            login_docker
            sed -i "s|login=0|login=1|g" ./config-auto/agent/agent-temp.sh
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
            sed -i "s|Default|PlatformProxy|g" ./config-auto/gz/appsettings.json
            sed -i "s|\"EnableTrafficCapture\": false,|\"EnableTrafficCapture\": true,|g" ./config-auto/gz/appsettings.json
            if [ "$setup" -eq 1 ]; then
                docker network create challenges -d bridge --subnet 10.2.0.0/16
            fi
            break
            ;;
        2)
            echo "选择关闭流量代理..."
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
            echo "选择关闭smtp邮件服务..."
            sed -i "s|SMTP_PORT|1|g" ./config-auto/gz/appsettings.json
            break
            ;;
        *)
            echo "无效的选择，请重新输入："
            ;;
    esac
done

echo "请选择是否解析了域名："
echo "1) 是"
echo "2) 否"
while true; do
    read -p "请输入您的选择: " select
    case $select in
        1)
            read -p "请输入解析的域名: " domain
    
            public_ip=$(curl -s https://api.ipify.org)

            domain_ip=$(dig +short "$domain")

            if [ "$public_ip" = "$domain_ip" ]; then
                echo "设置域名 $domain 成功..."
                sed -i "s|DOMAIN|$domain|g" ./config-auto/gz/appsettings.json
                sed -i "s|DOMAIN|$domain|g" ./config-auto/caddy/Caddyfile
                sed -i "s|SERVER|$public_ip|g" ./config-auto/agent/agent-temp.sh
            else
                echo "域名 $domain 解析的 IP ($domain_ip) 不是本机的公网 IP ($public_ip)"
                echo "请检查域名解析是否正确，或者手动修改配置文件"
                select=2
            fi
            break
            ;;
        2)
            echo "未解析域名..."
            break
            ;;
        *)
            echo "无效的选择，请重新输入："
            ;;
    esac
done

while true; do
    read -p "请设置管理员密码(必须包含大写字母、小写字母和数字): " adminpasswd
    if [[ $adminpasswd =~ [A-Z] && $adminpasswd =~ [a-z] && $adminpasswd =~ [0-9] ]]; then
        sed -i "s|ADMIN_PASSWD|$adminpasswd|g" ./config-auto/gz/docker-compose.yaml
        echo "密码设置成功！"
        break
    else
        echo "密码必须包含大写字母、小写字母和数字，请重新输入。"
    fi
done

echo "开始部署..."

systemctl disable --now ufw && systemctl disable --now iptables
mv ./config-auto/docker/daemon.json /etc/docker/
sudo systemctl daemon-reload && sudo systemctl restart docker

if [ "$setup" -eq 1 ]; then
    mkdir GZCTF
    mv ./config-auto/gz/appsettings.json ./GZCTF/
    mv ./config-auto/gz/docker-compose.yaml ./GZCTF/
else
    if [ "$VPC" -eq 1 ]; then
        curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_EXEC="--kube-controller-manager-arg=node-cidr-mask-size=16" INSTALL_K3S_EXEC="--docker" INSTALL_K3S_MIRROR=cn sh -s - --node-external-ip="$public_ip" --flannel-backend=wireguard-native --flannel-external-ip
        sed -i "s|sh -|sh -s - --node-external-ip=PUBLIC_IP|g" config-auto/agent/agent-temp.sh
    else
        curl -sfL https://rancher-mirror.rancher.cn/k3s/k3s-install.sh | INSTALL_K3S_EXEC="--kube-controller-manager-arg=node-cidr-mask-size=16" INSTALL_K3S_EXEC="--docker" INSTALL_K3S_MIRROR=cn sh -
    fi
    token=$(sudo cat /var/lib/rancher/k3s/server/token)
    sed -i "s|mynodetoken|$token|g" ./config-auto/agent/agent-temp.sh
    sed -i '${/^$/d}' /etc/systemd/system/k3s.service
    echo -e "        '--disable=traefik' \\\\\\n        '--kube-apiserver-arg=service-node-port-range=20000-50000' \\\\\\n        '--kubelet-arg=config=/etc/rancher/k3s/kubelet.config' \\\\\\n" >> /etc/systemd/system/k3s.service
    mv ./config-auto/k3s/kubelet.config /etc/rancher/k3s/
    mv ./config-auto/k3s/registries.yaml /etc/rancher/k3s/
    sudo systemctl daemon-reload && sudo systemctl restart k3s
    mkdir GZCTF
    sudo cat /etc/rancher/k3s/k3s.yaml > ./GZCTF/kube-config.yaml
    sed -i "s|127.0.0.1|$public_ip|g" ./GZCTF/kube-config.yaml
    mv ./config-auto/gz/appsettings.json ./GZCTF/
    mv ./config-auto/gz/docker-compose.yaml ./GZCTF/
    mkdir k3s-agent
    cp ./config-auto/agent/agent-temp.sh k3s-agent/agent-temp
    mv ./config-auto/agent/add-agent.sh k3s-agent/add-agent.sh
    for i in $(seq 1 $hostNum); do
        cp ./config-auto/agent/agent-temp.sh k3s-agent/k3s-agent-$i.sh
        sed -i "s|NAME|k3s-agent-$i|g" k3s-agent/k3s-agent-$i.sh
        sed -i "s|PUBLIC_IP|${ip_array[$i-1]}|g" k3s-agent/k3s-agent-$i.sh
    done
fi

if [ "$select" -eq 1 ]; then
    mkdir caddy
    mv ./config-auto/caddy/Caddyfile ./caddy/
    sudo kill -9 $(sudo lsof -t -i:80)
    
    cd caddy
    nohup caddy run > caddy.log 2>&1 &
    cd ../
else
    echo "未解析域名, 跳过caddy配置..."
fi

rm -rf config-auto

cd GZCTF
docker compose up -d

echo "============"
echo "||部署成功!||"
echo "============"

echo "==============================================================================================================="

if [ "$setup" -eq 2 ]; then
    echo "---------------------------------------------------------------------------------------------------------------"
    echo "请将 k3s-agent 文件夹中的脚本拷贝到相应的其他节点机器上，并执行 k3s-agent-*.sh"
    echo "如有新加机器, 请使用 k3s-agent 文件夹中的 add-agent.sh 脚本添加, 并且请手动添加 <ip> <hostname> 到本机 /etc/hosts 中"
    echo "使用方法: bash add-agent.sh <ip> <hostname>"
    echo "其中 ip 为新加机器的ip地址,  hostname 为新加机器的主机名, 都是必填项"
    echo "主机名必须符合标准：长度在1到255之间，只能包含字母、数字、连字符。且不能与已有主机名重复！！！"
    echo "例如: bash add-agent.sh 10.10.10.10 k3s-agent-example"
    echo "---------------------------------------------------------------------------------------------------------------"
fi

echo "GZCTF 相关文件已经保存在当前目录下的 GZCTF 文件夹中"
echo "Caddy 相关文件已经保存在当前目录下的 caddy 文件夹中"

if [ "$select" -eq 1 ]; then
    echo "请访问 https://$domain 进行后续配置"
    echo "或者访问 http://$public_ip:81 进行后续配置"
else
    echo "请访问 http://$public_ip:81 进行后续配置"
fi
echo "用户名: admin"
echo "密码: $adminpasswd"
echo "==============================================================================================================="
