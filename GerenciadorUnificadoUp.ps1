# ============================================================================
# 1. VERIFICACAO DE PRIVILEGIOS E AUTO-ELEVACAO (METODO FINAL)
# ============================================================================
# Pega a identidade do usuário atual e verifica se ele está no grupo "Administradores"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [System.Security.Principal.WindowsPrincipal]::new($currentUser)

if (-not $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Se não for admin, tenta se re-executar com privilégios elevados
    $arguments = "& '" + $MyInvocation.MyCommand.Definition + "'"
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    # Fecha a janela atual (sem privilégios)
    exit
}

# Se o script chegou aqui, ele já está rodando como Administrador.

# ============================================================================
# 2. FUNCOES PRINCIPAIS
# ============================================================================

# Função para exibir o menu principal
function Show-MainMenu {
    Clear-Host
    $Host.UI.RawUI.WindowTitle = 'Gerenciador de Certificados Unificado v5.0'
    Write-Host "
  =========================================================
        GERENCIADOR DE CERTIFICADOS UNIFICADO
  =========================================================

  Escolha uma acao:

     1 - INSTALAR certificados da pasta
     2 - DESINSTALAR certificados da pasta
     3 - ANALISAR certificados
     
     4 - INSTALAR de uma URL direta
     5 - BUSCAR E INSTALAR de uma pagina web
     6 - BUSCAR E DESINSTALAR de uma pagina web

     0 - Sair da ferramenta

  ========================================================="
}

