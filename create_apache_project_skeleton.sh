```bash
#!/usr/bin/env bash
# =============================================================
#  apache-project-skeleton
# =============================================================
#  File: create_apache_project_skeleton.sh
#
#  Description:
#  Interactive Bash utility for scaffolding secure Apache2-based
#  web projects using PHP, MariaDB, and Bootstrap.
#
#  The script:
#   - Prompts for domain name, base directory, and project type
#   - Creates a production-ready directory structure
#   - Uses Apache best practices (public web root via DocumentRoot)
#   - Detects PHP runtime (prefers php-fpm; supports mod_php)
#   - Offers to install php-fpm if missing (Ubuntu/Debian)
#   - Generates starter PHP templates and assets
#   - Creates an Apache VirtualHost template (not auto-enabled)
#   - Records OS, Apache, PHP, and database versions for auditing
#
#  Supported Project Types:
#   1) small-app   – Simple PHP app with includes and storage
#   2) saas-api    – MVC-style layout for APIs and SaaS projects
#   3) large-app   – Laravel-like placeholder structure
#   4) marketing   – Public-only static site
#
#  Requirements:
#   - Ubuntu / Debian-based Linux system
#   - bash, apache2, apt
#   - Internet access (optional, for Bootstrap CDN)
#
#  Safety Notes:
#   - Apache DocumentRoot is always set to the /public directory
#   - Application logic and configs are never exposed publicly
#   - Script does NOT enable the site automatically
#   - Script may install php-fpm only with user confirmation
#
#  Usage:
#   chmod +x create_apache_project_skeleton.sh
#   ./create_apache_project_skeleton.sh
#
#  License:
#   MIT License
#
#  Author:
#   Andy Delgado
#   Apollos Development
#   https://apollos-dev.com
#
#  Created:
#   2026-01-08
#
#  Last Updated:
#   2026-01-08
# =============================================================

set -euo pipefail

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
warn() { printf "\033[33m[WARN]\033[0m %s\n" "$*"; }
info() { printf "\033[36m[INFO]\033[0m %s\n" "$*"; }
die()  { printf "\033[31m[ERR]\033[0m %s\n" "$*"; exit 1; }

prompt() {
  local var_name="$1"
  local message="$2"
  local default="${3:-}"
  local input=""
  if [[ -n "$default" ]]; then
    read -r -p "$message [$default]: " input
    input="${input:-$default}"
  else
    read -r -p "$message: " input
  fi
  printf -v "$var_name" '%s' "$input"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_php_fpm_socket() {
  local candidates=(
    "/run/php/php8.4-fpm.sock"
    "/run/php/php8.3-fpm.sock"
    "/run/php/php8.2-fpm.sock"
    "/run/php/php8.1-fpm.sock"
    "/run/php/php8.0-fpm.sock"
  )
  for s in "${candidates[@]}"; do
    [[ -S "$s" ]] && { echo "$s"; return 0; }
  done

  local found=""
  found="$(ls -1 /run/php/php*-fpm.sock 2>/dev/null | head -n 1 || true)"
  [[ -n "$found" && -S "$found" ]] && { echo "$found"; return 0; }

  return 1
}

detect_php_mode() {
  # Return values:
  #   fpm:<socket>   if php-fpm socket exists
  #   mod_php        if apache2 + libapache2-mod-php likely installed/enabled
  #   none           if neither detected
  local sock=""
  if sock="$(detect_php_fpm_socket 2>/dev/null)"; then
    echo "fpm:$sock"
    return 0
  fi

  # Heuristic checks for mod_php (works even if apache isn't installed yet)
  if [[ -d /etc/apache2/mods-enabled ]] && ls /etc/apache2/mods-enabled/php*.load >/dev/null 2>&1; then
    echo "mod_php"
    return 0
  fi

  # As a fallback, if php exists but no fpm socket, mod_php might still be used
  # but we won't assume it.
  echo "none"
  return 0
}

ensure_php_runtime() {
  # For PHP project types, prefer php-fpm. If missing, offer install.
  local mode="$1"  # fpm:<sock> | mod_php | none
  local project_type="$2"

  [[ "$project_type" == "marketing" ]] && return 0

  if [[ "$mode" == fpm:* || "$mode" == "mod_php" ]]; then
    return 0
  fi

  echo
  bold "PHP runtime not detected"
  echo "No PHP-FPM socket found and mod_php does not appear to be enabled."
  echo
  echo "Recommended fix (Ubuntu/Debian):"
  echo "  sudo apt update && sudo apt install -y php-fpm"
  echo

  if ! have_cmd apt; then
    die "apt not found. Install php-fpm using your distro's package manager, then rerun this script."
  fi

  prompt DO_INSTALL "Want me to install php-fpm now? (yes/no)" "no"
  [[ "$DO_INSTALL" != "yes" ]] && die "Ok. Install php-fpm, then rerun: ./$0"

  local APT_PREFIX=""
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    have_cmd sudo || die "sudo not found. Run: sudo apt update && sudo apt install -y php-fpm"
    APT_PREFIX="sudo"
  fi

  info "Installing php-fpm..."
  $APT_PREFIX apt update
  $APT_PREFIX apt install -y php-fpm

  # After install, we should now have a socket
  local new_mode=""
  new_mode="$(detect_php_mode)"
  if [[ "$new_mode" != fpm:* ]]; then
    warn "php-fpm installed but no socket detected yet. You may need to start/restart php-fpm."
    echo "Try:"
    echo "  sudo systemctl restart php8.3-fpm  (or your version)"
  fi

  info "Relaunching script..."
  exec "$0" "$@"
}

# ---- Collect inputs ----
bold "Apache2 Project Skeleton Generator"
echo

prompt DOMAIN "Enter server domain (example.com)"
[[ -z "$DOMAIN" ]] && die "Domain cannot be empty."

prompt BASE_DIR "Base directory" "/var/www"

echo
bold "Select project type:"
cat <<'MENU'
  1) small-app     (public/ + includes/ + app/ + config/ + storage/ + database/)
  2) saas-api      (MVC-ish: public/ + app/{Controllers,Models,Views} + config/ + storage/ + database/)
  3) large-app     (Laravel-like layout placeholder)
  4) marketing     (public-only static site)
MENU
echo

prompt TYPE_CHOICE "Enter choice (1-4)" "1"

case "$TYPE_CHOICE" in
  1) PROJECT_TYPE="small-app" ;;
  2) PROJECT_TYPE="saas-api" ;;
  3) PROJECT_TYPE="large-app" ;;
  4) PROJECT_TYPE="marketing" ;;
  *) die "Invalid choice. Must be 1-4." ;;
esac

PROJECT_ROOT="${BASE_DIR%/}/$DOMAIN"
CONFIG_DIR="$PROJECT_ROOT/config"
APACHE_TEMPLATE="$CONFIG_DIR/$DOMAIN.conf"
VERSIONS_FILE="$CONFIG_DIR/versions.txt"

PHP_MODE="$(detect_php_mode)"
ensure_php_runtime "$PHP_MODE" "$PROJECT_TYPE" "$@"

# Refresh mode after possible install
PHP_MODE="$(detect_php_mode)"

PHP_FPM_SOCK=""
if [[ "$PHP_MODE" == fpm:* ]]; then
  PHP_FPM_SOCK="${PHP_MODE#fpm:}"
fi

echo
info "Domain:        $DOMAIN"
info "Base dir:      $BASE_DIR"
info "Project root:  $PROJECT_ROOT"
info "Project type:  $PROJECT_TYPE"
info "PHP mode:      $PHP_MODE"
[[ -n "$PHP_FPM_SOCK" ]] && info "PHP-FPM sock:  $PHP_FPM_SOCK"
echo

if [[ -d "$PROJECT_ROOT" ]]; then
  warn "Directory already exists: $PROJECT_ROOT"
  prompt CONFIRM "Type 'yes' to continue (may overwrite some files)" "no"
  [[ "$CONFIRM" != "yes" ]] && die "Aborted."
fi

# ---- Build filesystem ----
mkdir -p "$PROJECT_ROOT" "$CONFIG_DIR"
mkdir -p "$PROJECT_ROOT/public"
mkdir -p "$PROJECT_ROOT/database"
mkdir -p "$PROJECT_ROOT/storage/logs"

case "$PROJECT_TYPE" in
  small-app)
    mkdir -p "$PROJECT_ROOT/includes" "$PROJECT_ROOT/app"
    mkdir -p "$PROJECT_ROOT/public/assets/css" "$PROJECT_ROOT/public/assets/js"
    mkdir -p "$PROJECT_ROOT/public/uploads"
    ;;

  saas-api)
    mkdir -p "$PROJECT_ROOT/includes"
    mkdir -p "$PROJECT_ROOT/app/Controllers" "$PROJECT_ROOT/app/Models"
    mkdir -p "$PROJECT_ROOT/app/Views/layouts" "$PROJECT_ROOT/app/Views/pages" "$PROJECT_ROOT/app/Views/partials"
    mkdir -p "$PROJECT_ROOT/public/assets/css" "$PROJECT_ROOT/public/assets/js"
    mkdir -p "$PROJECT_ROOT/public/uploads"
    ;;

  large-app)
    mkdir -p "$PROJECT_ROOT/app" "$PROJECT_ROOT/bootstrap" "$PROJECT_ROOT/config" "$PROJECT_ROOT/routes"
    mkdir -p "$PROJECT_ROOT/resources/views" "$PROJECT_ROOT/storage"
    mkdir -p "$PROJECT_ROOT/public/assets/css" "$PROJECT_ROOT/public/assets/js"
    touch "$PROJECT_ROOT/artisan"
    ;;

  marketing)
    mkdir -p "$PROJECT_ROOT/public/assets/css" "$PROJECT_ROOT/public/assets/js" "$PROJECT_ROOT/public/assets/images"
    ;;
esac

# ---- Create core files ----
cat > "$PROJECT_ROOT/public/assets/css/style.css" <<'CSS'
/* Basic project styles */
:root { --container-max: 1100px; }
.container-narrow { max-width: var(--container-max); margin: 0 auto; }
CSS

cat > "$PROJECT_ROOT/public/assets/js/app.js" <<'JS'
// Basic project JS
console.log("App loaded");
JS

if [[ "$PROJECT_TYPE" != "marketing" ]]; then
  mkdir -p "$PROJECT_ROOT/includes"

  cat > "$PROJECT_ROOT/includes/header.php" <<'PHP'
<?php
// includes/header.php
$pageTitle = $pageTitle ?? 'My Website';
$metaDescription = $metaDescription ?? '';
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <?php if (!empty($metaDescription)): ?>
  <meta name="description" content="<?= htmlspecialchars($metaDescription, ENT_QUOTES, 'UTF-8') ?>">
  <?php endif; ?>
  <title><?= htmlspecialchars($pageTitle, ENT_QUOTES, 'UTF-8') ?></title>

  <!-- Bootstrap (CDN) -->
  <link rel="preconnect" href="https://cdn.jsdelivr.net">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

  <!-- Site CSS -->
  <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body class="bg-light">
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container">
    <a class="navbar-brand" href="/">Home</a>
  </div>
</nav>
<main class="container py-4">
PHP

  cat > "$PROJECT_ROOT/includes/footer.php" <<'PHP'
<?php
// includes/footer.php
?>
</main>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="/assets/js/app.js"></script>
</body>
</html>
PHP
fi

if [[ "$PROJECT_TYPE" == "marketing" ]]; then
  cat > "$PROJECT_ROOT/public/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Marketing Site</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body class="bg-light">
  <div class="container py-5">
    <h1 class="mb-3">It works ✅</h1>
    <p class="lead">Your marketing site is live.</p>
  </div>
</body>
</html>
HTML
else
  cat > "$PROJECT_ROOT/public/index.php" <<'PHP'
<?php
$pageTitle = "It works ✅";
$metaDescription = "Project skeleton is ready.";
require __DIR__ . '/../includes/header.php';
?>
<h1 class="mb-3">It works ✅</h1>
<p class="lead">Your Apache2 + PHP + Bootstrap skeleton is ready.</p>
<hr>
<ul>
  <li><strong>Header:</strong> /includes/header.php</li>
  <li><strong>Footer:</strong> /includes/footer.php</li>
  <li><strong>CSS:</strong> /public/assets/css/style.css</li>
  <li><strong>JS:</strong> /public/assets/js/app.js</li>
</ul>
<?php require __DIR__ . '/../includes/footer.php'; ?>
PHP
fi

# ---- Apache VirtualHost template ----
# Stored in: BASE_DIR/DOMAIN/config/DOMAIN.conf
# Copy to: /etc/apache2/sites-available/DOMAIN.conf
# Enable with: a2ensite DOMAIN.conf && systemctl reload apache2
#
# If PHP_MODE is fpm:<sock>, we include a basic ProxyFCGI snippet (requires a2enmod proxy_fcgi setenvif)
# If PHP_MODE is mod_php, no ProxyFCGI config is added.

APACHE_PHP_BLOCK=""
if [[ "$PHP_MODE" == fpm:* ]]; then
  # Use the common Apache "FilesMatch + SetHandler" pattern for PHP-FPM via unix socket
  APACHE_PHP_BLOCK=$(cat <<EOF
    # PHP-FPM (ProxyFCGI)
    # Modules needed:
    #   sudo a2enmod proxy_fcgi setenvif
    # And optionally:
    #   sudo a2enconf php*-fpm   (if available)
    <FilesMatch \\.php\$>
        SetHandler "proxy:unix:${PHP_FPM_SOCK}|fcgi://localhost/"
    </FilesMatch>
EOF
)
else
  APACHE_PHP_BLOCK=$(cat <<'EOF'
    # PHP handler:
    # This template assumes mod_php is enabled (libapache2-mod-php).
    # If you're using PHP-FPM instead, enable proxy_fcgi and update the handler section.
EOF
)
fi

cat > "$APACHE_TEMPLATE" <<APACHECONF
# $DOMAIN Apache2 VirtualHost template
# Copy to: /etc/apache2/sites-available/$DOMAIN.conf
#
# Enable:
#   sudo a2ensite $DOMAIN.conf
#   sudo systemctl reload apache2
#
# Recommended modules:
#   sudo a2enmod rewrite headers ssl

<VirtualHost *:80>
    ServerName $DOMAIN
    #ServerAlias www.$DOMAIN

    DocumentRoot $PROJECT_ROOT/public

    ErrorLog  \${APACHE_LOG_DIR}/$DOMAIN.error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN.access.log combined

    <Directory $PROJECT_ROOT/public>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

$APACHE_PHP_BLOCK

    # Basic security headers (optional; adjust to taste)
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
</VirtualHost>
APACHECONF

# .htaccess (useful for pretty URLs if AllowOverride is on)
cat > "$PROJECT_ROOT/public/.htaccess" <<'HT'
# Basic rewrite rules (optional)
<IfModule mod_rewrite.c>
  RewriteEngine On

  # If the requested file/directory does not exist, route to index.php
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^ index.php [L]
</IfModule>
HT

# ---- versions.txt ----
OS_PRETTY="$(grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
APACHE_V="$(
  (apache2 -v 2>/dev/null || httpd -v 2>/dev/null || true) | head -n 2 | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g' | sed 's/[[:space:]]$//'
)"
PHP_V="$(php -v 2>/dev/null | head -n 1 || true)"
MARIADB_V="$(mariadb --version 2>/dev/null || mysql --version 2>/dev/null || true)"

cat > "$VERSIONS_FILE" <<TXT
Project: $DOMAIN
Created: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

OS: ${OS_PRETTY:-Unknown}
Apache: ${APACHE_V:-Unknown}
PHP: ${PHP_V:-Unknown}
MariaDB/MySQL: ${MARIADB_V:-Unknown}
PHP Mode: $PHP_MODE
TXT

touch "$PROJECT_ROOT/README.md"
touch "$PROJECT_ROOT/.env.example"

bold "Done ✅"
echo
info "Project created at: $PROJECT_ROOT"
info "Apache vhost template saved at: $APACHE_TEMPLATE"
info "versions saved at:             $VERSIONS_FILE"
echo
echo "Next steps (typical):"
echo "  1) sudo cp \"$APACHE_TEMPLATE\" \"/etc/apache2/sites-available/$DOMAIN.conf\""
echo "  2) sudo a2ensite \"$DOMAIN.conf\""
echo "  3) sudo a2enmod rewrite headers"
if [[ "$PHP_MODE" == fpm:* ]]; then
  echo "  4) sudo a2enmod proxy_fcgi setenvif"
fi
echo "  5) sudo apache2ctl configtest && sudo systemctl reload apache2"
echo "  6) (optional) sudo certbot --apache -d $DOMAIN"
echo
```
