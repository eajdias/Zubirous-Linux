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

# Verificar GameMode
log "Verificando se o GameMode está instalado..."
if ! dpkg -l | grep -qw gamemode; then
    echo -e "\e[1;31m[ERRO]\e[0m GameMode não encontrado. Instale o pacote gamemode antes de continuar."
    exit 1
fi

# Habilitar GameMode
log "Habilitando GameMode..."
if systemctl --user is-active --quiet gamemoded; then
    log "GameMode já está habilitado."
else
    systemctl --user enable --now gamemoded
    log "GameMode habilitado com sucesso."
fi

# Verificar Flatpak
log "Verificando se o Flatpak está instalado..."
if ! command -v flatpak &> /dev/null; then
    echo -e "\e[1;31m[ERRO]\e[0m Flatpak não encontrado. Instale o Flatpak antes de continuar."
    exit 1
fi

# Adicionar repositório Flathub (caso necessário)
log "Verificando configuração do Flathub..."
if ! flatpak remote-list | grep -qw "flathub"; then
    log "Adicionando repositório Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    log "Flathub já está configurado."
fi

# Instalar aplicativos Flatpak
log "Instalando aplicativos Flatpak..."
FLATPAK_APPS=(
    org.libretro.RetroArch
    com.valvesoftware.Steam
    com.parsecgaming.parsec
    net.pcsx2.PCSX2
    info.cemu.Cemu
)

for app in "${FLATPAK_APPS[@]}"; do
    if flatpak list | grep -qw "$app"; then
        log "O aplicativo $app já está instalado. Pulando..."
    else
        log "Instalando $app..."
        flatpak install flathub "$app" -y || echo -e "\e[1;31m[ERRO]\e[0m Falha ao instalar $app."
    fi
done

log "Todos os aplicativos foram instalados ou já estavam presentes."
