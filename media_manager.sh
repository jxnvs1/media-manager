#!/bin/bash

# Informações do script
# Criador: Jonas
# Descrição: Script para gerenciamento de mídias (filmes, séries, animes) com banco de dados SQLite3.
# Requisitos: sqlite3
# Compatibilidade: Distribuições Linux com SQLite3 instalado.

# Arquivo do banco de dados
DB_FILE="$HOME/.media_db.sqlite"

# Cores para exibição
RED='\033[0;31m'     # Vermelho
YELLOW='\033[1;33m'  # Amarelo
GREEN='\033[0;32m'   # Verde
NC='\033[0m'         # Sem cor

# Função para verificar os requisitos necessários
check_requirements() {
    if ! command -v sqlite3 &>/dev/null; then
        echo -e "${RED}Erro: sqlite3 não está instalado.${NC}"
        echo -e "Para instalar, use os seguintes comandos nas principais distribuições:"
        echo -e "  - Debian/Ubuntu: sudo apt install sqlite3"
        echo -e "  - Fedora: sudo dnf install sqlite"
        echo -e "  - Arch Linux: sudo pacman -S sqlite"
        exit 1
    fi
}

# Função para inicializar o banco de dados
initialize_db() {
    sqlite3 "$DB_FILE" <<EOF
CREATE TABLE IF NOT EXISTS media (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    name TEXT NOT NULL,
    status INTEGER NOT NULL,
    part TEXT NOT NULL,
    date TEXT NOT NULL
);
EOF
}

# Função para gerar um ID único para a mídia
generate_unique_id() {
    local id
    id=$((RANDOM))
    while sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM media WHERE id = $id;" | grep -q "1"; do
        id=$((RANDOM))
    done
    echo "$id"
}

# Função para adicionar mídias
add_media() {
    local type
    # Solicita o tipo da mídia antes de tudo
    echo "Escolha o tipo de mídia:"
    echo "1 - Filme"
    echo "2 - Série"
    echo "3 - Anime"
    read -p "Escolha uma opção (1, 2 ou 3): " type_option

    case $type_option in
        1) type="Filme" ;;
        2) type="Série" ;;
        3) type="Anime" ;;
        *) echo "Opção inválida!"; return ;;
    esac

    # Solicita os nomes das mídias
    read -e -p "Digite os nomes das mídias, separados por ponto e vírgula (;): " names_input
    IFS=';' read -ra names <<< "$names_input"

    # Loop para adicionar cada mídia separadamente
    for name in "${names[@]}"; do
        name=$(echo "$name" | xargs) # Remove espaços extras

        local id=$(generate_unique_id)
        echo "Defina o status para '$name':"
        echo "1 - Para Assistir"
        echo "2 - Estou Assistindo"
        echo "3 - Concluído"
        read -p "Escolha o status: " status

        local part="N/A"
        local date="N/A"

        # Define informações adicionais com base no status
        if [[ $status == 2 ]]; then
            if [[ $type == "Série" || $type == "Anime" ]]; then
                read -e -p "Temporada: " season
                read -e -p "Episódio: " episode
                part="T$season EP$episode"
            else
                read -e -p "Minutagem atual (Ex: 20Min ou 1h3Min): " minutagem
                part="${minutagem:-N/A}"
            fi
        elif [[ $status == 3 ]]; then
            date=$(date +%Y-%m-%d)
        fi

        # Insere a mídia no banco de dados
        sqlite3 "$DB_FILE" "INSERT INTO media (id, type, name, status, part, date) VALUES ($id, '$type', '$name', $status, '$part', '$date');"
        echo "Entrada para '$name' adicionada com sucesso!"
    done
}

# Função para exibir as mídias organizadas por tipo e status
show_all_media() {
    clear
    echo "Mídias Cadastradas:"
    echo "----------------------------"

    # Função auxiliar para exibir mídias por tipo e status
    display_media_by_type_and_status() {
        local type=$1
        local status=$2
        local status_label=$3
        local color=$4

        local media=$(sqlite3 "$DB_FILE" "SELECT name, part, id FROM media WHERE type = '$type' AND status = $status;")
        if [[ -n $media ]]; then
            echo -e "${color}${type}s - ${status_label}:${NC}"
            sqlite3 "$DB_FILE" "SELECT name, part, id FROM media WHERE type = '$type' AND status = $status;" | while IFS='|' read -r name part id; do
                printf "  [%s] %s (%s)\n" "$id" "$name" "$part"
            done
            echo
        fi
    }

    # Exibição por tipo e status
    for type in "Filme" "Série" "Anime"; do
        display_media_by_type_and_status "$type" 1 "Para Assistir" "$RED"
        display_media_by_type_and_status "$type" 2 "Estou Assistindo" "$YELLOW"
        display_media_by_type_and_status "$type" 3 "Concluído" "$GREEN"
    done
}

# Função para alterar o status de uma mídia
change_status() {
    read -p "Digite o ID da mídia que deseja alterar: " id

    entry=$(sqlite3 "$DB_FILE" "SELECT * FROM media WHERE id = $id;")
    if [[ -z $entry ]]; then
        echo "ID não encontrado!"
        return
    fi

    echo "Novo status (1 - Para Assistir, 2 - Estou Assistindo, 3 - Concluído):"
    read new_status

    local new_part="N/A"
    local new_date="N/A"

    if [[ $new_status == 2 ]]; then
        read -e -p "Nova parte (Ex: T2 EP3 ou 1h20Min): " new_part
    elif [[ $new_status == 3 ]]; then
        new_date=$(date +%Y-%m-%d)
    fi

    sqlite3 "$DB_FILE" "UPDATE media SET status = $new_status, part = '$new_part', date = '$new_date' WHERE id = $id;"
    echo "Status da mídia atualizado com sucesso!"
}

# Função para remover uma mídia
remove_media() {
    read -p "Digite o ID da mídia que deseja remover: " id
    sqlite3 "$DB_FILE" "DELETE FROM media WHERE id = $id;"
    echo "Mídia removida com sucesso!"
}

# Função para exibir o menu principal
show_menu() {
    while true; do
        clear
        show_all_media
        echo "1. Adicionar mídia"
        echo "2. Alterar status da mídia"
        echo "3. Remover mídia"
        echo "4. Sair"
        read -p "Escolha uma opção: " choice

        case $choice in
            1) add_media ;;
            2) change_status ;;
            3) remove_media ;;
            4) exit 0 ;;
            *) echo "Opção inválida!" ;;
        esac
    done
}

# Início do script
check_requirements
initialize_db
show_menu
