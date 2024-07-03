#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "--------------------------------------------------------------------------------------"
    echo "使用方法: bash add-agent.sh [ip] [hostname]"
    echo "其中 ip 为新加机器的ip地址,  hostname 为新加机器的主机名, 都是必填项"
    echo "主机名必须符合标准：长度在1到255之间，只能包含字母、数字、连字符。且不能与已有主机名重复！！！"
    echo "例如: bash add-agent.sh 10.10.10.10 k3s-agent-example"
    echo "--------------------------------------------------------------------------------------"
    exit 1
fi


ip_address=$1
hostname=$2

function valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

if ! valid_ip $ip_address; then
    echo "错误: $ip_address ip地址非法！"
    exit 1
fi

function valid_hostname() {
    local hn=$1
    # 主机名必须符合标准：长度在1到255之间，只能包含字母、数字、连字符
    if [[ $hn =~ ^[a-zA-Z0-9-]{1,255}$ ]]; then
        return 0
    else
        return 1
    fi
}

if ! valid_hostname $hostname; then
    echo "错误: $hostname 主机名非法！"
    echo "主机名必须符合标准：长度在1到255之间，只能包含字母、数字、连字符"
    exit 1
fi

sed -i "s|#AGENT_HOSTS|echo \"$ip_address $hostname\" >> /etc/hosts\n#AGENT_HOSTS|g" agent-temp
cp agent-temp $hostname.sh

sed -i "s|NAME|$hostname|g" $hostname.sh
sed -i "s|PUBLIC_IP|$ip_address|g" $hostname.sh

echo "连接脚本生成完成！ $hostname.sh"