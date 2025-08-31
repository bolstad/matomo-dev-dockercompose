# Local Matomo Development Environment with Docker Compose

**Author:** Christian Bolstad (christian@carnaby.se)

This repository provides a docker-compose.yml configuration to set up a local development environment for Matomo analytics quickly.

It features the latest Matomo and MariaDB images, a bind-mounted volume for live code editing of Matomo files directly from your host machine, and an exposed MariaDB port for direct database access.

Suitable for:

* Developing custom Matomo plugins or themes.
* Testing Matomo configurations locally.
* Running multiple Matomo instances without conflicts.

# Features

* **Bleeding edge:** Uses latest official Matomo and MariaDB images as default (but you can easily pin a specific version, see 'Customization').
* **Writable matomo files:** The Matomo web root (/var/www/html) is mounted to a local ./matomo_data directory, allowing you to edit files directly on your host with your preferred IDE or editor.
* **Access DB from host:** MariaDB port is exposed for easy connection with your standard database management tools.
* **Persistent data:** Both Matomo files (if using the bind mount for /var/www/html) and database data (in ./db_data) are persisted on your host machine.
* **Configuration via .env file:** All settings (ports, passwords, container names) are externalized to a `.env` file for easy customization without modifying docker-compose.yml. This makes it easy to run several development instances in parallel without port conflicts. 
* **No conflicts:** Default configuration uses non-standard ports (8081 for web, 3307 for database) to avoid conflicts with other local services.
* **Makefile for common tasks:** Start/stop/tail logs/start shell/start Mysql cli via `make` commands 

## Environment Configuration (.env file)

This setup uses a `.env` file to manage all configuration settings. This allows you to easily customize ports, passwords, and other settings without modifying the `docker-compose.yml` file.

### Default .env Configuration

The repository includes a `.env.example` file with the following configurable values (copy to `.env` for use):

```bash
# Port Configuration
MATOMO_PORT=8081              # Web interface port (default: 8081 to avoid conflicts)
DB_PORT=3307                  # Database port (default: 3307 to avoid conflicts)

# Database Configuration
MYSQL_ROOT_PASSWORD=dev_root_password123
MYSQL_DATABASE=matomo
MYSQL_USER=matomo_user
MYSQL_PASSWORD=dev_matomo_password123

# Matomo Configuration
MATOMO_DATABASE_HOST=db
MATOMO_DATABASE_ADAPTER=mysql
MATOMO_DATABASE_TABLES_PREFIX=matomo_
MATOMO_DATABASE_DBNAME=matomo
MATOMO_DATABASE_USERNAME=matomo_user
MATOMO_DATABASE_PASSWORD=dev_matomo_password123

# Container Names
MATOMO_CONTAINER_NAME=matomo-dev
DB_CONTAINER_NAME=matomo-dev-db

# Network Configuration
NETWORK_NAME=matomo_dev_network

# Volume Paths
MATOMO_DATA_PATH=./matomo_data
DB_DATA_PATH=./db_data
```

### Avoiding Port Conflicts

If you're running multiple Matomo instances or other services, you can easily change the ports in the `.env` file:
- Change `MATOMO_PORT` if port 8081 is already in use
- Change `DB_PORT` if port 3307 is already in use

## Setup Instructions

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/bolstad/matomo-dev-dockercompose.git
    cd matomo-dev-dockercompose
    ```

2.  **Create and Update the .env file:**
    Copy `.env.example` to `.env` and update according to your needs:
    * **IMPORTANT: Change the default passwords** for security:
        * `MYSQL_ROOT_PASSWORD`
        * `MYSQL_PASSWORD` and `MATOMO_DATABASE_PASSWORD` (must match)
    * Adjust ports if needed to avoid conflicts:
        * `MATOMO_PORT` (default: 8081)
        * `DB_PORT` (default: 3307)
    * Optionally customize container names and paths

3.  **Data Directories:**
    The data directories (`matomo_data` and `db_data`) will be created automatically when you first run `docker-compose up`.
    * `./matomo_data`: Will store Matomo's application files.
    * `./db_data`: Will store MariaDB's data.

    *Note on Permissions:* If you are on Linux, Docker might create these directories as `root`. You may need to adjust their ownership and permissions afterwards to allow your host user to write to `./matomo_data` (e.g., `sudo chown -R $(whoami):$(whoami) matomo_data db_data`).

## Makefile Commands

This project includes a Makefile that provides convenient shortcuts for common Docker Compose operations. All commands read configuration from the `.env` file automatically.

### Available Commands

| Command | Description |
|---------|-------------|
| `make help` | Display all available commands |
| `make up` | Start the Docker containers in detached mode |
| `make down` | Stop and remove the Docker containers |
| `make restart` | Stop and restart all containers |
| `make status` | Show the current status of all containers |
| `make shell` | Open a bash shell inside the Matomo container |
| `make db` | Connect to MariaDB as the application user |
| `make db-root` | Connect to MariaDB as root user |
| `make logs` | Follow logs from all containers |
| `make logs-matomo` | Follow logs from the Matomo container only |
| `make logs-db` | Follow logs from the database container only |
| `make clean` | Stop containers and remove data directories (destructive) |

### Command Examples

```bash
# Start the development environment
make up

