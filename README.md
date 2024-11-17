# Media Manager

Este é um script em Bash para gerenciar filmes, séries e animes utilizando SQLite3. O script permite organizar e rastrear o progresso de mídias, incluindo a opção de alterar status (Para Assistir, Estou Assistindo, Concluído) e registrar a parte assistida, seja por episódio ou minutagem.

## Funcionalidades

- Adicionar mídias (Filmes, Séries, Animes)
- Alterar status de mídias (Para Assistir, Estou Assistindo, Concluído)
- Atualizar progresso de mídias (Temporada/ Episódio ou Minutagem)
- Visualizar todas as mídias organizadas por tipo e status

## Requisitos

- SQLite3
- Bash

## Como Usar

1. Baixe ou clone o repositório.
2. Torne o script executável: `chmod +x media_manager.sh`
3. Execute o script: `./media_manager.sh`

## Instalação das Dependências

**Debian/Ubuntu**:
```bash
sudo apt install sqlite3
