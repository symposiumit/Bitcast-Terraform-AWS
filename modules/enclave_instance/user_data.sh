#!/bin/bash
set -euxo pipefail

NEC_CONFIG=/etc/nitro_enclaves

mkdir -p "$NEC_CONFIG"
cat <<CONFIG > "$NEC_CONFIG"/config.yaml
allocator:
  eid: "{{.enclave_cpu_count}}"
  cpu_count: {{.enclave_cpu_count}}
  memory_mib: {{.enclave_memory_mib}}
vsock_proxy:
  port: 5000
  backend:
    type: tcp
    address: 127.0.0.1
    port: 8000
CONFIG

systemctl enable --now nitro-enclaves-allocator.service
systemctl enable --now nitro-enclaves-vsock-proxy.service