# Check container status
make status

# Access the Matomo container shell for debugging
make shell

# Connect to the database
make db

# View Matomo logs
make logs-matomo

# Restart everything
make restart
```

### Database Access

The `make db` command connects to the MariaDB database using the credentials defined in your `.env` file. It automatically selects the Matomo database and authenticates as the application user. For administrative tasks, use `make db-root` to connect with root privileges.

### Container Shell Access

The `make shell` command provides direct access to the Matomo container's filesystem at `/var/www/html`. This is useful for:
- Running Matomo console commands
- Checking file permissions
- Debugging PHP configuration
- Clearing cache manually

## Usage

1.  **Start the Environment:**
    Navigate to the directory containing your `docker-compose.yml` file in a terminal and run:
    ```bash
    make up
    ```
    This command will download the necessary Docker images (if not already present) and start the Matomo and MariaDB containers in detached mode.

2.  **Access Matomo:**
    Once the containers are running (you can check with `make status`), open your web browser and navigate to:
    `http://localhost:8081` (or the port you configured in `.env`)

3.  **Matomo Initial Setup:**
    You will be greeted by the Matomo installation wizard. Follow the on-screen instructions.
    * When prompted for **Database Setup**, use the following details:
        * **Database Server:** `db` (this is the service name defined in `docker-compose.yml`)
        * **Login:** `matomo_user` (as configured in `.env`)
        * **Password:** The password you set in `.env` for `MATOMO_DATABASE_PASSWORD` and `MYSQL_PASSWORD`.
        * **Database Name:** `matomo` (as configured in `.env`)
        * **Table Prefix:** `matomo_` (or your preference)
        * **Adapter:** `PDO\MYSQL`
    * Complete the rest of the installation steps (Super User creation, etc.).
  
   OR 

   * Import a copy of your stage database for testing (see 'Connect to Database from Host')     

4.  **Developing Matomo (Writable Filesystem):**
    * The `./matomo_data` directory on your host machine is directly mapped to `/var/www/html` inside the Matomo container.
    * You can now open the `./matomo_data` directory in your favorite code editor or IDE on your host system.
    * Any changes you make to files (e.g., in the `plugins` or `themes` directory within `./matomo_data`) will be immediately reflected in the running Matomo instance. You might need to clear Matomo's cache or refresh your browser to see some changes.

5.  **Connecting to the Database from Host:**
    You can connect to the MariaDB database using any compatible SQL client (e.g., DBeaver, MySQL Workbench, TablePlus, command line `mysql` client).
    * **Host:** `127.0.0.1` or `localhost`
    * **Port:** The port configured in `.env` as `DB_PORT` (default: `3307`)
    * **Username:** `matomo_user` (for accessing the `matomo` database) or `root` (for full admin access to the DB server).
    * **Password:** The password you set in `.env` for `MYSQL_PASSWORD` (for `matomo_user`) or `MYSQL_ROOT_PASSWORD` (for `root`).
    * **Database (optional, for `matomo_user`):** `matomo`

6.  **Viewing Logs:**
    To view the logs from the running services:
    ```bash
    make logs
    ```
    To view logs for a specific service:
    ```bash
    make logs-matomo
    make logs-db
    ```

7.  **Stopping the Environment:**
    To stop the Matomo and MariaDB containers:
    ```bash
    make down
    ```
    Your data in `./matomo_data` and `./db_data` will remain intact.

8.  **Removing the Environment and Data (Use with Caution!):**
    If you want to stop the containers AND remove all associated volumes (including your Matomo files in `./matomo_data` if it were a Docker named volume, and your database data in `./db_data` if it were a Docker named volume), use:
    ```bash
    docker-compose down -v
    ```
    **Note:** Since we are using bind mounts (`./matomo_data` and `./db_data`), `docker-compose down -v` will remove the anonymous volumes but not the data in these host-bound directories. To delete that data, you need to manually delete the `./matomo_data` and `./db_data` directories from your host.

