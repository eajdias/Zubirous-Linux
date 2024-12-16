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

# Detectar e instalar drivers de GPU
log "Detectando GPUs..."
if lspci | grep -i 'nvidia'; then
    log "GPU NVIDIA detectada. Instalando driver NVIDIA..."
    if ! dpkg -l | grep -q 'nvidia-driver'; then
        sudo apt-get install -y nvidia-driver
    else
        log "Driver NVIDIA já está instalado."
    fi
elif lspci | grep -i 'amd' | grep -i 'vga'; then
    log "GPU AMD detectada. Instalando firmware AMD..."
    if ! dpkg -l | grep -q 'firmware-amd-graphics'; then
        sudo apt-get install -y firmware-amd-graphics
    else
        log "Firmware AMD já está instalado."
    fi
else
    log "Nenhuma GPU dedicada específica detectada."
fi

log "Detectando GPUs integradas..."
if lspci | grep -i 'intel' | grep -i 'vga'; then
    log "GPU Intel integrada detectada. Instalando drivers necessários..."
    if ! dpkg -l | grep -q 'xserver-xorg-video-intel'; then
        sudo apt-get install -y xserver-xorg-video-intel
    else
        log "Driver da Intel já está instalado."
    fi
fi
