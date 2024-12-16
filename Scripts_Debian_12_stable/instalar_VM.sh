#!/bin/bash

set -e  # Interrompe o script em caso de erro

# Função para exibir mensagens informativas
log() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

# Verificar se o script está sendo executado como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\e[1;31m[ERRO]\e[0m Este script precisa ser executado como root ou com sudo."
    exit 1
fi

# Atualizar pacotes
log "Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y

# Instalar dependências e ferramentas
log "Instalando pacotes essenciais para máquinas virtuais..."
sudo apt-get install -y \
    qemu-system uml-utilities virt-manager git wget libguestfs-tools \
    p7zip-full make dmg2img tesseract-ocr tesseract-ocr-eng genisoimage \
    vim net-tools screen qemu-system-x86 qemu-utils virt-viewer \
    libvirt-daemon-system libvirt-clients bridge-utils qemu-kvm \
    libvirt-clients libvirt-daemon-system bridge-utils virt-manager \
    libguestfs-tools

# Habilitar e iniciar os serviços
log "Habilitando e iniciando os serviços necessários..."
sudo systemctl enable --now libvirtd
sudo systemctl enable --now virtlogd

# Configurar o KVM para ignorar msrs
log "Configurando KVM para ignorar MSRs..."
echo 1 | sudo tee /sys/module/kvm/parameters/ignore_msrs

# Carregar o módulo do KVM
log "Carregando o módulo do KVM..."
sudo modprobe kvm

# Exibir status
log "Configuração concluída! Verifique se os serviços estão ativos com o comando: sudo systemctl status libvirtd"