## Customization

* **Ports:** To change the host ports, simply edit the `.env` file:
    ```bash
    MATOMO_PORT=8000  # Matomo now accessible on http://localhost:8000
    DB_PORT=3308      # MariaDB now accessible on port 3308
    ```
    No need to modify `docker-compose.yml`!

* **Passwords:** Update passwords in the `.env` file:
    ```bash
    MYSQL_ROOT_PASSWORD=your_secure_password
    MYSQL_PASSWORD=your_secure_password
    MATOMO_DATABASE_PASSWORD=your_secure_password  # Must match MYSQL_PASSWORD
    ```

* **Container Names:** Customize container names in `.env`:
    ```bash
    MATOMO_CONTAINER_NAME=my-matomo
    DB_CONTAINER_NAME=my-matomo-db
    ```

* **Matomo Version:** To use a specific Matomo version, change the image tag in `docker-compose.yml`:
    ```yaml
    services:
      matomo:
        image: matomo:5.0 # Or any other available tag
    ```
    Find available tags on [Docker Hub for Matomo](https://hub.docker.com/_/matomo).

* **PHP Configuration:** The official Matomo Docker image handles PHP configuration. For advanced custom PHP settings, you might need to create a custom Dockerfile that `FROM matomo:latest` and adds your own `.ini` files. Consult the [Matomo Docker image documentation](https://github.com/matomo-org/docker) for more details.

## Troubleshooting

* **Permission Denied on `./matomo_data`:**
    If Matomo or your host user has trouble writing to the `./matomo_data` directory, it's likely a file permission issue on your host system.
    * Ensure your host user has read/write/execute permissions on `./matomo_data`.
    * The user inside the Matomo container (often `www-data` with UID/GID `33` or `82`) needs to be able to write to the mounted volume. Sometimes, making the directory world-writable for local development can be a quick (but less secure) fix: `chmod -R 777 ./matomo_data`.
    * A better approach on Linux is often to ensure your host user's UID matches the `www-data` UID inside the container or to set the ownership of the host directory appropriately, e.g., `sudo chown -R 33:33 ./matomo_data` (if `www-data` is UID/GID 33). Check the Matomo Docker image documentation for specifics on the user.

* **Port Conflicts:**
    If you get an error about a port already being in use when running `docker-compose up`, it means another application on your host is using the configured port. You can either stop the other application or change the port in your `.env` file:
    * Change `MATOMO_PORT` if the web port is in use (default: 8081)
    * Change `DB_PORT` if the database port is in use (default: 3307)
    
    After changing the `.env` file, restart the containers:
    ```bash
    docker-compose down
    docker-compose up -d
    ```

* **Multiple Matomo Instances:**
    To run multiple independent Matomo development environments:
    1. Clone the repository to different directories
    2. In each directory, modify the `.env` file with unique:
        * Port numbers (`MATOMO_PORT`, `DB_PORT`)
        * Container names (`MATOMO_CONTAINER_NAME`, `DB_CONTAINER_NAME`)
        * Network name (`NETWORK_NAME`)
    3. Start each instance with `docker-compose up -d` in its respective directory

## Changelog

All notable changes to this project will be documented in this section.

### [1.1.1] - 2024-08-31

#### Fixed
- Post-commit clarity: renamed `.env-example` to `.env.example`, fixed typos
- Removed unnecessary named volume definitions from docker-compose.yml that conflicted with bind mounts
- Updated directory creation instructions to reflect automatic creation

#### Changed
- Simplified data directory setup - directories are now created automatically by Docker

### [1.1.0] - 2024-08-31

#### Added
- Environment configuration via `.env` file for easy customization
- `.env.example` template file with detailed explanation of all configurable values
- Support for running multiple Matomo instances in parallel
- Configurable container names via environment variables
- Configurable network name to avoid Docker network conflicts
- Documentation for avoiding port conflicts

#### Changed
- Default Matomo port from 8080 to 8081 to avoid common conflicts
- Default MariaDB port from 3306 to 3307 to avoid common conflicts
- All hardcoded configuration values moved to environment variables

#### Fixed
- Volume naming conflicts when running multiple instances
- Port binding conflicts with existing services

### [1.0.0] - 2024-06-01

#### Initial Release
- Docker Compose setup for Matomo development environment
- Latest Matomo and MariaDB images
- Bind-mounted volumes for live code editing
- Exposed database port for direct access
- Persistent data storage
- Basic documentation

---

Happy hacking!