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
    $Host.UI.RawUI.WindowTitle = 'Gerenciador de Certificados Unificado v2.1'
    Write-Host "
  =========================================================
        GERENCIADOR DE CERTIFICADOS UNIFICADO
  =========================================================

  Escolha uma acao:

     1 - INSTALAR todos os certificados da pasta
     2 - DESINSTALAR todos os certificados da pasta
     3 - ANALISAR certificados

     0 - Sair da ferramenta

  ========================================================="
}

# --- BLOCO DE EXIBICAO COM LIMPEZA DE TEXTO ---
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


# Função para instalar os certificados
function Install-Certificates {
    Clear-Host
    Write-Host "--- INICIANDO INSTALACAO ---`n" -ForegroundColor Green
    $certFiles = Get-ChildItem -Path $PSScriptRoot | Where-Object { $_.Extension -in '.der', '.cer', '.crt' }
    
    if (-not $certFiles) {
        Write-Host "Nenhum arquivo de certificado foi encontrado para instalar." -ForegroundColor Red
    } else {
        foreach ($cert in $certFiles) {
            $certInfo = Get-PfxCertificate -FilePath $cert.FullName
            certutil -addstore "Root" $cert.FullName >$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                Show-CertificateInfo -Certificate $certInfo -StatusMessage "INSTALADO COM SUCESSO" -StatusColor Green
            } else {
                Show-CertificateInfo -Certificate $certInfo -StatusMessage "FALHA NA INSTALACAO" -StatusColor Red
            }
        }
    }
    Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
}

# Função para desinstalar os certificados
function Uninstall-Certificates {
    Clear-Host
    Write-Host "--- INICIANDO DESINSTALACAO ---`n" -ForegroundColor Yellow
    $certFiles = Get-ChildItem -Path $PSScriptRoot | Where-Object { $_.Extension -in '.der', '.cer', '.crt' }

    if (-not $certFiles) {
        Write-Host "Nenhum arquivo de certificado foi encontrado para desinstalar." -ForegroundColor Red
    } else {
        foreach ($cert in $certFiles) {
            $certInfo = Get-PfxCertificate -FilePath $cert.FullName
            certutil -delstore "Root" $certInfo.SerialNumber >$null 2>&1
            if ($LASTEXITCODE -eq 0) {
                Show-CertificateInfo -Certificate $certInfo -StatusMessage "DESINSTALADO COM SUCESSO" -StatusColor Yellow
            } else {
                Show-CertificateInfo -Certificate $certInfo -StatusMessage "NAO ENCONTRADO NO REPOSITORIO" -StatusColor Cyan
            }
        }
    }
    Read-Host "`nProcesso concluido. Pressione ENTER para voltar ao menu..."
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
                        $certInfo = Get-PfxCertificate -FilePath $_.FullName
                        Show-CertificateInfo -Certificate $certInfo
                    }
                } else { Write-Host "Nenhum arquivo de certificado encontrado." -ForegroundColor Red }
                Read-Host "`nAnalise concluida. Pressione ENTER para voltar..."
            }
            '2' {
                $fileName = Read-Host "Digite o nome completo do arquivo"
                if (Test-Path $fileName) {
                    Clear-Host
                    $certInfo = Get-PfxCertificate -FilePath $fileName
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
        '0' { # Sai do loop
        }
        default {
            Write-Host "`nOpcao invalida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($mainChoice -ne '0')