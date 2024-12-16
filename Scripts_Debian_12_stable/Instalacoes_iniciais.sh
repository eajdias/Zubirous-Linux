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

# Função para instalar pacotes
install_packages() {
    local packages=("$@")
    for package in "${packages[@]}"; do
        if dpkg -l | grep -qw "$package"; then
            log "Pacote $package já está instalado. Pulando..."
        else
            log "Instalando $package..."
            sudo apt-get install -y --no-install-recommends "$package"
        fi
    done
}

# Verificar se o Flatpak está configurado
log "Verificando configuração do Flatpak..."
if ! flatpak remote-list | grep -q "flathub"; then
    log "Adicionando repositório Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    log "Flatpak já configurado."
fi

# Lista de pacotes essenciais
log "Instalando pacotes necessários..."

# Pacotes de desenvolvimento
install_packages \
    build-essential zip git curl wget nasm yasm clang cmake ninja-build \
    libgtk-3-dev libxcb-randr0-dev libxdo-dev libxfixes-dev libxcb-shape0-dev \
    libxcb-xfixes0-dev libasound2-dev libpulse-dev libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev libpam0g-dev gparted

# Pacotes de sistema e desempenho
install_packages \
    gamemode libgl1-mesa-glx libgl1-mesa-dri libc6-i386 lib32gcc-s1 preload zram-tools dnsutils

# Pacotes multimídia e utilitários
install_packages \
    vlc thunderbird bleachbit meld flameshot flatpak ttf-mscorefonts-installer \
    fonts-firacode fonts-noto

log "Todos os pacotes foram instalados com sucesso!"