# --- BLOCO DE EXIBICAO PADRONIZADO ---
function Show-CertificateInfo {
    param(
        [Parameter(Mandatory=$true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [string]$StatusMessage,
        [string]$StatusColor = "White"
    )
    
    # Extrai e limpa as informações para mostrar apenas o Nome Comum (CN)
    $subjectCN = ($Certificate.Subject -split ', ' | Where-Object { $_.StartsWith('CN=') }) -replace 'CN=', ''
    $issuerCN = ($Certificate.Issuer -split ', ' | Where-Object { $_.StartsWith('CN=') }) -replace 'CN=', ''
    
    Write-Host "---------------------------------------------------------" -ForegroundColor Yellow
    Write-Host ("   Nome do Certificado : " + $subjectCN)
    Write-Host ("   Emitido Por         : " + $issuerCN)
    Write-Host ("   Valido a Partir de  : " + $Certificate.NotBefore)
    Write-Host ("   Valido Ate          : " + $Certificate.NotAfter)
    Write-Host ("   Numero de Serie     : " + $Certificate.SerialNumber)
    
    if ($StatusMessage) {
        Write-Host "   STATUS              : " -NoNewline
        Write-Host $StatusMessage -ForegroundColor $StatusColor
    }
    Write-Host "---------------------------------------------------------`n" -ForegroundColor Yellow
}

# --- NOVA FUNCAO CENTRAL DE SELECAO ---
function Get-UserSelection {
    param(
        [Parameter(Mandatory=$true)]
        [array]$MenuItems,
        [Parameter(Mandatory=$true)]
        [string]$ActionPrompt
    )
    
    do {
        Clear-Host
        Write-Host "--- SELECIONE OS CERTIFICADOS PARA $($ActionPrompt.ToUpper()) ---`n"
        for ($i = 0; $i -lt $MenuItems.Count; $i++) {
            Write-Host ("  [{0}] {1}" -f ($i + 1), $MenuItems[$i].Name)
        }
        Write-Host "`n  [T] $($ActionPrompt) TODOS"
        Write-Host "  [T - 1,3,...] $($ActionPrompt) todos EXCETO os numeros especificados"
        Write-Host "  [C] Cancelar e voltar ao menu principal`n"
        $selection = Read-Host "Selecione os numeros (separados por virgula), 'T', 'T - ...', ou 'C'"

        if ($selection -eq 'C') { return $null }

        $selectedItems = @()
        if ($selection -match '^(T|t)\s*-\s*(.*)') { # Logica para "Todos EXCETO"
            $allIndices = 1..$MenuItems.Count
            $excludedIndices = $matches[2] -split ',' | ForEach-Object { $_.Trim() }
            $finalIndices = $allIndices | Where-Object { $_ -notin $excludedIndices }
            foreach ($i in $finalIndices) { $selectedItems += $MenuItems[$i - 1] }
        } elseif ($selection -eq 'T') { # Logica para "Todos"
            $selectedItems = $MenuItems
        } else { # Logica para numeros especificos
            $indices = $selection -split ',' | ForEach-Object { $_.Trim() }
            foreach ($index in $indices) {
                if ($index -match '^\d+$' -and [int]$index -ge 1 -and [int]$index -le $MenuItems.Count) {
                    $selectedItems += $MenuItems[[int]$index - 1]
                }
            }
        }

        if ($selectedItems) {
            return $selectedItems
        } else {
            Write-Host "`nSelecao invalida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } while ($true)
}

# Função para instalar os certificados da pasta local
function Install-Certificates {
    Clear-Host
    $certFiles = Get-ChildItem -Path $PSScriptRoot | Where-Object { $_.Extension -in '.der', '.cer', '.crt' } | Select-Object @{Name='Name'; Expression={$_.Name}}, @{Name='Url'; Expression={$_.FullName}}
    
    if (-not $certFiles) {
        Write-Host "Nenhum arquivo de certificado foi encontrado para instalar." -ForegroundColor Red
        Read-Host "`nPressione ENTER para voltar ao menu..."
        return
    }

    $certsToInstall = Get-UserSelection -MenuItems $certFiles -ActionPrompt "Instalar"
    if (-not $certsToInstall) { return } # Usuario cancelou

    Clear-Host
    Write-Host "--- INICIANDO INSTALACAO SELECIONADA ---`n"
    foreach ($certItem in $certsToInstall) {
        $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certItem.Url)
        certutil -addstore "Root" $certItem.Url >$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Show-CertificateInfo -Certificate $certInfo -StatusMessage "INSTALADO COM SUCESSO" -StatusColor Green
        } else {
            Show-CertificateInfo -Certificate $certInfo -StatusMessage "FALHA NA INSTALACAO" -StatusColor Red
        }
    }
    Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
}

# Função para instalar via URL direta
function Install-FromUrl {
    Clear-Host
    Write-Host "--- BAIXAR E INSTALAR CERTIFICADO DE UMA URL ---`n" -ForegroundColor Magenta
    $url = Read-Host "Por favor, insira a URL DIRETA do arquivo do certificado (.der, .cer, .crt)"

    if (-not ($url.StartsWith("http://") -or $url.StartsWith("https://"))) {
        Write-Host "`n[ERRO] URL invalida. Deve comecar com http:// ou https://" -ForegroundColor Red
        Start-Sleep -Seconds 3
        return
    }

    $tempFilePath = Join-Path $env:TEMP "downloaded_cert_$(Get-Random).tmp"
    try {
        Write-Host "`nBaixando o arquivo de '$url'..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $tempFilePath
        $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($tempFilePath)
        certutil -addstore "Root" $tempFilePath >$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Show-CertificateInfo -Certificate $certInfo -StatusMessage "BAIXADO E INSTALADO COM SUCESSO" -StatusColor Magenta
        } else {
            Show-CertificateInfo -Certificate $certInfo -StatusMessage "FALHA NA INSTALACAO (Download OK)" -StatusColor Red
        }
    } catch { Write-Host "`n[ERRO] Falha ao processar o arquivo. Detalhes: $($_.Exception.Message)" -ForegroundColor Red } 
    finally { if (Test-Path $tempFilePath) { Remove-Item $tempFilePath -Force } }
    Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
}

# Função para buscar e instalar de uma pagina
function Install-FromWebPage {
    Clear-Host
    Write-Host "--- BUSCAR E INSTALAR CERTIFICADOS DE UMA PAGINA WEB ---`n" -ForegroundColor Cyan
    $pageUrl = Read-Host "Por favor, insira a URL da pagina que contem os links dos certificados"

    try {
        Write-Host "`nAnalisando a pagina '$pageUrl'..."
        $htmlContent = Invoke-WebRequest -Uri $pageUrl | Select-Object -ExpandProperty Content
        $regex = '<td>(.*?)<\/td>(?:.|\s)*?<td><a href="(.*?\.(?:der|cer|crt))"'
        $matches = [regex]::Matches($htmlContent, $regex)
        
        if ($matches.Count -eq 0) {
            Write-Host "`nNenhum link de certificado valido foi encontrado nesta pagina." -ForegroundColor Red
            Read-Host "`nPressione ENTER para voltar ao menu..."
            return
        }

        $menuItems = @()
        foreach ($match in $matches) {
            $friendlyName = ($match.Groups[1].Value -replace '<.*?>').Trim()
            if ($friendlyName -ne "Download") {
                $relativeUrl = $match.Groups[2].Value.Trim()
                $fullUrl = [System.Uri]::new([System.Uri]::new($pageUrl), $relativeUrl).AbsoluteUri
                $menuItems += [PSCustomObject]@{ Name = $friendlyName; Url  = $fullUrl }
            }
        }

        $certsToInstall = Get-UserSelection -MenuItems $menuItems -ActionPrompt "Instalar"
        if (-not $certsToInstall) { return } # Usuario cancelou

        Clear-Host
        Write-Host "--- INICIANDO INSTALACAO SELECIONADA ---`n"
        foreach ($certItem in $certsToInstall) {
            $tempFilePath = Join-Path $env:TEMP "downloaded_cert_$(Get-Random).tmp"
            try {
                Write-Host "`nBaixando '$($certItem.Name)' de '$($certItem.Url)'..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $certItem.Url -OutFile $tempFilePath
                $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($tempFilePath)
                certutil -addstore "Root" $tempFilePath >$null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Show-CertificateInfo -Certificate $certInfo -StatusMessage "INSTALADO COM SUCESSO" -StatusColor Green
                } else {
                    Show-CertificateInfo -Certificate $certInfo -StatusMessage "FALHA NA INSTALACAO" -StatusColor Red
                }
            } catch { Write-Host "`n[ERRO] Falha ao processar o certificado '$($certItem.Name)'. Detalhes: $($_.Exception.Message)" -ForegroundColor Red } 
            finally { if (Test-Path $tempFilePath) { Remove-Item $tempFilePath -Force } }
        }
        Read-Host "`nProcesso de instalacao em lote concluido. Pressione ENTER para voltar ao menu..."

    } catch {
        Write-Host "`n[ERRO] Nao foi possivel acessar ou analisar a pagina. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
    }
}

