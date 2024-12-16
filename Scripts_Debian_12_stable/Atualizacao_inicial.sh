#!/bin/bash

set -e  # Para interromper o script em caso de erro

# Função para exibir mensagens informativas
log() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

# Verificar se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[1;31m[ERRO]\e[0m Este script precisa ser executado como root ou com sudo."
    exit 1
fi

# Verificar a versão do Debian
VERSION=$(lsb_release -sc)
log "Versão do Debian detectada: $VERSION"
if [ "$VERSION" != "bookworm" ]; then
    log "Este script foi testado apenas no Debian 12 (Bookworm). Continuando por sua conta e risco."
fi

# Ativar paralelismo para o APT
log "Ativando paralelismo no APT..."
echo 'APT::Acquire::Queue-Mode "host";' | sudo tee /etc/apt/apt.conf.d/99parallel > /dev/null

# Atualizar e otimizar pacotes
log "Atualizando e otimizando pacotes do sistema..."
sudo apt-get update || { echo "Erro ao atualizar os pacotes. Abortando."; exit 1; }
sudo apt-get upgrade -y
sudo apt-get autoremove -y
sudo apt-get autoclean -y

# Adicionar Flathub
log "Configurando repositório Flathub..."
if ! flatpak remote-list | grep -q "flathub"; then
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    log "Flathub já está configurado."
fi

# Adicionar repositório Backports
log "Configurando repositório Backports..."
if ! grep -q "^deb .*$(lsb_release -sc)-backports" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main contrib non-free" | sudo tee /etc/apt/sources.list.d/backports.list
    sudo apt-get update
else
    log "Repositório Backports já está configurado."
fi

# Adicionar repositório XanMod
log "Configurando repositório XanMod..."
if ! grep -q "xanmod" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
    sudo apt-get update
else
    log "Repositório XanMod já está configurado."
fi

# Configurar systemd-resolved
log "Configurando DNS com systemd-resolved..."
if ! systemctl is-active --quiet systemd-resolved; then
    sudo systemctl enable --now systemd-resolved
fi
echo -e "[Resolve]\nDNS=8.8.8.8 8.8.4.4\nFallbackDNS=1.1.1.1 1.0.0.1" | sudo tee /etc/systemd/resolved.conf > /dev/null
sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

# Configurações de sysctl
log "Aplicando configurações de sysctl..."
{
    echo "vm.swappiness=10"
    echo "net.core.rmem_default=262144"
    echo "net.core.rmem_max=4194304"
    echo "net.core.wmem_default=262144"
    echo "net.core.wmem_max=1048576"
    echo "net.ipv4.tcp_window_scaling=1"
    echo "net.core.netdev_max_backlog=10000"
} | sudo tee /etc/sysctl.conf
sudo sysctl -p

# Atualizar Kernel do sistema
log "Atualizando para o kernel XanMod..."
if ! uname -r | grep -q "xanmod"; then
    sudo apt-get install -y linux-xanmod-edge
else
    log "Kernel XanMod já está instalado."
fi

# Atualizar o GRUB
log "Atualizando o GRUB..."
sudo update-grub

# Finalização
log "Instalação concluída. Reinicie o sistema para aplicar todas as alterações."
