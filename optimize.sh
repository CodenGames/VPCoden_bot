#!/bin/bash
set -euo pipefail

SYSCTL_FILE="/etc/sysctl.d/90-vpn-optimize.conf"

cat > "$SYSCTL_FILE" << 'EOF'
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576
net.ipv4.tcp_rmem = 4096 1048576 16777216
net.ipv4.tcp_wmem = 4096 1048576 16777216
net.ipv4.tcp_mem = 262144 524288 786432
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 65536
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_fastopen = 3
net.netfilter.nf_conntrack_max = 524288
fs.file-max = 1048576
fs.nr_open = 1048576
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_budget = 2000
net.core.netdev_budget_usecs = 8000
net.core.dev_weight = 128
vm.swappiness = 10
EOF

sysctl -p "$SYSCTL_FILE"

cat > /etc/security/limits.d/99-vpn.conf << 'EOF'
*       soft    nofile  1048576
*       hard    nofile  1048576
root    soft    nofile  1048576
root    hard    nofile  1048576
EOF

IFACE=$(ip route show default | awk '/default/{print $5}' | head -1)
IFACE=${IFACE:-eth0}
CPUS=$(nproc)
RPS_MASK=$(printf '%x' $(( (1 << CPUS) - 1 )))
RPS_FLOW=$(( CPUS * 8192 ))

if [ -d "/sys/class/net/${IFACE}/queues/rx-0" ]; then
    echo "$RPS_MASK" > "/sys/class/net/${IFACE}/queues/rx-0/rps_cpus"
    echo "$RPS_FLOW" > /proc/sys/net/core/rps_sock_flow_entries
    echo "$RPS_FLOW" > "/sys/class/net/${IFACE}/queues/rx-0/rps_flow_cnt"
fi

IRQ=$(grep virtio0-input /proc/interrupts 2>/dev/null | cut -d: -f1 | tr -d ' ')
[ -n "$IRQ" ] && echo 4 > /proc/irq/$IRQ/smp_affinity 2>/dev/null || true

tc qdisc replace dev "$IFACE" root fq pacing maxrate 1gbit flow_limit 200 orphan_mask 1023 2>/dev/null || true

cat > /etc/systemd/system/rps-tuning.service << SVCEOF
[Unit]
Description=RPS, IRQ and qdisc tuning for VPN
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'echo ${RPS_MASK} > /sys/class/net/${IFACE}/queues/rx-0/rps_cpus; echo ${RPS_FLOW} > /proc/sys/net/core/rps_sock_flow_entries; echo ${RPS_FLOW} > /sys/class/net/${IFACE}/queues/rx-0/rps_flow_cnt; IRQ=\$(grep virtio0-input /proc/interrupts | cut -d: -f1 | tr -d " "); [ -n "\$IRQ" ] && echo 4 > /proc/irq/\$IRQ/smp_affinity || true; tc qdisc replace dev ${IFACE} root fq pacing maxrate 1gbit flow_limit 200 orphan_mask 1023 || true'

[Install]
WantedBy=multi-user.target
SVCEOF
systemctl daemon-reload
systemctl enable rps-tuning.service

cat > /etc/systemd/resolved.conf << 'EOF'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 8.8.8.8#dns.google 77.88.8.8
FallbackDNS=1.0.0.1 8.8.4.4
DNSOverTLS=opportunistic
Cache=yes
CacheFromLocalhost=yes
EOF
systemctl restart systemd-resolved

COMPOSE_FILE="/opt/remnawave/docker-compose.yml"
NEED_RECREATE=0

if [ -f "$COMPOSE_FILE" ]; then
    if ! grep -q "GOGC" "$COMPOSE_FILE"; then
        sed -i '/- NODE_PORT=/a\      - GOGC=200' "$COMPOSE_FILE"
        sed -i '/- GOGC=200/a\      - GOMEMLIMIT=3GiB' "$COMPOSE_FILE"
        NEED_RECREATE=1
    fi
fi

if docker ps --format '{{.Names}}' | grep -q '^remnanode$'; then
    if [ "$NEED_RECREATE" -eq 1 ]; then
        docker stop remnanode
        docker rm remnanode
        cd /opt/remnawave && docker-compose up -d remnanode 2>/dev/null || docker compose up -d remnanode 2>/dev/null || docker restart remnanode
    else
        docker restart remnanode
    fi
fi
