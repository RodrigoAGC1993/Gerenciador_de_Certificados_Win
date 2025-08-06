# Gerenciador de Certificados Unificado

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Uma ferramenta de linha de comando completa, desenvolvida em PowerShell, para simplificar a instalação, desinstalação e análise de certificados de segurança (`.der`, `.cer`, `.crt`) em massa em ambientes Windows.

## Visão Geral

Este utilitário foi criado para automatizar tarefas repetitivas de gerenciamento de certificados, centralizando múltiplas funções em uma única interface interativa e robusta. É a solução ideal para administradores de sistemas, equipes de TI e desenvolvedores que precisam garantir a padronização de certificados em diversas máquinas.

## Funcionalidades Principais

-   **Instalação em Massa:** Instala todos os certificados contidos na pasta diretamente no repositório de "Autoridades de Certificação Raiz Confiáveis".
-   **Desinstalação em Massa:** Remove, de forma segura, os certificados do repositório com base nos arquivos presentes na pasta, utilizando o Número de Série.
-   **Análise Detalhada:** Oferece um modo de diagnóstico para visualizar informações cruciais de um ou de todos os certificados.
-   **Interface Interativa:** Apresenta um menu de fácil navegação que guia o usuário através das opções.
-   **Auto-Elevação de Privilégios:** Verifica automaticamente se possui permissões de administrador e solicita a elevação (UAC prompt).
-   **Feedback Claro:** Fornece relatórios de status em tempo real para cada operação, com formatação e cores que facilitam a identificação de sucessos e falhas.

## Cenários de Utilização

Esta ferramenta é particularmente útil para:

-   **Configuração de Novas Máquinas (Onboarding):** Instale todos os certificados raiz da empresa de uma só vez.
-   **Manutenção e Ciclo de Vida de Certificados:** Desinstale versões antigas e instale as novas em todo o parque de máquinas.
-   **Ambientes de Desenvolvimento e Teste:** Adicione e remova rapidamente certificados de teste.
-   **Auditoria e Resolução de Problemas:** Verifique rapidamente se os certificados necessários estão instalados e válidos.

## Instruções de Uso

1.  **Preparação:**
    -   Crie uma pasta para o projeto.
    -   Coloque o arquivo `GerenciadorUnificado.ps1` dentro desta pasta.
    -   Adicione todos os arquivos de certificado que deseja gerenciar (`.der`, `.cer`, `.crt`) na mesma pasta.

2.  **Execução:**
    -   Clique com o **botão direito** no arquivo `GerenciadorUnificado.ps1`.
    -   No menu de contexto, selecione a opção **"Executar com o PowerShell"**.
    -   A janela de permissão do Windows (UAC) aparecerá. Clique em **"Sim"** para conceder os privilégios de administrador.
    -   A ferramenta será iniciada, exibindo o menu principal.

## Como Contribuir

Contribuições são bem-vindas! Se você tem ideias para novas funcionalidades ou encontrou um bug, por favor, veja nossas diretrizes de contribuição em [CONTRIBUTING.md](CONTRIBUTING.md).

## Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.


_____________________________________________________________________________________________________________________________


# Unified Certificate Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive command-line tool, developed in PowerShell, to simplify the bulk installation, uninstallation, and analysis of security certificates (`.der`, `.cer`, `.crt`) in Windows environments.

## Overview

This utility was created to automate repetitive certificate management tasks by centralizing multiple functions into a single, robust, and interactive interface. It is the ideal solution for system administrators, IT teams, and developers who need to ensure certificate standardization across multiple machines.

## Key Features

-   **Bulk Installation:** Installs all certificates contained in the folder directly into the system's "Trusted Root Certification Authorities" store.
-   **Bulk Uninstallation:** Safely removes certificates from the store based on the files present in the folder, using the unique Serial Number as an identifier.
-   **Detailed Analysis:** Offers a diagnostic mode to view crucial information for one or all certificates.
-   **Interactive Interface:** Features an easy-to-navigate menu that guides the user through the available options.
-   **Automatic Privilege Elevation:** Automatically checks for administrator permissions and requests elevation (UAC prompt) if necessary.
-   **Clear Feedback:** Provides real-time status reports for each operation, with formatting and colors that make it easy to identify successes and failures.

## Use Cases

This tool is particularly useful for:

-   **New Machine Setup (Onboarding):** Install all company root certificates at once.
-   **Certificate Lifecycle Management:** Uninstall old versions and deploy new ones across all machines.
-   **Development and Test Environments:** Quickly add and remove test certificates.
-   **Auditing and Troubleshooting:** Verify if the necessary certificates are installed and valid.

## Usage Instructions

1.  **Preparation:**
    -   Create a folder for the project.
    -   Place the `GerenciadorUnificado.ps1` file inside this folder.
    -   Add all the certificate files you wish to manage (`.der`, `.cer`, `.crt`) to the same folder.

2.  **Execution:**
    -   **Right-click** on the `GerenciadorUnificado.ps1` file.
    -   From the context menu, select the **"Run with PowerShell"** option.
    -   The Windows User Account Control (UAC) prompt will appear. Click **"Yes"** to grant administrator privileges.
    -   The tool will launch, displaying the main menu.

## How to Contribute

Contributions are welcome! If you have ideas for new features or have found a bug, please see our contribution guidelines in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.