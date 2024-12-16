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
log "Atualizando pacotes do sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar o Docker
log "Instalando Docker..."
sudo apt install -y docker.io

# Configurar grupo Docker
log "Criando grupo docker e adicionando usuários..."
if ! getent group docker > /dev/null; then
    sudo groupadd docker
else
    log "Grupo docker já existe."
fi

sudo usermod -aG docker "$USER"
log "Adicionado o usuário atual ($USER) ao grupo docker."

# Iniciar e habilitar o serviço Docker
log "Iniciando e habilitando o serviço Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# Verificar o status do Docker
log "Verificando status do Docker..."
sudo systemctl status docker --no-pager

# Configurar permissões do Docker Socket
log "Configurando permissões do Docker Socket..."
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock

# Instalar dependências adicionais
log "Instalando dependências adicionais para o Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Testar a instalação do Docker
log "Testando a instalação do Docker..."
docker run hello-world || echo -e "\e[1;31m[ERRO]\e[0m Falha ao executar o container de teste. Verifique o Docker."

log "Instalação e configuração do Docker concluídas com sucesso!"
