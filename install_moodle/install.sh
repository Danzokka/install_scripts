#!/bin/bash
# Automated installation script for Moodle with configurable parameters
# Example usage:

set -e

# Colors for terminal
ORANGE='\033[38;5;208m'
LIGHT_ORANGE='\033[38;5;215m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
USE_DOCKER=false
MOUNT_POINT=""
DB_TYPE="mariadb"
DB_USER="admin"
DB_PASSWORD="password"
DB_NAME="moodle"
PHP_VERSION="8.2"
MOODLE_VERSION="4.5"
DOMAIN="example.com"
MEMORY_LIMIT="1G"
MAX_SIZE="4G"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --docker)
      USE_DOCKER=true
      shift
      ;;
    --no-docker)
      USE_DOCKER=false
      shift
      ;;
    --mount-point)
      MOUNT_POINT="$2"
      shift 2
      ;;
    --db)
      DB_TYPE="$2"
      shift 2
      ;;
    --dbuser)
      DB_USER="$2"
      shift 2
      ;;
    --dbpassword)
      DB_PASSWORD="$2"
      shift 2
      ;;
    --dbname)
      DB_NAME="$2"
      shift 2
      ;;
    --php)
      PHP_VERSION="$2"
      shift 2
      ;;
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --moodle)
      MOODLE_VERSION="$2"
      shift 2
      ;;
    --memory_limit)
      MEMORY_LIMIT="$2"
      shift 2
      ;;
    --max_size)
      MAX_SIZE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1"
      exit 1
      ;;
  esac
 done

# Show configuration
cat <<INFO
${CYAN}Selected configuration:${NC}
  Database: $DB_TYPE
  Docker: $USE_DOCKER
  DB User: $DB_USER
  DB Password: $DB_PASSWORD
  DB Name: $DB_NAME
  PHP: $PHP_VERSION
  Moodle: $MOODLE_VERSION
  Domain: $DOMAIN
  Memory Limit: $MEMORY_LIMIT
  Max Size: $MAX_SIZE
  Mount Point: $MOUNT_POINT
INFO

# Function for spinner animation
show_spinner() {
  local pid=$1
  local msg="$2"
  local color="$3"
  local delay=0.2
  local spinstr='...'
  local i=0
  tput civis 2>/dev/null
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) % 3 ))
    printf "\r${color}%s%s${NC}" "$msg" "${spinstr:0:$i}"
    sleep $delay
  done
  printf "\r${color}%s... [OK]${NC}\n" "$msg"
  tput cnorm 2>/dev/null
}

# 1. Update packages
(echo > /dev/null; apt update > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1) &
SPIN_PID=$!
show_spinner $SPIN_PID "Updating packages" "$CYAN"

# 2. Install basic dependencies
(echo > /dev/null; apt install -y software-properties-common unzip wget curl lsb-release ca-certificates apt-transport-https > /dev/null 2>&1) &
SPIN_PID=$!
show_spinner $SPIN_PID "Installing basic dependencies" "$CYAN"

# 2.1 Install Docker if needed
if [[ "$USE_DOCKER" == true ]]; then
  if ! command -v docker &> /dev/null; then
    (echo > /dev/null; apt install -y docker.io > /dev/null 2>&1; systemctl enable docker > /dev/null 2>&1; systemctl start docker > /dev/null 2>&1) &
    SPIN_PID=$!
    show_spinner $SPIN_PID "Installing Docker" "$BLUE"
  fi
fi

# 3. Install and configure database
if [[ "$USE_DOCKER" == true ]]; then
  echo -e "${BLUE}Starting $DB_TYPE database with Docker...${NC}"
  DOCKER_MOUNT=""
  if [[ -n "$MOUNT_POINT" ]]; then
    DOCKER_MOUNT="-v $MOUNT_POINT:/var/lib/mysql"
    if [[ $DB_TYPE == "postgresql" || $DB_TYPE == "postgres" ]]; then
      DOCKER_MOUNT="-v $MOUNT_POINT:/var/lib/postgresql/data"
    fi
  fi
  if [[ $DB_TYPE == "mariadb" || $DB_TYPE == "mysql" ]]; then
    docker run -d --name ${DB_TYPE}_moodle $DOCKER_MOUNT -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD -e MYSQL_DATABASE=$DB_NAME -e MYSQL_USER=$DB_USER -e MYSQL_PASSWORD=$DB_PASSWORD -p 3306:3306 $DB_TYPE:latest
    sleep 20
  elif [[ $DB_TYPE == "postgresql" || $DB_TYPE == "postgres" ]]; then
    docker run -d --name postgres_moodle $DOCKER_MOUNT -e POSTGRES_DB=$DB_NAME -e POSTGRES_USER=$DB_USER -e POSTGRES_PASSWORD=$DB_PASSWORD -p 5432:5432 postgres:latest
    sleep 20
  else
    echo -e "${RED}Database $DB_TYPE is not supported with Docker.${NC}"
    exit 1
  fi
else
  if [[ $DB_TYPE == "mariadb" || $DB_TYPE == "mysql" ]]; then
    (echo > /dev/null; if ! command -v mariadb &> /dev/null; then apt install -y mariadb-server > /dev/null 2>&1; systemctl enable mariadb > /dev/null 2>&1; systemctl start mariadb > /dev/null 2>&1; fi) &
    SPIN_PID=$!
    show_spinner $SPIN_PID "Installing/configuring MariaDB/MySQL" "$YELLOW"
    mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF
  elif [[ $DB_TYPE == "postgresql" || $DB_TYPE == "postgres" ]]; then
    (echo > /dev/null; if ! command -v psql &> /dev/null; then apt install -y postgresql postgresql-contrib > /dev/null 2>&1; systemctl enable postgresql > /dev/null 2>&1; systemctl start postgresql > /dev/null 2>&1; fi) &
    SPIN_PID=$!
    show_spinner $SPIN_PID "Installing/configuring PostgreSQL" "$YELLOW"
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" || true
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" || true
    sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
  else
    echo -e "${RED}Database $DB_TYPE is not supported.${NC}"
    exit 1
  fi
