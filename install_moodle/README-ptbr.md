# Script de Instalação Automatizada do Moodle

## Tecnologias Utilizadas

[![Operating Systems](https://go-skill-icons.vercel.app/api/icons?i=linux,ubuntu,debian,bash,nginx,docker,git,github)](https://github.com/Danzokka)

## Bancos de Dados Suportados

[![Databases](https://go-skill-icons.vercel.app/api/icons?i=mysql,mariadb,postgresql)](https://github.com/Danzokka)

## Visão Geral

Este script automatiza a instalação do Moodle em servidores Linux, realizando desde a instalação de dependências, configuração do banco de dados, PHP, Nginx, até a obtenção de certificados SSL e configuração do cron. Ele permite parametrização completa via linha de comando e pode ser utilizado tanto com banco de dados local quanto via Docker.

## Sistemas Operacionais Suportados

- Ubuntu 18.04+
- Debian 10+
- Linux Mint

> **Observação:** O script foi desenvolvido e testado em distribuições Linux. Para uso em Windows, recomenda-se o uso de WSL2 ou ambiente compatível.

## Pré-requisitos

- Acesso root ou sudo
- Git instalado (para clonar o repositório)
- Conexão com a internet

## Como Instalar

1. Clone o repositório:
   ```bash
   git clone https://github.com/Danzokka/install_scripts.git
   cd install_scripts/install_moodle
   ```
2. Torne o script executável:
   ```bash
   chmod +x install.sh
   ```
3. Execute o script com as opções desejadas:
   ```bash
   sudo bash install.sh [opções]
   ```

## Parâmetros Disponíveis

| Parâmetro      | Descrição                                                    | Valor padrão   |
| -------------- | ------------------------------------------------------------ | -------------- |
| --docker       | Utiliza Docker para o banco de dados (não precisa valor)     | false          |
| --mount-point  | Diretório do host para persistência do banco (apenas Docker) | (não definido) |
| --db           | Tipo do banco de dados (mariadb/mysql/postgresql)            | mariadb        |
| --dbuser       | Usuário do banco de dados                                    | admin          |
| --dbpassword   | Senha do banco de dados                                      | password       |
| --dbname       | Nome do banco de dados                                       | moodle         |
| --php          | Versão do PHP                                                | 8.2            |
| --domain       | Domínio do Moodle                                            | example.com    |
| --moodle       | Versão do Moodle                                             | 4.5            |
| --memory_limit | Limite de memória do PHP                                     | 1G             |
| --max_size     | Tamanho máximo de upload                                     | 4G             |

### Exemplo de uso

```bash
sudo bash install.sh --docker --mount-point /srv/moodle-db --db postgresql --dbuser admin --dbpassword 123456 --dbname moodle --php 8.2 --domain "exemplo.seudominio.com" --moodle 4.1.8 --memory_limit 512M --max_size 128M
```

## O que o script faz por trás

- Atualiza o sistema e instala dependências
- Instala e configura MariaDB, MySQL ou PostgreSQL (local ou via Docker)
- Cria banco de dados e usuário
- Instala PHP e extensões necessárias
- Instala e configura Nginx
- Clona a versão correta do Moodle do repositório oficial do GitHub
- Ajusta permissões e configurações do PHP
- Configura o Nginx para o domínio informado
- Instala e configura SSL com Certbot
- Agenda o cron do Moodle

## Utilizando Docker para o Banco de Dados

Ao passar o parâmetro `--docker`, o script irá utilizar um container Docker para o banco de dados. Você pode também usar `--mount-point /seu/diretorio/host` para persistir os dados do banco no host, permitindo que múltiplos containers compartilhem o mesmo diretório de dados.

## Observações

- O script baixa a versão do Moodle diretamente do repositório oficial do GitHub, garantindo sempre a branch correta para a versão.
- Recomenda-se rodar o script em uma máquina limpa para evitar conflitos de dependências.

## Licença

Este projeto está sob a licença MIT.

## Contribuição

Sinta-se à vontade para abrir issues ou pull requests para melhorias!
