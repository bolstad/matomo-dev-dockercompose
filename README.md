# Local Matomo Development Environment with Docker Compose

This repository provides a docker-compose.yml configuration to set up a local development environment for Matomo analytics quickly.

It features the latest Matomo and MariaDB images, a bind-mounted volume for live code editing of Matomo files directly from your host machine, and an exposed MariaDB port for direct database access.

Suitable for:

* Developing custom Matomo plugins or themes.
* Testing Matomo configurations locally.


# Features

* Bleeding edge:  Uses latest official Matomo and MariaDB images as default (buy you can easily pin a specifc version, see 'Customization'. 
* Writable matomo files: The Matomo web root (/var/www/html) is mounted to a local ./matomo_data directory, allowing you to edit files directly on your host with your preferred IDE or editor.
* Accass DB from host: MariaDB port 3306 is exposed to localhost:3306 for easy connection with your standard database management tools.
* Persistent data: Both Matomo files (if using the bind mount for /var/www/html) and database data (in ./db_data) are persisted on your host machine.

## Setup Instructions

1.  **Clone the Repository (or Create the File):**
    * If this were a Git repository:
        ```bash
        git clone <repository-url>
        cd <repository-name>
        ```
    * Alternatively, create a new directory for your project and save the `docker-compose.yml` content (provided in the previous step) into a file named `docker-compose.yml` within that directory.

2.  **Create Local Data Directories:**
    In the same directory as your `docker-compose.yml` file, create the directories that will be used for persistent storage:
    ```bash
    mkdir matomo_data
    mkdir db_data
    ```
    * `./matomo_data`: Will store Matomo's application files.
    * `./db_data`: Will store MariaDB's data.

    *Note on Permissions:* If you are on Linux, Docker might create these directories as `root` if they don't exist when you first run `docker-compose up`. You may need to adjust their ownership and permissions afterwards to allow your host user to write to `./matomo_data` (e.g., `sudo chown -R $(whoami):$(whoami) matomo_data db_data`).

3.  **Configure Passwords:**
    Open the `docker-compose.yml` file and **change the default passwords**.
    * Under the `matomo` service `environment`:
        * `MATOMO_DATABASE_PASSWORD`: Set a strong password.
    * Under the `db` service `environment`:
        * `MYSQL_ROOT_PASSWORD`: Set a very strong password for the database root user.
        * `MYSQL_PASSWORD`: **Ensure this matches the `MATOMO_DATABASE_PASSWORD` you set above.**

    **Example snippets from `docker-compose.yml` to modify:**
    ```yaml
    # ...
    services:
      matomo:
        # ...
        environment:
          # ...
          MATOMO_DATABASE_PASSWORD: your_matomo_db_password_here # <-- CHANGE THIS
        # ...
      db:
        # ...
        environment:
          MYSQL_ROOT_PASSWORD: your_strong_root_password_here # <-- CHANGE THIS
          # ...
          MYSQL_PASSWORD: your_matomo_db_password_here # <-- CHANGE THIS (must match above)
        # ...
    ```

## Usage

1.  **Start the Environment:**
    Navigate to the directory containing your `docker-compose.yml` file in a terminal and run:
    ```bash
    docker-compose up -d
    ```
    This command will download the necessary Docker images (if not already present) and start the Matomo and MariaDB containers in detached mode (`-d`).

2.  **Access Matomo:**
    Once the containers are running (you can check with `docker-compose ps`), open your web browser and navigate to:
    `http://localhost:8080`

3.  **Matomo Initial Setup:**
    You will be greeted by the Matomo installation wizard. Follow the on-screen instructions.
    * When prompted for **Database Setup**, use the following details:
        * **Database Server:** `db` (this is the service name defined in `docker-compose.yml`)
        * **Login:** `matomo_user` (as defined in `docker-compose.yml`)
        * **Password:** The password you set for `MATOMO_DATABASE_PASSWORD` and `MYSQL_PASSWORD`.
        * **Database Name:** `matomo` (as defined in `docker-compose.yml`)
        * **Table Prefix:** `matomo_` (or your preference)
        * **Adapter:** `PDO\MYSQL`
    * Complete the rest of the installation steps (Super User creation, etc.).
  
   OR 

   * Import a copy of your stage data base for bliss (see 'Connect to Datbase from Host')     

4.  **Developing Matomo (Writable Filesystem):**
    * The `./matomo_data` directory on your host machine is directly mapped to `/var/www/html` inside the Matomo container.
    * You can now open the `./matomo_data` directory in your favorite code editor or IDE on your host system.
    * Any changes you make to files (e.g., in the `plugins` or `themes` directory within `./matomo_data`) will be immediately reflected in the running Matomo instance. You might need to clear Matomo's cache or refresh your browser to see some changes.

5.  **Connecting to the Database from Host:**
    You can connect to the MariaDB database using any compatible SQL client (e.g., DBeaver, MySQL Workbench, TablePlus, command line `mysql` client).
    * **Host:** `127.0.0.1` or `localhost`
    * **Port:** `3306` (as mapped in `docker-compose.yml`)
    * **Username:** `matomo_user` (for accessing the `matomo` database) or `root` (for full admin access to the DB server).
    * **Password:** The password you set for `MYSQL_PASSWORD` (for `matomo_user`) or `MYSQL_ROOT_PASSWORD` (for `root`).
    * **Database (optional, for `matomo_user`):** `matomo`

6.  **Viewing Logs:**
    To view the logs from the running services:
    ```bash
    docker-compose logs -f
    ```
    To view logs for a specific service (e.g., matomo):
    ```bash
    docker-compose logs -f matomo
    docker-compose logs -f db
    ```

7.  **Stopping the Environment:**
    To stop the Matomo and MariaDB containers:
    ```bash
    docker-compose down
    ```
    Your data in `./matomo_data` and `./db_data` will remain intact.

8.  **Removing the Environment and Data (Use with Caution!):**
    If you want to stop the containers AND remove all associated volumes (including your Matomo files in `./matomo_data` if it were a Docker named volume, and your database data in `./db_data` if it were a Docker named volume), use:
    ```bash
    docker-compose down -v
    ```
    **Note:** Since we are using bind mounts (`./matomo_data` and `./db_data`), `docker-compose down -v` will remove the anonymous volumes but not the data in these host-bound directories. To delete that data, you need to manually delete the `./matomo_data` and `./db_data` directories from your host.

## Customization

* **Ports:** To change the host port on which Matomo is accessible (e.g., from `8080` to `8000`), modify the `ports` section for the `matomo` service in `docker-compose.yml`:
    ```yaml
    services:
      matomo:
        ports:
          - "8000:80" # Matomo now accessible on http://localhost:8000
    ```
    Similarly, you can change the host port for MariaDB.
* **Matomo Version:** Change the image tag for the `matomo` service (e.g., `matomo:5.0` for a specific version):
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
    If you get an error about a port already being in use when running `docker-compose up`, it means another application on your host is using port `8080` or `3306`. You can either stop the other application or change the host-side port mapping in your `docker-compose.yml` as described in the 'Customization' section.

---

Happy hacking!