fi

# 5. Install PHP and extensions
(echo > /dev/null; add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1; apt update > /dev/null 2>&1; apt install -y $PHP_EXT > /dev/null 2>&1) &
SPIN_PID=$!
show_spinner $SPIN_PID "Installing PHP and extensions" "$GREEN"

# 6. Install Nginx
(echo > /dev/null; apt install -y nginx > /dev/null 2>&1) &
SPIN_PID=$!
show_spinner $SPIN_PID "Installing Nginx" "$BLUE"

# Function to construct Moodle branch name
get_moodle_branch() {
  local version="$1"
  local major minor patch branch
  IFS='.' read -r major minor patch <<< "$version"
  if [[ $major -eq 3 && $minor -lt 9 ]]; then
    branch="MOODLE_${major}${minor}_STABLE"
  elif [[ $major -eq 3 && $minor -ge 9 ]]; then
    branch="MOODLE_${major}${minor}_STABLE"
  elif [[ $major -ge 4 ]]; then
    # padding for minor
    minor=$(printf "%02d" $minor)
    branch="MOODLE_${major}${minor}_STABLE"
  else
    echo "Moodle version not supported: $version"
    exit 1
  fi
  echo "$branch"
}

# Function to check if branch exists on GitHub
check_github_branch_exists() {
  local branch="$1"
  local url="https://github.com/moodle/moodle/tree/$branch"
  if curl -s -f -o /dev/null "$url"; then
    return 0
  else
    return 1
  fi
}

# 7. Download and install Moodle via GitHub
cd /tmp
BRANCH=$(get_moodle_branch "$MOODLE_VERSION")
echo -e "${ORANGE}Starting Moodle download (branch $BRANCH)...${NC}"
echo -e "${LIGHT_ORANGE}Checking if branch $BRANCH exists on GitHub...${NC}"
if check_github_branch_exists "$BRANCH"; then
  echo -e "${LIGHT_ORANGE}Cloning Moodle from branch $BRANCH...${NC}"
  git clone --branch "$BRANCH" --depth 1 https://github.com/moodle/moodle.git
else
  echo -e "${RED}Error: Branch $BRANCH for version $MOODLE_VERSION does not exist in the official Moodle repository.${NC}"
  exit 1
fi
mkdir -p /var/www/$DOMAIN
mkdir -p /var/www/$DOMAIN/moodledata
mv moodle /var/www/$DOMAIN/

# 8. Permissions
chown -R www-data:www-data /var/www/$DOMAIN/
chmod -R 755 /var/www/$DOMAIN/
chmod 700 /var/www/$DOMAIN/moodledata

# 9. Configure php.ini
PHPINI="/etc/php/$PHP_VERSION/fpm/php.ini"
sed -i "s/^upload_max_filesize.*/upload_max_filesize = $MAX_SIZE/" $PHPINI
sed -i "s/^post_max_size.*/post_max_size = $MAX_SIZE/" $PHPINI
sed -i "s/^memory_limit.*/memory_limit = $MEMORY_LIMIT/" $PHPINI
sed -i 's/^max_execution_time.*/max_execution_time = 360/' $PHPINI
# Remove ; if present before max_input_vars and adjust value
grep -qE '^;?max_input_vars' $PHPINI && \
  sed -i "s/^;\?max_input_vars.*/max_input_vars = 5000/" $PHPINI || \
  echo "max_input_vars = 5000" >> $PHPINI
systemctl restart php$PHP_VERSION-fpm

# 10. Configure Nginx
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
cat > $NGINX_CONF <<EOL
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/$DOMAIN/moodle;
    index index.php index.html index.htm;

    client_max_body_size $MAX_SIZE;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ [^/].php(/|$) {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location /dataroot/ {
        internal;
        alias /var/www/$DOMAIN/moodledata/;
    }
}
EOL

ln -sf $NGINX_CONF /etc/nginx/sites-enabled/$DOMAIN

# Add client_max_body_size to global nginx.conf
NGINX_MAIN_CONF="/etc/nginx/nginx.conf"
if grep -q "^\s*client_max_body_size" $NGINX_MAIN_CONF; then
  sed -i "s/^\s*client_max_body_size.*/    client_max_body_size $MAX_SIZE;/" $NGINX_MAIN_CONF
else
  sed -i "/##\\n# Basic Settings\\n##/a \\    client_max_body_size $MAX_SIZE;" $NGINX_MAIN_CONF
fi

nginx -t && systemctl reload nginx

# 11. Install Certbot
(echo > /dev/null; apt install -y certbot python3-certbot-nginx > /dev/null 2>&1; certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN --redirect > /dev/null 2>&1) &
SPIN_PID=$!
show_spinner $SPIN_PID "Installing Certbot and configuring SSL" "$CYAN"

# 12. Enable Moodle cron
echo -e "${GREEN}Configuring Moodle cron...${NC}"
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/$DOMAIN/moodle/admin/cli/cron.php > /dev/null 2>&1") | crontab -

# End
echo -e "${GREEN}Installation complete. Access http://$DOMAIN to finalize Moodle setup.${NC}"
