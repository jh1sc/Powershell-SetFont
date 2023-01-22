if (-not ("Windows.Native.Kernel32" -as [type]))
{
  Add-Type -TypeDefinition @"
    namespace Windows.Native
    {
      using System;
      using System.ComponentModel;
      using System.IO;
      using System.Runtime.InteropServices;
      public class Kernel32
      {
        public const uint FILE_SHARE_READ = 1;
        public const uint FILE_SHARE_WRITE = 2;
        public const uint GENERIC_READ = 0x80000000;
        public const uint GENERIC_WRITE = 0x40000000;
        public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
        public const int STD_ERROR_HANDLE = -12;
        public const int STD_INPUT_HANDLE = -10;
        public const int STD_OUTPUT_HANDLE = -11;
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public class CONSOLE_FONT_INFOEX
        {
          private int cbSize;
          public CONSOLE_FONT_INFOEX()
          {
            this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));
          }
          public int FontIndex;
          public short FontWidth;
          public short FontHeight;
          public int FontFamily;
          public int FontWeight;
          [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
          public string FaceName;
        }
        public class Handles
        {
          public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);
          public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);
          public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);
        }
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool CloseHandle(IntPtr hHandle);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr CreateFile
          (
          [MarshalAs(UnmanagedType.LPTStr)] string filename,
          uint access,
          uint share,
          IntPtr securityAttributes, 
          [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,
          uint flagsAndAttributes,
          IntPtr templateFile
          );
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern bool GetCurrentConsoleFontEx
          (
          IntPtr hConsoleOutput, 
          bool bMaximumWindow, 
          [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont
          );
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern IntPtr GetStdHandle(int nStdHandle);
        [DllImport("kernel32.dll", SetLastError=true)]
        public static extern bool SetCurrentConsoleFontEx
          (
          IntPtr ConsoleOutput, 
          bool MaximumWindow,
          [In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx
          );
        public static IntPtr CreateFile(string fileName, uint fileAccess, 
          uint fileShare, FileMode creationDisposition)
        {
          IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, 
            creationDisposition, 0U, IntPtr.Zero);
          if (hFile == INVALID_HANDLE_VALUE)
          {
            throw new Win32Exception();
          }
          return hFile;
        }
        public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx()
        {
          IntPtr hFile = IntPtr.Zero;
          try
          {
            hFile = CreateFile("CONOUT$", GENERIC_READ,
            FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);
            return GetCurrentConsoleFontEx(hFile);
          }
          finally
          {
            CloseHandle(hFile);
          }
        }
        public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi)
        {
          IntPtr hFile = IntPtr.Zero;
          try
          {
            hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,
              FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);
            SetCurrentConsoleFontEx(hFile, false, cfi);
          }
          finally
          {
            CloseHandle(hFile);
          }
        }
        public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx
          (
          IntPtr outputHandle
          )
        {
          CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();
          if (!GetCurrentConsoleFontEx(outputHandle, false, cfi))
          {
            throw new Win32Exception();
          }

          return cfi;
        }
      }
    }
"@
}

Function SaveFont 
{
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SavedNameOfFont
    )
    try
    {
        # Create or open the file to save the font information
        $file = "$env:TEMP\SavedFonts.txt"
        if (!(Test-Path $file)) {New-Item -ItemType "File" -Path $file -Force}

        # Get the current console font information
        $FontAspects = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx()

        # Create an object to hold the font information
        $SavedFont = @(
            [pscustomobject]@{
            SavedName = $SavedNameOfFont
            FontIndex = $FontAspects.FontIndex
            FontWidth =  $FontAspects.FontWidth
            FontHeight = $FontAspects.FontHeight
            FontFamily = $FontAspects.FontFamily
            FontWeight = $FontAspects.FontWeight
            FaceName = $FontAspects.FaceName
            }
        )
        
        # Add the font information to the file
        Add-Content -Path $file -Value $SavedFont | out-null
        return $SavedFont
    }
    catch
    {
        Write-Error "An error occurred while saving the font: $($_.Exception.Message)"
    }
}

Function ListSavedFont 
{
    try
    {
        $SavedFonts = @()
        $contents = gc "$env:TEMP\SavedFonts.txt"
        $pattern = '@{SavedName=([^;]+); FontIndex=([^;]+); FontWidth=([^;]+); FontHeight=([^;]+); FontFamily=([^;]+); FontWeight=([^;]+); FaceName=([^}]+)}'
        $matches = [regex]::matches($contents, $pattern)

        # Iterate through each match and create a custom object for each
        foreach ($match in $matches) {
            $SavedFonts += @(
                [pscustomobject]@{
                SavedName = $match.Groups[1].Value
                FontIndex = $match.Groups[2].Value
                FontWidth = $match.Groups[3].Value
                FontHeight = $match.Groups[4].Value
                FontFamily = $match.Groups[5].Value
                FontWeight = $match.Groups[6].Value
                FaceName = $match.Groups[7].Value
                })
        }
        return $SavedFonts
    }
    catch
    {
        Write-Error "An error occurred while listing saved fonts: $($_.Exception.Message)"
    }
}
      
Function SetFont 
{
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SavedNameOfFont
    )
    try
    {
        $contents = gc "$env:TEMP\SavedFonts.txt"
        $pattern = '@{SavedName=([^;]+); FontIndex=([^;]+); FontWidth=([^;]+); FontHeight=([^;]+); FontFamily=([^;]+); FontWeight=([^;]+); FaceName=([^}]+)}'
        $matches = [regex]::matches($contents, $pattern)

        # Iterate through each match and set the font if the saved name matches the specified name
        foreach ($match in $matches) {
            if ($match.Groups[1].Value -eq $SavedNameOfFont) {
                $FontAspects = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx()
                $FontAspects.FontIndex = $match.Groups[2].Value
                $FontAspects.FontWidth = $match.Groups[3].Value
                $FontAspects.FontHeight = $match.Groups[4].Value
                $FontAspects.FontFamily = $match.Groups[5].Value
                $FontAspects.FontWeight = $match.Groups[6].Value
                $FontAspects.FaceName = $match.Groups[7].Value
                [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($FontAspects)
            }
        }
    }
    catch
    {
        Write-Error "An error occurred while setting the font: $($_.Exception.Message)"
    }
}

Function RemoveSavedFont 
{
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$SavedNameOfFont
    )
    try
    {
        $file = "$env:TEMP\SavedFonts.txt"
        $contents = Get-Content $file
        $newContent = $contents | Where-Object { $_ -notlike "*$SavedNameOfFont*" }
        Set-Content -Path $file -Value $newContent
    }
    catch
    {
        Write-Error "An error occurred while removing the saved font: $($_.Exception.Message)"
    }
}





