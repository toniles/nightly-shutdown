if ([Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Warning 'Run PowerShell with -STA'
    return
}
$ErrorActionPreference = 'Stop'

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
$logPath   = Join-Path $scriptDir 'script-debug.log'
if (Test-Path $logPath) {
    if ((Get-Item $logPath).Length -gt 2MB) { Clear-Content $logPath }
} else {
    New-Item -Path $logPath -ItemType File -Force | Out-Null
}

function Write-Log($message) {
    "$((Get-Date).ToString('o')) $message" | Add-Content $logPath
}

try {
    try { Import-Module BurntToast -ErrorAction Stop } catch {}

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $script:cancelled = $false

    function Get-PreferredFont {
        param(
            [int]$size,
            [System.Drawing.FontStyle]$style
        )
        $names    = [System.Drawing.FontFamily]::Families | ForEach-Object Name
        $fontName = if ($names -contains 'Bahnschrift') { 'Bahnschrift' } else { 'Segoe UI' }
        return New-Object System.Drawing.Font($fontName, $size, $style)
    }

    function Show-CancelForm {
        $thread = [System.Threading.Thread]{
            [System.Windows.Forms.Application]::EnableVisualStyles()
            $form = New-Object System.Windows.Forms.Form
            $form.FormBorderStyle = 'FixedDialog'
            $form.Size            = New-Object Drawing.Size(300,100)
            $area                 = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
            $form.Location        = New-Object Drawing.Point($area.Width-$form.Width-10, $area.Height-$form.Height-10)

            $button = New-Object System.Windows.Forms.Button
            $button.Text      = 'Cancel All'
            $button.Dock      = 'Fill'
            $button.Font      = Get-PreferredFont -size 12 -style Bold
            $button.BackColor = [System.Drawing.Color]::FromArgb(200,50,50)
            $button.ForeColor = [System.Drawing.Color]::White
            $button.Add_Click({ $script:cancelled = $true; $form.Close() })
            $form.Controls.Add($button)

            [System.Windows.Forms.Application]::Run($form)
            $form.Dispose()
        }
        $thread.SetApartmentState('STA')
        $thread.IsBackground = $true
        $thread.Start()
    }

    function Sleep-WithCancel {
        param([int]$seconds)
        for ($i = 0; $i -lt $seconds; $i++) {
            Start-Sleep -Seconds 1
            [System.Windows.Forms.Application]::DoEvents()
            if ($script:cancelled) { break }
        }
    }

    function Ask-Awake {
        param([int]$timeout)
        [System.Windows.Forms.Application]::EnableVisualStyles()
        $response = $false

        $form = New-Object System.Windows.Forms.Form
        $form.FormBorderStyle = 'None'
        $form.BackColor       = [System.Drawing.Color]::Black
        $form.Size            = New-Object Drawing.Size(600,200)
        $form.StartPosition   = 'CenterScreen'
        $form.Topmost         = $true
        $form.Font            = Get-PreferredFont -size 12 -style Bold

        $form.Add_Paint({
            param($s,$e)
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255,255,20),5)
            $e.Graphics.DrawRectangle($pen,0,0,$form.Width-1,$form.Height-1)
        })

        $label = New-Object System.Windows.Forms.Label
        $label.Text      = 'Are you still there?'
        $label.AutoSize  = $true
        $label.Font      = Get-PreferredFont -size 24 -style Bold
        $label.ForeColor = [System.Drawing.Color]::FromArgb(255,255,20)
        $label.Location  = New-Object Drawing.Point((($form.ClientSize.Width - $label.PreferredSize.Width)/2),30)
        $form.Controls.Add($label)

        $button = New-Object System.Windows.Forms.Button
        $button.Text       = 'I am here'
        $button.Size       = New-Object Drawing.Size(250,45)
        $button.FlatStyle  = 'Flat'
        $button.BackColor  = [System.Drawing.Color]::Black
        $button.ForeColor  = [System.Drawing.Color]::FromArgb(255,255,20)
        $button.Font       = Get-PreferredFont -size 14 -style Bold
        $button.FlatAppearance.BorderSize  = 2
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,255,20)
        $button.Location   = New-Object Drawing.Point((($form.ClientSize.Width - $button.PreferredSize.Width)/2),(($form.ClientSize.Height - $button.PreferredSize.Height)/2+15))
        $form.Controls.Add($button)

        # -------- Suscripción corregida al evento Tick --------
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = $timeout * 1000
        $timer.add_Tick({
            $timer.Stop()
            $form.Close()
        })
        $timer.Start()
        # -------------------------------------------------------

        $button.Add_Click({ $timer.Stop(); $response = $true; $form.Close() })

        [void]$form.ShowDialog()
        $timer.Dispose()
        $form.Dispose()

        return $response
    }

    if (-not (Ask-Awake -timeout 120)) {
        Show-CancelForm

        if (-not $script:cancelled) {
            try {
                (New-Object -ComObject Shell.Application).MinimizeAll()
            } catch { Write-Log "Minimize error: $_" }
            Sleep-WithCancel -seconds 120
        }

        if (-not $script:cancelled) {
            try {
                (New-Object -ComObject WScript.Shell).SendKeys([char]173)
            } catch { Write-Log "Mute error: $_" }
            Sleep-WithCancel -seconds 120
        }

        for ($round = 1; $round -le 2; $round++) {
            if ($script:cancelled) { break }
            Get-Process |
                Where-Object { $_.MainWindowHandle -ne 0 -and $_.Id -ne $PID -and $_.ProcessName -ne 'explorer' } |
                ForEach-Object {
                    if ($script:cancelled) { return }
                    try {
                        Stop-Process -Id $_.Id -Force -ErrorAction Stop
                    } catch {
                        Write-Log "Close error: $($_.ProcessName): $_"
                    }
                    Sleep-WithCancel -seconds 1
                }
            Sleep-WithCancel -seconds 120
        }

        if (-not $script:cancelled) {
            try {
                Stop-Computer -Force
            } catch { Write-Log "Shutdown error: $_" }
        }

        if ($script:cancelled) {
            Write-Log 'Operation cancelled by user'
        }
    }
}
catch {
    Write-Log "Fatal error: $($_.Exception.Message)"
}
