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

# Configurar ZRAM
log "Verificando se o pacote zram-tools está instalado..."
if ! dpkg -l | grep -q zram-tools; then
    log "O pacote zram-tools não está instalado. Instale-o antes de continuar."
    exit 1
fi

log "Verificando se o serviço ZRAM está disponível..."
if ! systemctl list-unit-files | grep -q "zramswap.service"; then
    log "ZRAM não está configurado no sistema. Instale o pacote zram-tools antes de continuar."
    exit 1
fi

log "Configurando ZRAM..."
if [ ! -f /etc/default/zram-config ]; then
    log "Arquivo de configuração do ZRAM não encontrado. Criando o arquivo..."
    sudo touch /etc/default/zram-config
fi

if ! grep -q "^ALGO=lz4" /etc/default/zram-config; then
    echo "ALGO=lz4" | sudo tee /etc/default/zram-config > /dev/null
    log "Reiniciando o serviço ZRAM para aplicar as configurações..."
    sudo systemctl restart zramswap.service
    log "ZRAM configurado com sucesso!"
else
    log "ZRAM já está configurado com o algoritmo lz4."
fi

# Detectar SSD e ativar TRIM
log "Detectando discos SSD para ativar TRIM..."
SSD_FOUND=false
for disk in /sys/block/*; do
    if [ -f "$disk/queue/rotational" ] && [ "$(cat "$disk/queue/rotational")" -eq 0 ]; then
        SSD_FOUND=true
        log "SSD detectado: $(basename "$disk"). Configurando TRIM..."
        echo "0 3 * * 0 root /sbin/fstrim -av" | sudo tee /etc/cron.d/fstrim > /dev/null
        sudo systemctl enable --now fstrim.timer
    fi
done

if [ "$SSD_FOUND" = false ]; then
    log "Nenhum SSD detectado no sistema."
else
    log "TRIM configurado para discos SSD detectados."
fi

log "Configurações concluídas com sucesso!"
