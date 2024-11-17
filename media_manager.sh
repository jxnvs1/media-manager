#!/bin/bash
################################################################################
# Gerenciador de Mídias
# Criado por: Jonas Santana
# Versão: 1.3
# Descrição: Organiza filmes, séries e animes, separando por status e categorias.
# Requisitos: SQLite3, Bash
################################################################################

# Caminho do banco de dados
DB_FILE="$HOME/.media_db.sqlite"

# Cores para saída
RED='\033[0;31m'     
YELLOW='\033[1;33m'  
GREEN='\033[0;32m'   
BLUE='\033[0;34m'    
NC='\033[0m'         

# Função para verificar dependências
check_dependencies() {
    local missing=0
    echo "Verificando dependências..."

    if ! command -v sqlite3 &>/dev/null; then
        echo -e "${RED}SQLite3 não está instalado!${NC}"
        missing=1
    fi

    if (( missing == 1 )); then
        echo -e "\n${YELLOW}Instale os requisitos com:${NC}"
        echo -e "${BLUE}Debian/Ubuntu:${NC} sudo apt install sqlite3"
        echo -e "${BLUE}Fedora:${NC} sudo dnf install sqlite"
        echo -e "${BLUE}Arch Linux:${NC} sudo pacman -S sqlite"
        echo -e "${BLUE}OpenSUSE:${NC} sudo zypper install sqlite3"
        exit 1
    fi
}

# Inicializar o banco de dados
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

# Mostrar todas as mídias organizadas por tipo e status
show_all_media() {
    clear

    show_by_type_and_status() {
        local type="$1"
        local color="$2"
        echo -e "${color}$type:${NC}"
        sqlite3 "$DB_FILE" "SELECT id, name, status, part, date FROM media WHERE type = '$type';" | while IFS='|' read -r id name status part date; do
            case $status in
                1) status_text="Para Assistir" ;;
                2) status_text="Estou Assistindo" ;;
                3) status_text="Concluído" ;;
                *) status_text="Desconhecido" ;;
            esac

            printf "  %-5s %-30s %-20s %-15s %-10s\n" "$id" "$name" "$status_text" "$part" "$date"
        done
        echo
    }

    echo "Mídias Cadastradas:"
    printf "%-5s %-30s %-20s %-15s %-10s\n" "ID" "Nome" "Status" "Informações" "Data"
    echo "--------------------------------------------------------------------------------------------"

    show_by_type_and_status "Filme" "$BLUE"
    show_by_type_and_status "Série" "$GREEN"
    show_by_type_and_status "Anime" "$YELLOW"
}

# Adicionar mídia
add_media() {
    echo "Selecione o tipo de mídia:"
    echo "1. Filme"
    echo "2. Série"
    echo "3. Anime"
    read -p "Escolha uma opção: " type_choice

    case $type_choice in
        1) type="Filme" ;;
        2) type="Série" ;;
        3) type="Anime" ;;
        *) echo "Opção inválida!" ; return ;;
    esac

    read -e -p "Digite o nome da mídia: " name

    echo "Escolha o status inicial:"
    echo "1 - Para Assistir"
    echo "2 - Estou Assistindo"
    echo "3 - Concluído"
    read -p "Escolha o status: " status

    local part="N/A"
    local date="N/A"
    if [[ $status == 2 ]]; then
        read -e -p "Progresso (Ex: T1 EP5 ou 30Min): " part
    elif [[ $status == 3 ]]; then
        date=$(date +%Y-%m-%d)
    fi

    sqlite3 "$DB_FILE" "INSERT INTO media (type, name, status, part, date) VALUES ('$type', '$name', $status, '$part', '$date');"
    echo "Mídia '$name' adicionada com sucesso!"
}

# Alterar status da mídia
change_status() {
    read -p "Digite o ID da mídia: " id

    local entry
    entry=$(sqlite3 "$DB_FILE" "SELECT * FROM media WHERE id = $id;")
    if [[ -z $entry ]]; then
        echo "ID não encontrado!"
        return
    fi

    echo "Selecione o novo status:"
    echo "1 - Para Assistir"
    echo "2 - Estou Assistindo"
    echo "3 - Concluído"
    read -p "Escolha o novo status: " new_status

    local new_date="N/A"
    if [[ $new_status == 3 ]]; then
        new_date=$(date +%Y-%m-%d)
    fi

    sqlite3 "$DB_FILE" "UPDATE media SET status = $new_status, date = '$new_date' WHERE id = $id;"
    echo "Status atualizado para ID $id!"
}

# Atualizar o progresso da mídia
update_progress() {
    read -p "Digite o ID da mídia: " id

    local entry
    entry=$(sqlite3 "$DB_FILE" "SELECT * FROM media WHERE id = $id;")
    if [[ -z $entry ]]; then
        echo "ID não encontrado!"
        return
    fi

    read -e -p "Atualize o progresso (Ex: T2 EP3 ou 45Min): " new_part
    sqlite3 "$DB_FILE" "UPDATE media SET part = '$new_part' WHERE id = $id;"
    echo "Progresso atualizado para ID $id!"
}

# Gerenciar mídias
manage_media() {
    while true; do
        clear
        show_all_media
        echo -e "\nEscolha uma opção:"
        echo "1. Adicionar nova mídia"
        echo "2. Alterar status"
        echo "3. Atualizar progresso"
        echo "4. Voltar ao menu principal"
        echo "5. Sair"
        read -p "Escolha uma opção: " choice

        case $choice in
            1) add_media ;;
            2) change_status ;;
            3) update_progress ;;
            4) break ;;
            5) exit 0 ;;
            *) echo "Opção inválida!" ;;
        esac
    done
}

# Menu principal
show_menu() {
    initialize_db
    while true; do
        clear
        echo "Menu Principal:"
        echo "1. Gerenciar Mídias"
        echo "2. Sair"
        read -p "Escolha uma opção: " choice

        case $choice in
            1) manage_media ;;
            2) exit 0 ;;
            *) echo "Opção inválida!" ;;
        esac
    done
}

# Verificar dependências e iniciar o programa
check_dependencies
show_menu
