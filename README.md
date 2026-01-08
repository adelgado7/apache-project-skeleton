# apache-project-skeleton

An interactive Bash script that scaffolds secure **Apache2-based** web projects using **PHP**, **MariaDB**, and **Bootstrap** on Ubuntu/Debian systems.

This tool helps you go from a fresh server to a clean, production-ready project structure quickly and consistently—without forcing a full framework.

---

## Features

- Interactive prompts for:
  - Domain name
  - Base directory (default: `/var/www`)
  - Project type
- Supports multiple project layouts:
  - Small PHP apps
  - SaaS / API-style MVC projects
  - Large (Laravel-like) placeholders
  - Marketing / static sites
- PHP runtime detection:
  - Prefers **PHP-FPM**
  - Detects **mod_php** when available
  - Offers to install `php-fpm` if missing
- Automatically creates:
  - Secure directory structure
  - `/public` DocumentRoot (Apache best practice)
  - Bootstrap-ready `header.php` and `footer.php`
  - Starter `index.php` or `index.html`
  - Apache VirtualHost template (not auto-enabled)
  - `.htaccess` with basic rewrite rules
  - Version tracking file (`versions.txt`)

---

## Supported Project Types

| Type | Description |
|------|-------------|
| small-app | Simple PHP app with includes, app logic, and storage |
| saas-api | MVC-style structure for APIs and SaaS projects |
| large-app | Laravel-like placeholder layout (no framework installed) |
| marketing | Public-only static site |

---

## Requirements

- Ubuntu / Debian-based Linux server
- bash
- apache2
- apt package manager
- Internet access (optional, for Bootstrap CDN)

> This script is intended to be run **on the server**, not directly on Windows.

---

## Installation

### Option 1: Clone from GitHub (recommended)

```bash
git clone https://github.com/adelgado7/apache-project-skeleton.git
cd apache-project-skeleton
chmod +x create_apache_project_skeleton.sh
./create_apache_project_skeleton.sh
```

### Option 2: Download via wget

```bash
wget -O create_apache_project_skeleton.sh \
https://raw.githubusercontent.com/adelgado7/apache-project-skeleton/main/create_apache_project_skeleton.sh

chmod +x create_apache_project_skeleton.sh
./create_apache_project_skeleton.sh
```

This method is useful for:

- Quick installs on fresh servers
- Minimal environments without Git
- Automated provisioning or bootstrap scripts

> Tip: Always review downloaded scripts before executing them on a production system.

---

## What the Script Creates

```
/var/www/example.com/
├── public/                 # Apache DocumentRoot
│   ├── index.php | index.html
│   ├── .htaccess
│   └── assets/
│       ├── css/
│       └── js/
├── includes/               # header.php / footer.php (PHP projects)
├── app/                    # application logic (varies by type)
├── database/               # migrations / SQL
├── storage/                # logs, uploads, cache
├── config/
│   ├── example.com.conf    # Apache VirtualHost template
│   └── versions.txt        # OS, Apache, PHP, MariaDB versions
├── README.md
└── .env.example
```

Apache is always configured with:

```
DocumentRoot /var/www/example.com/public
```

---

## Apache VirtualHost Configuration

The script generates a VirtualHost template at:

```
/var/www/example.com/config/example.com.conf
```

To enable it:

```bash
sudo cp /var/www/example.com/config/example.com.conf \
  /etc/apache2/sites-available/example.com.conf

sudo a2ensite example.com.conf
sudo systemctl reload apache2
```

### Required / Recommended Modules

```bash
sudo a2enmod rewrite headers
```

If using **PHP-FPM**:

```bash
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php*-fpm
```

---

## Version Tracking

Each project includes a version audit file:

```
config/versions.txt
```

Example contents:

```
Project: example.com
Created: 2026-01-08T19:15:42Z

OS: Ubuntu 24.04 LTS
Apache: Apache/2.4.58 (Ubuntu)
PHP: PHP 8.3.6
MariaDB/MySQL: MariaDB 11.4
PHP Mode: fpm:/run/php/php8.3-fpm.sock
```

---

## Security Notes

- Apache `DocumentRoot` is always set to `/public`
- Application logic and configs live outside the web root
- `.htaccess` included for clean URLs
- VirtualHost is not enabled automatically
- SSL and rewrite rules require explicit user action

---

## Roadmap / Ideas

Potential future enhancements:

- Non-interactive CLI flags
- `.env` generation from prompts
- Database and DB user creation
- Automatic permissions and ownership
- Git initialization
- Optional Laravel installation
- CSP and HSTS presets

---

## Contributing

Contributions are welcome, especially:

- Additional project templates
- Apache hardening improvements
- OS compatibility testing
- Documentation improvements

Fork the repository, create a branch, and open a pull request.

---

## License

MIT License  
Use freely, modify safely, and build great things.

---

## Author

Andy Delgado  
Apollos Development  
https://apollos-dev.com
