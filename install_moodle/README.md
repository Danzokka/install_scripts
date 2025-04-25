# Script: Automated Moodle Installation

## Tecnologies Used

[![Operating Systems](https://go-skill-icons.vercel.app/api/icons?i=linux,ubuntu,debian,bash,nginx,docker,git,github)](https://github.com/Danzokka)

## Databases Supported

[![Databases](https://go-skill-icons.vercel.app/api/icons?i=mysql,mariadb,postgresql)](https://github.com/Danzokka)

## Overview

This script automates the installation of Moodle on Linux servers, handling dependencies, database setup, PHP, Nginx, SSL certificates, and cron configuration. It supports full command-line parameterization and can use either a local or Dockerized database.

## Supported Operating Systems

- Ubuntu 18.04+
- Debian 10+
- Linux Mint

> **Note:** The script is developed and tested for Linux distributions. For Windows, use WSL2 or a compatible environment.

## Prerequisites

- Root or sudo access
- Git installed (to clone the repository)
- Internet connection

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Danzokka/install_scripts.git
   cd install_scripts/install_moodle
   ```
2. Make the script executable:
   ```bash
   chmod +x install.sh
   ```
3. Run the script with desired options:
   ```bash
   sudo bash install.sh [options]
   ```

## Available Parameters

| Parameter      | Description                                              | Default value |
| -------------- | -------------------------------------------------------- | ------------- |
| --docker       | Use Docker for the database (no value needed)            | false         |
| --mount-point  | Host directory to mount for DB persistence (Docker only) | (not set)     |
| --db           | Database type (mariadb/mysql/postgresql)                 | mariadb       |
| --dbuser       | Database user                                            | admin         |
| --dbpassword   | Database password                                        | password      |
| --dbname       | Database name                                            | moodle        |
| --php          | PHP version                                              | 8.2           |
| --domain       | Moodle domain                                            | example.com   |
| --moodle       | Moodle version                                           | 4.5           |
| --memory_limit | PHP memory limit                                         | 1G            |
| --max_size     | Max upload size                                          | 4G            |

### Example usage

```bash
sudo bash install.sh --docker --mount-point /srv/moodle-db --db postgresql --dbuser admin --dbpassword 123456 --dbname moodle --php 8.2 --domain "example.yourdomain.com" --moodle 4.1.8 --memory_limit 512M --max_size 128M
```

## How it works

- Updates the system and installs dependencies
- Installs and configures MariaDB, MySQL, or PostgreSQL (local or via Docker)
- Creates the database and user
- Installs PHP and required extensions
- Installs and configures Nginx
- Clones the correct Moodle version from the official GitHub repository
- Sets permissions and PHP configuration
- Configures Nginx for the provided domain
- Installs and configures SSL with Certbot
- Schedules the Moodle cron

## Using Docker for the Database

When using the `--docker` parameter, the script will use a Docker container for the database. You can also use `--mount-point /your/host/dir` to persist database data on the host, allowing multiple containers to share the same data directory.

## Notes

- The script fetches the Moodle version directly from the official GitHub repository, ensuring the correct branch for the version.
- It is recommended to run the script on a clean machine to avoid dependency conflicts.

## License

This project is licensed under the MIT License.

## Contributing

Feel free to open issues or pull requests for improvements!
