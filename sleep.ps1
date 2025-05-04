Add-Type -AssemblyName System.Windows.Forms
Import-Module BurntToast

function Ask-Awake($timeoutSeconds = 120) {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $script:result = $false

    # Crear formulario
    $form = New-Object System.Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.BackColor       = [System.Drawing.Color]::Black
    $form.Size            = New-Object Drawing.Size(600,200)
    $form.StartPosition   = "CenterScreen"
    $form.Topmost         = $true
    # Fuente general
    $form.Font            = New-Object System.Drawing.Font('Bahnschrift',12,[System.Drawing.FontStyle]::Bold)

    # Dibuja un borde neón (amarillo)
    $form.Add_Paint({
        param($sender, $e)
        $pen = New-Object System.Drawing.Pen(
            [System.Drawing.Color]::FromArgb(255,255,20), 5)
        $e.Graphics.DrawRectangle($pen,0,0,
            $form.Width-1, $form.Height-1)
    })

    # Margen superior para el header
    $headerMarginTop = 30

    # Etiqueta (header) – usa Bahnschrift y color amarillo
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = "¿sigues ahí, coleguita?"
    $lbl.AutoSize  = $true
    $lbl.Font      = New-Object System.Drawing.Font('Bahnschrift',24,[System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(255,255,20)
    # Reubica tras conocer AutoSize, con margen superior configurable
    $lbl.Location  = New-Object Drawing.Point(
        (($form.ClientSize.Width - $lbl.PreferredWidth) / 2),
        $headerMarginTop
    )
    $form.Controls.Add($lbl)

    # Botón estilo neón (amarillo)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text       = "¡Sigo aquí!"
    $btn.Size       = New-Object Drawing.Size(250,45)
    $btn.FlatStyle  = 'Flat'
    $btn.BackColor  = [System.Drawing.Color]::Black
    $btn.ForeColor  = [System.Drawing.Color]::FromArgb(255,255,20)
    $btn.Font       = New-Object System.Drawing.Font('Bahnschrift',14,[System.Drawing.FontStyle]::Bold)
    $btn.FlatAppearance.BorderSize  = 2
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(255,255,20)
    $btn.Location   = New-Object Drawing.Point(
        (( $form.ClientSize.Width  - $btn.Width ) / 2),
        (( $form.ClientSize.Height - $btn.Height) / 2 + 15))
    # Efecto hover
    $btn.Add_MouseEnter({
        $btn.BackColor = [System.Drawing.Color]::FromArgb(255,255,20)
        $btn.ForeColor = [System.Drawing.Color]::Black
    })
    $btn.Add_MouseLeave({
        $btn.BackColor = [System.Drawing.Color]::Black
        $btn.ForeColor = [System.Drawing.Color]::FromArgb(255,255,20)
    })
    $btn.Add_Click({
        $timer.Stop()
        $script:result = $true
        $form.Close()
    })
    $form.Controls.Add($btn)

    # Temporizador para cierre tras timeout
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = $timeoutSeconds * 1000
    $timer.Add_Tick({
        $timer.Stop()
        $script:result = $false
        $form.Close()
    })
    $timer.Start()

    # Mostrar formulario
    [void]$form.ShowDialog()
    return $script:result
}

# Ejecutar pregunta y esperar respuesta
$response = Ask-Awake -timeoutSeconds 120

if (-not $response) {
    # 1) Minimizar ventanas
    New-BurntToastNotification -Text "Minimizando ventanas..."
    (New-Object -ComObject Shell.Application).MinimizeAll()
    Start-Sleep -Seconds 120

    # 2) Silenciar audio
    New-BurntToastNotification -Text "Silenciando audio..."
    (New-Object -ComObject WScript.Shell).SendKeys([char]173)
    Start-Sleep -Seconds 120

    # 3 & 4) Cerrar aplicaciones dos veces, excluyendo el script y explorer
    for ($i = 1; $i -le 2; $i++) {
        New-BurntToastNotification -Text "Cerrando aplicaciones..."
        Get-Process |
            Where-Object { $_.MainWindowHandle -ne 0 -and $_.Id -ne $PID -and $_.ProcessName -ne 'explorer' } |
            Stop-Process -Force
        Start-Sleep -Seconds 120
    }

    # 5) Apagar el PC
    New-BurntToastNotification -Text "Apagando el PC. Buenas noches"
    Start-Sleep -Seconds 5
    Stop-Computer -Force
}