# Função para desinstalar os certificados da pasta local
function Uninstall-Certificates {
    Clear-Host
    $certFiles = Get-ChildItem -Path $PSScriptRoot | Where-Object { $_.Extension -in '.der', '.cer', '.crt' } | Select-Object @{Name='Name'; Expression={$_.Name}}, @{Name='Url'; Expression={$_.FullName}}

    if (-not $certFiles) {
        Write-Host "Nenhum arquivo de certificado foi encontrado para desinstalar." -ForegroundColor Red
        Read-Host "`nPressione ENTER para voltar ao menu..."
        return
    }

    $certsToUninstall = Get-UserSelection -MenuItems $certFiles -ActionPrompt "Desinstalar"
    if (-not $certsToUninstall) { return } # Usuario cancelou

    Clear-Host
    Write-Host "--- INICIANDO DESINSTALACAO SELECIONADA ---`n"
    foreach ($certItem in $certsToUninstall) {
        $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($certItem.Url)
        certutil -delstore "Root" $certInfo.SerialNumber >$null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Show-CertificateInfo -Certificate $certInfo -StatusMessage "DESINSTALADO COM SUCESSO" -StatusColor Yellow
        } else {
            Show-CertificateInfo -Certificate $certInfo -StatusMessage "NAO ENCONTRADO NO REPOSITORIO" -StatusColor Cyan
        }
    }
    Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
}

