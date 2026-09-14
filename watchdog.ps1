# Watchdog del stack OpenWA.
# Re-levanta lo que se haya caido con WMI (procesos desacoplados que persisten).
# Usa una marca de tiempo por servicio para no duplicar mientras arranca.

$log = 'C:\openwa\watchdog.log'

function Write-Log($m) { "$(Get-Date -Format s) $m" | Out-File -Append -Encoding utf8 $log }
function Listening([int]$port) { ((Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue) | Measure-Object).Count -gt 0 }
function ProcRunning([string]$pattern) {
    ((Get-CimInstance Win32_Process -Filter "Name='php.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like "*$pattern*" }) | Measure-Object).Count -gt 0
}
function RecentlyLaunched([string]$name) {
    $f = "C:\openwa\.launch-$name"
    if (Test-Path $f) { return ((Get-Date) - (Get-Item $f).LastWriteTime).TotalSeconds -lt 150 }
    return $false
}
function MarkLaunched([string]$name) { Set-Content -Path "C:\openwa\.launch-$name" -Value (Get-Date) }
function KillPattern([string]$pattern) {
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @('php.exe', 'node.exe') -and $_.CommandLine -like "*$pattern*" } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}
function Spawn($command) { wmic process call create "cmd.exe /c $command" | Out-Null }

try {
    if (-not (Listening 8020) -and -not (RecentlyLaunched 'panel')) {
        MarkLaunched 'panel'
        KillPattern 'artisan serve'
        Spawn 'cd /d C:\xampp_82_12\htdocs\openwa_basico && php artisan serve --port=8020 >> storage\logs\serve.out.log 2>&1'
        Write-Log 'panel 8020 -> relanzado'
    }

    if (-not (Listening 2785) -and -not (RecentlyLaunched 'gateway')) {
        MarkLaunched 'gateway'
        KillPattern 'nest'
        Spawn 'cd /d C:\openwa && npm run start:dev >> openwa.out.log 2>&1'
        Write-Log 'gateway 2785 -> relanzado'
    }

    if (-not (ProcRunning 'queue:work') -and -not (RecentlyLaunched 'worker')) {
        MarkLaunched 'worker'
        KillPattern 'queue:work'
        Spawn 'cd /d C:\xampp_82_12\htdocs\openwa_basico && php artisan queue:work --tries=3 --timeout=120 --sleep=1 >> storage\logs\queue.out.log 2>&1'
        Write-Log 'worker de cola -> relanzado'
    }
} catch {
    Write-Log "error: $($_.Exception.Message)"
}
