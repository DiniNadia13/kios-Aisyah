$base = 'c:\xampp83\htdocs\KiosAisyha'
$staging = Join-Path $base 'staging_deploy'

if (Test-Path $staging) {
    Remove-Item $staging -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $staging 'laravel') -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $staging 'public_html') -Force | Out-Null

Write-Host "Copying backend folders to staging/laravel..."
$folders = @('app', 'bootstrap', 'config', 'database', 'resources', 'routes', 'storage', 'vendor')
foreach ($f in $folders) {
    $src = Join-Path $base "backend\$f"
    $dest = Join-Path $staging "laravel\$f"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dest -Recurse -Force
    }
}

$files = @('artisan', 'composer.json', 'composer.lock')
foreach ($fl in $files) {
    $src = Join-Path $base "backend\$fl"
    $dest = Join-Path $staging "laravel\$fl"
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dest -Force
    }
}

# Production .env
$envLines = @(
    'APP_NAME="Kios Aisyha"',
    'APP_ENV=production',
    'APP_KEY=base64:E7CFmAEfRyM/aUpBxCJqUyfmiJEJqLCclEeEKAGstFo=',
    'APP_DEBUG=false',
    'APP_URL=https://kiosaisyha.my.id',
    '',
    'APP_LOCALE=id',
    'APP_FALLBACK_LOCALE=id',
    '',
    'LOG_CHANNEL=stack',
    'LOG_STACK=single',
    'LOG_LEVEL=error',
    '',
    'DB_CONNECTION=mysql',
    'DB_HOST=127.0.0.1',
    'DB_PORT=3306',
    'DB_DATABASE=kiosaisy_kioss',
    'DB_USERNAME=kiosaisy_kios',
    'DB_PASSWORD=KiosAisyha*123',
    '',
    'SESSION_DRIVER=database',
    'SESSION_LIFETIME=120',
    'SESSION_ENCRYPT=false',
    '',
    'CACHE_STORE=database',
    'QUEUE_CONNECTION=database',
    '',
    'FILESYSTEM_DISK=public'
)
$envLines | Set-Content -Path (Join-Path $staging 'laravel\.env') -Encoding UTF8

Write-Host "Copying Flutter Web to staging/public_html..."
Copy-Item -Path (Join-Path $base 'app\build\web\*') -Destination (Join-Path $staging 'public_html') -Recurse -Force

# index.php for API
$apiIndex = @(
    '<?php',
    '',
    'use Illuminate\Http\Request;',
    '',
    'define(''LARAVEL_START'', microtime(true));',
    '',
    'if (file_exists($maintenance = __DIR__.''/../laravel/storage/framework/maintenance.php'')) {',
    '    require $maintenance;',
    '}',
    '',
    'require __DIR__.''/../laravel/vendor/autoload.php'';',
    '',
    '(require_once __DIR__.''/../laravel/bootstrap/app.php'')',
    '    ->handleRequest(Request::capture());'
)
$apiIndex | Set-Content -Path (Join-Path $staging 'public_html\api_index.php') -Encoding UTF8

# .htaccess
$htaccessLines = @(
    '<IfModule mod_rewrite.c>',
    '    <IfModule mod_negotiation.c>',
    '        Options -MultiViews -Indexes',
    '    </IfModule>',
    '',
    '    RewriteEngine On',
    '',
    '    # Force HTTPS',
    '    RewriteCond %{HTTPS} off',
    '    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]',
    '',
    '    # Handle Authorization Header',
    '    RewriteCond %{HTTP:Authorization} .',
    '    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]',
    '',
    '    # Handle X-XSRF-Token Header',
    '    RewriteCond %{HTTP:x-xsrf-token} .',
    '    RewriteRule .* - [E=HTTP_X_XSRF_TOKEN:%{HTTP:X-XSRF-Token}]',
    '',
    '    # Direct APK downloads & aliases (case-insensitive)',
    '    RewriteRule ^(download|download/|kiosaisyha\.apk|app\.apk)$ /KiosAisyha.apk [NC,L]',
    '',
    '    # Route API and dynamic endpoints to Laravel',
    '    RewriteCond %{REQUEST_URI} ^/api [NC,OR]',
    '    RewriteCond %{REQUEST_URI} ^/receipt [NC,OR]',
    '    RewriteCond %{REQUEST_URI} ^/storage [NC]',
    '    RewriteRule ^ api_index.php [L]',
    '',
    '    # Flutter Web Single Page App fallback',
    '    RewriteCond %{REQUEST_FILENAME} !-f',
    '    RewriteCond %{REQUEST_FILENAME} !-d',
    '    RewriteRule ^ index.html [L]',
    '</IfModule>'
)
$htaccessLines | Set-Content -Path (Join-Path $staging 'public_html\.htaccess') -Encoding UTF8

Write-Host "Staging build completed successfully!"

