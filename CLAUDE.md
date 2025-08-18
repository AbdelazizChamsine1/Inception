# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Inception project for 42 School that implements a containerized web infrastructure using Docker Compose. The project consists of three services: NGINX (reverse proxy with TLS), WordPress (CMS with PHP-FPM), and MariaDB (database server).

## Common Commands

### Build and Run Infrastructure
```bash
# Build and start all containers
make

# Stop containers
make down

# Clean and rebuild everything
make re

# Complete cleanup (removes data directories)
make fclean
```

### Docker Compose Operations
```bash
# Direct docker-compose commands (run from project root)
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up --build -d
docker compose -f srcs/docker-compose.yml down

# View logs for specific service
docker-compose -f srcs/docker-compose.yml logs [nginx|wordpress|mariadb]

# Check container status
docker ps
```

### Testing and Debugging
```bash
# Test HTTPS access
curl -k https://achamsin.42.fr

# Access running containers
docker exec -it nginx /bin/bash
docker exec -it wordpress /bin/bash
docker exec -it mariadb /bin/bash
```

## Architecture

### Service Architecture
- **NGINX Container**: Acts as reverse proxy, handles TLS termination (port 443), redirects HTTP to HTTPS
- **WordPress Container**: Runs PHP-FPM on port 9000, serves WordPress CMS
- **MariaDB Container**: Database server on port 3306, stores WordPress data

### Data Flow
1. External requests hit NGINX on port 443 (TLS)
2. NGINX proxies PHP requests to WordPress container via FastCGI
3. WordPress connects to MariaDB for database operations
4. Static files served directly by NGINX from shared volume

### Key Configuration Files
- `srcs/.env`: Environment variables for all services (domain, passwords, users)
- `srcs/docker-compose.yml`: Service definitions and networking
- `srcs/requirements/nginx/conf/nginx.conf`: NGINX reverse proxy and TLS config
- `srcs/requirements/wordpress/tools/start.sh`: WordPress installation and setup script
- `srcs/requirements/mariadb/tools/init_db.sh`: Database initialization script

### Data Persistence
- MariaDB data: `/home/$USER/data/mariadb` (bind mount)
- WordPress files: `/home/$USER/data/wordpress` (bind mount, shared with NGINX)

### Security Features
- TLS-only access (no plain HTTP allowed)
- Self-signed SSL certificates generated during build
- Environment variables for sensitive data (no hardcoded passwords)
- Restricted WordPress admin usernames (42achamsinAdmin, not 'admin')
- Database user isolation

## Domain Configuration

Before running, update the domain in `srcs/.env`:
```bash
DOMAIN_NAME=your_login.42.fr
```

Add to `/etc/hosts`:
```
127.0.0.1 your_login.42.fr
```

## Container Build Process

Each container follows this pattern:
1. **Base Image**: All use `debian:bullseye`
2. **Dependencies**: Install required packages via apt-get
3. **Configuration**: Copy custom config files and setup scripts
4. **Initialization**: Run service-specific setup (SSL, database init, WordPress install)
5. **Runtime**: Start the main service process

### Build Dependencies
- NGINX: nginx, openssl
- WordPress: php7.4, php7.4-fpm, php7.4-mysql, wget, curl, mariadb-client
- MariaDB: mariadb-server

## WordPress Setup

The WordPress container automatically:
1. Downloads WordPress using WP-CLI
2. Creates wp-config.php with database connection
3. Installs WordPress with admin user
4. Creates additional regular user
5. Configures HTTPS URLs
6. Starts PHP-FPM service

Default users (credentials in `.env`):
- Admin: 42achamsinAdmin
- Regular: 42_User