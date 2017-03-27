Add-Type @"
  using System;
  using System.IO;
  using System.Runtime.InteropServices;
  using Microsoft.Win32.SafeHandles;
  
  namespace KScript {
    public class LongItem {
      [StructLayout(LayoutKind.Sequential)]
      public struct FILETIME {
          public uint dwLowDateTime;
          public uint dwHighDateTime;
      };
    
      [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
      public struct WIN32_FIND_DATA {
        public FileAttributes dwFileAttributes;
        public FILETIME ftCreationTime;
        public FILETIME ftLastAccessTime;
        public FILETIME ftLastWriteTime;
        public int nFileSizeHigh;
        public int nFileSizeLow;
        public int dwReserved0;
        public int dwReserved1;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        public string cFileName;
        // not using this
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)]
        public string cAlternate;
      }
    
      [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
      public static extern IntPtr FindFirstFile(string lpFileName, out WIN32_FIND_DATA lpFindFileData);
      
      [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
      public static extern bool FindNextFile(IntPtr hFindFile, out WIN32_FIND_DATA lpFindFileData);
      
      [DllImport("kernel32.dll", SetLastError = true)]
      [return: MarshalAs(UnmanagedType.Bool)]
      public static extern bool FindClose(IntPtr hFindFile);
    }
  }
"@