#!/bin/bash

# Diretório contendo as ROMs (alterar caminho para o correto)
diretorio_roms="/media/eajd/sdb/ROMS - extras/NES"

# Navega até o diretório especificado
cd "$diretorio_roms" || { echo "Diretório não encontrado."; exit 1; }

# Declaração de um array associativo para armazenar as ROMs selecionadas
declare -A roms_selecionadas

# Processa todas as ROMs no diretório
for arquivo in *; do
  # Extrai o nome base do jogo (antes do parêntese)
  nome_base=$(echo "$arquivo" | sed -E 's/ \(.*//')

  # Verifica se o arquivo contém idiomas de interesse (USA, EN, World, ou PT-BR)
  if [[ "$arquivo" =~ \(USA\) ]] || [[ "$arquivo" =~ \(World\) ]] || [[ "$arquivo" =~ \(PT-BR\) ]] || [[ "$arquivo" =~ \(En ]] || [[ "$arquivo" =~ \(En, ]]; then
    # Extrai a versão do arquivo
    versao_atual=$(echo "$arquivo" | grep -oP '\(V[0-9]+\.[0-9]+\.[0-9]+\)' || echo "(V0.0.0)")

    # Verifica se já existe uma versão armazenada para o mesmo jogo
    if [[ -n "${roms_selecionadas[$nome_base]}" ]]; then
      # Extrai a versão armazenada
      versao_armazenada=$(echo "${roms_selecionadas[$nome_base]}" | grep -oP '\(V[0-9]+\.[0-9]+\.[0-9]+\)' || echo "(V0.0.0)")

      # Compara as versões e mantém a mais recente
      if [[ "$versao_atual" > "$versao_armazenada" ]]; then
        roms_selecionadas["$nome_base"]="$arquivo"
      fi
    else
      # Armazena a ROM atual como a selecionada
      roms_selecionadas["$nome_base"]="$arquivo"
    fi
  fi
done

# Exclui as ROMs não selecionadas
for arquivo in *; do
  # Extrai o nome base do arquivo atual
  nome_base=$(echo "$arquivo" | sed -E 's/ \(.*//')

  # Conta o número de ROMs disponíveis para o mesmo nome base
  num_roms=$(ls | grep -E "^$nome_base" | wc -l)

  # Se houver mais de uma ROM para este jogo e o arquivo não for o selecionado, remove
  if [[ $num_roms -gt 1 && "${roms_selecionadas[$nome_base]}" != "$arquivo" ]]; then
    echo "Removendo: $arquivo"
    rm "$arquivo"
  fi
done