# Função para buscar e desinstalar de uma pagina
function Uninstall-FromWebPage {
    Clear-Host
    Write-Host "--- BUSCAR E DESINSTALAR CERTIFICADOS DE UMA PAGINA WEB ---`n" -ForegroundColor Red
    $pageUrl = Read-Host "Por favor, insira a URL da pagina que contem os links dos certificados"

    try {
        Write-Host "`nAnalisando a pagina '$pageUrl'..."
        $htmlContent = Invoke-WebRequest -Uri $pageUrl | Select-Object -ExpandProperty Content
        $regex = '<td>(.*?)<\/td>(?:.|\s)*?<td><a href="(.*?\.(?:der|cer|crt))"'
        $matches = [regex]::Matches($htmlContent, $regex)
        
        if ($matches.Count -eq 0) {
            Write-Host "`nNenhum link de certificado valido foi encontrado nesta pagina." -ForegroundColor Red
            Read-Host "`nPressione ENTER para voltar ao menu..."
            return
        }

        $menuItems = @()
        foreach ($match in $matches) {
            $friendlyName = ($match.Groups[1].Value -replace '<.*?>').Trim()
            if ($friendlyName -ne "Download") {
                $relativeUrl = $match.Groups[2].Value.Trim()
                $fullUrl = [System.Uri]::new([System.Uri]::new($pageUrl), $relativeUrl).AbsoluteUri
                $menuItems += [PSCustomObject]@{ Name = $friendlyName; Url  = $fullUrl }
            }
        }

        $certsToUninstall = Get-UserSelection -MenuItems $menuItems -ActionPrompt "Desinstalar"
        if (-not $certsToUninstall) { return } # Usuario cancelou

        Clear-Host
        Write-Host "--- INICIANDO DESINSTALACAO SELECIONADA ---`n"
        foreach ($certItem in $certsToUninstall) {
            $tempFilePath = Join-Path $env:TEMP "downloaded_cert_$(Get-Random).tmp"
            try {
                Write-Host "`nObtendo informacoes de '$($certItem.Name)'..." -ForegroundColor Cyan
                Invoke-WebRequest -Uri $certItem.Url -OutFile $tempFilePath
                $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($tempFilePath)
                
                certutil -delstore "Root" $certInfo.SerialNumber >$null 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Show-CertificateInfo -Certificate $certInfo -StatusMessage "DESINSTALADO COM SUCESSO" -StatusColor Yellow
                } else {
                    Show-CertificateInfo -Certificate $certInfo -StatusMessage "NAO ENCONTRADO NO REPOSITORIO" -StatusColor Cyan
                }
            } catch { Write-Host "`n[ERRO] Falha ao processar o certificado '$($certItem.Name)'. Detalhes: $($_.Exception.Message)" -ForegroundColor Red } 
            finally { if (Test-Path $tempFilePath) { Remove-Item $tempFilePath -Force } }
        }
        Read-Host "`nProcesso de desinstalacao em lote concluido. Pressione ENTER para voltar ao menu..."

    } catch {
        Write-Host "`n[ERRO] Nao foi possivel acessar ou analisar a pagina. Detalhes: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
    }
}

# Função para o menu do analisador
function Show-AnalyzerMenu {
    do {
        Clear-Host
        Write-Host "
  =========================================================
                   MODO DE ANALISE
  =========================================================

     1 - Analisar TODOS os certificados
     2 - Analisar um certificado ESPECIFICO

     0 - Voltar ao menu principal
        "
        $analyzerChoice = Read-Host "Escolha uma opcao de analise"
        
        switch ($analyzerChoice) {
            '1' {
                Clear-Host
                $certFiles = Get-ChildItem -Path $PSScriptRoot | Where-Object { $_.Extension -in '.der', '.cer', '.crt' }
                if ($certFiles) {
                    $certFiles | ForEach-Object {
                        $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($_.FullName)
                        Show-CertificateInfo -Certificate $certInfo
                    }
                } else { Write-Host "Nenhum arquivo de certificado encontrado." -ForegroundColor Red }
                Read-Host "`nAnalise concluida. Pressione ENTER para voltar..."
            }
            '2' {
                $fileName = Read-Host "Digite o nome completo do arquivo"
                if (Test-Path $fileName) {
                    Clear-Host
                    $certInfo = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($fileName)
                    Show-CertificateInfo -Certificate $certInfo
                } else { Write-Host "`n[ERRO] Arquivo '$fileName' nao encontrado!" -ForegroundColor Red; Start-Sleep 2 }
                Read-Host "`nAnalise concluida. Pressione ENTER para voltar..."
            }
        }
    } while ($analyzerChoice -ne '0')
}

# ============================================================================
# 3. LOOP PRINCIPAL DO PROGRAMA
# ============================================================================
do {
    Show-MainMenu
    $mainChoice = Read-Host "Digite o numero da sua escolha e pressione ENTER"

    switch ($mainChoice) {
        '1' { Install-Certificates }
        '2' { Uninstall-Certificates }
        '3' { Show-AnalyzerMenu }
        '4' { Install-FromUrl }
        '5' { Install-FromWebPage }
        '6' { Uninstall-FromWebPage }
        '0' { # Sai do loop
        }
        default {
            Write-Host "`nOpcao invalida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($mainChoice -ne '0')```