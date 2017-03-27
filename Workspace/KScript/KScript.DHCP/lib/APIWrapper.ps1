# This library is partial P/Invoke wrapper around the DHCP API. The following functions are wrapped:
#
#   * DhcpEnumSubnetClients
#   * DhcpEnumSubnets
#   * DhcpGetSubnetInfo
#
# The structures returned by each of the functions are translated into fully managed .NET objects.
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   08/01/2015 - Chris Dent - First release.

Add-Type @"
  using KScript.Dhcp;
  using System;
  using System.Collections;
  using System.Net;
  using System.Runtime.InteropServices;

  namespace KScript {
    namespace Dhcp {
      //
      // Enumerations
      //
      
      public enum SubnetState : uint {
        DhcpSubnetEnabled = 0,
        DhcpSubnetDisabled,
        DhcpSubnetEnabledSwitched,
        DhcpSubnetDisabledSwitched,
        DhcpSubnetInvalidState
      }
  
      //
      // Simplified return objects.
      //
    
      public class ClientInfo {
        public IPAddress ClientIPAddress { get; private set; }
        public IPAddress SubnetMask { get; private set; }
        public String ClientHardwareAddress { get; private set; }
        public String ClientName { get; private set; }
        public String ClientComment { get; private set; }
        public DateTime ClientLeaseExpires { get; private set; }
        public HostInfo OwnerHost { get; private set; }
        
        internal ClientInfo(APIWrapper.DHCP_CLIENT_INFO DhcpClientInfo) {
          this.ClientIPAddress = DhcpInformation.ConvertToIPAddress(DhcpClientInfo.ClientIPAddress);
          this.SubnetMask = DhcpInformation.ConvertToIPAddress(DhcpClientInfo.SubnetMask);
          this.ClientHardwareAddress = DhcpClientInfo.ClientHardwareAddress.ToString();
          this.ClientName = DhcpClientInfo.ClientName;
          this.ClientComment = DhcpClientInfo.ClientComment;
          this.ClientLeaseExpires = DhcpClientInfo.ClientLeaseExpires.ToDateTime();
          this.OwnerHost = new HostInfo(DhcpClientInfo.OwnerHost);
        }
        
        public override String ToString() {
          return String.Format("{0} ({1}/{2})", this.ClientName, this.ClientIPAddress, this.ClientHardwareAddress);
        }
      }
   
      public class HostInfo {
        public IPAddress IPAddress { get; private set; }
        public String NetBiosName { get; private set; }
        public String HostName { get; private set; }
        
        internal HostInfo(APIWrapper.DHCP_HOST_INFO DhcpHostInfo) {
          this.IPAddress = DhcpInformation.ConvertToIPAddress(DhcpHostInfo.IPAddress);
          this.NetBiosName = DhcpHostInfo.NetBiosName;
          this.HostName = DhcpHostInfo.HostName;
        }
        
        public override String ToString() {
          return this.HostName;
        }
      }
      
      public class SubnetInfo {
        public IPAddress SubnetAddress { get; private set; }
        public IPAddress SubnetMask { get; private set; }
        public String SubnetName { get; private set; }
        public String SubnetComment { get; private set; }
        public HostInfo PrimaryHost { get; private set; }
        public SubnetState SubnetState { get; private set; }
        
        internal SubnetInfo(APIWrapper.DHCP_SUBNET_INFO DhcpSubnetInfo) {
          this.SubnetAddress = DhcpInformation.ConvertToIPAddress(DhcpSubnetInfo.SubnetAddress);
          this.SubnetMask = DhcpInformation.ConvertToIPAddress(DhcpSubnetInfo.SubnetMask);
          this.SubnetName = DhcpSubnetInfo.SubnetName;
          this.SubnetComment = DhcpSubnetInfo.SubnetComment;
          this.PrimaryHost = new HostInfo(DhcpSubnetInfo.PrimaryHost);
          this.SubnetState = DhcpSubnetInfo.SubnetState;
        }
      }
    
      //
      // Methods used to translate objects and execute API functions.
      //
    
      public class DhcpInformation { 
        public static SubnetInfo GetSubnet(IPAddress ServerIPAddress, IPAddress SubnetAddress) {
          IntPtr SubnetInfoPtr;
        
          uint ReturnCode = APIWrapper.DhcpGetSubnetInfo(
            ServerIPAddress.ToString(),
            ConvertFromIPAddress(SubnetAddress),
            out SubnetInfoPtr);
            
          if (ReturnCode == 0) {
            APIWrapper.DHCP_SUBNET_INFO SubnetInfoRaw = (APIWrapper.DHCP_SUBNET_INFO)Marshal.PtrToStructure(SubnetInfoPtr, typeof(APIWrapper.DHCP_SUBNET_INFO));
            SubnetInfo SubnetInfo = new SubnetInfo(SubnetInfoRaw);
            
            return SubnetInfo;
          } else {
            // throw new AccessDeniedException
          
            return null;
          }
        }
        
        public static SubnetInfo[] GetSubnets(IPAddress ServerIPAddress) {
          uint ResumeHandle = 0;
          IntPtr SubnetIPArrayPtr;
          uint ElementsRead = 0;
          uint ElementsTotal = 0;
          ArrayList ReturnValues = new ArrayList();
        
          uint ReturnCode = APIWrapper.DhcpEnumSubnets(
            ServerIPAddress.ToString(),
            ref ResumeHandle,
            65536,
            out SubnetIPArrayPtr,
            out ElementsRead,
            out ElementsTotal
          );
          
          if (ReturnCode == 0) {
            APIWrapper.DHCP_IP_ARRAY SubnetIPArray = (APIWrapper.DHCP_IP_ARRAY)Marshal.PtrToStructure(SubnetIPArrayPtr, typeof(APIWrapper.DHCP_IP_ARRAY));
            IntPtr CurrentElementPtr = SubnetIPArray.Elements;
            
            for (int i = 0; i < SubnetIPArray.NumElements; i++) {
              APIWrapper.DHCP_IP_ADDRESS SubnetAddressRaw = (APIWrapper.DHCP_IP_ADDRESS)Marshal.PtrToStructure(CurrentElementPtr, typeof(APIWrapper.DHCP_IP_ADDRESS));
              IPAddress SubnetAddress = ConvertToIPAddress(SubnetAddressRaw.IPAddress);
              
              SubnetInfo SubnetInfo = GetSubnet(ServerIPAddress, SubnetAddress);
              ReturnValues.Add(SubnetInfo);
              
              CurrentElementPtr = (IntPtr)((int)CurrentElementPtr + (int)Marshal.SizeOf(typeof(IntPtr)));
            }
          }
          
          return (ReturnValues.ToArray(typeof(SubnetInfo)) as SubnetInfo[]);
        }
        
        public static ClientInfo[] GetSubnetClients(IPAddress ServerIPAddress, IPAddress SubnetAddress) {
          uint ResumeHandle = 0;
          IntPtr ClientInfoArrayPtr;
          uint ElementsRead = 0;
          uint ElementsTotal = 0;
          ArrayList ReturnValues = new ArrayList();
          
          uint ReturnCode = APIWrapper.DhcpEnumSubnetClients(
            ServerIPAddress.ToString(),
            ConvertFromIPAddress(SubnetAddress),
            ref ResumeHandle,
            65536,
            out ClientInfoArrayPtr,
            out ElementsRead,
            out ElementsTotal
          );
          
          if (ReturnCode == 0) {
            APIWrapper.DHCP_CLIENT_INFO_ARRAY ClientInfoArray = (APIWrapper.DHCP_CLIENT_INFO_ARRAY)Marshal.PtrToStructure(ClientInfoArrayPtr, typeof(APIWrapper.DHCP_CLIENT_INFO_ARRAY));
            IntPtr CurrentElementPtr = ClientInfoArray.Elements;
            
            for (int i = 0; i < ClientInfoArray.NumElements; i++) {
              APIWrapper.DHCP_CLIENT_INFO ClientInfoRaw = (APIWrapper.DHCP_CLIENT_INFO)Marshal.PtrToStructure(Marshal.ReadIntPtr(CurrentElementPtr), typeof(APIWrapper.DHCP_CLIENT_INFO));
              
              ClientInfo ClientInfo = new ClientInfo(ClientInfoRaw);
              ReturnValues.Add(ClientInfo);
              
              CurrentElementPtr = (IntPtr)((int)CurrentElementPtr + (int)Marshal.SizeOf(typeof(IntPtr)));
            }
          }
          
          return (ReturnValues.ToArray(typeof(ClientInfo)) as ClientInfo[]);
        }

        //
        // IP conversion
        //
        
        internal static IPAddress ConvertToIPAddress(UInt32 Value) {
          Byte[] IPArray = new Byte[4];
          
          for (int i = 3; i > -1; i--) {
            Double Remainder = Value % Math.Pow(256, i);
            IPArray[3 - i] = (Byte)((Value - Remainder) / Math.Pow(256, i));
            Value = (UInt32)Remainder;
          }

          return IPAddress.Parse(String.Format("{0}.{1}.{2}.{3}", 
            IPArray[0],
            IPArray[1],
            IPArray[2],
            IPArray[3]));
        }

        internal static UInt32 ConvertFromIPAddress(IPAddress Value) {
          UInt32 DecimalValue = 0;
          Byte[] Bytes = Value.GetAddressBytes();
          for (int i = 0; i < 4; i++) {
            DecimalValue = DecimalValue | (UInt32)(Bytes[i] << (8 * (3 - i)));
          }
          return DecimalValue;
        }
      }
      
      //
      // API Wrapper
      //
    
      internal class APIWrapper {
        //
        // Structures
        //
      
        // Primitive
      
        [StructLayout(LayoutKind.Sequential)]
        internal struct DATE_TIME {
          internal uint dwLowDateTime;
          internal uint dwHighDateTime;

          internal DateTime ToDateTime() {
            if (dwHighDateTime == 0 && dwLowDateTime == 0) {
              return DateTime.MinValue;
            }
            if (dwHighDateTime == int.MaxValue && dwLowDateTime == UInt32.MaxValue) {
              return DateTime.MaxValue;
            }
            return DateTime.FromFileTime((((long)dwHighDateTime) << 32) | dwLowDateTime);
          }
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct DHCP_BINARY_DATA {
          internal uint DataLength;
          internal IntPtr Data;
          
          public override String ToString() { 
            return String.Format("{0:X2}:{1:X2}:{2:X2}:{3:X2}:{4:X2}:{5:X2}",
              Marshal.ReadByte(this.Data),
              Marshal.ReadByte(this.Data, 1),
              Marshal.ReadByte(this.Data, 2),
              Marshal.ReadByte(this.Data, 3),
              Marshal.ReadByte(this.Data, 4),
              Marshal.ReadByte(this.Data, 5));
          }
        }
      
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        internal struct DHCP_CLIENT_INFO_ARRAY {
          internal uint NumElements;
          internal IntPtr Elements;
        }
       
        [StructLayout(LayoutKind.Sequential)]
        internal struct DHCP_HOST_INFO {
          internal uint IPAddress;
          [MarshalAs(UnmanagedType.LPWStr)]internal string NetBiosName;
          [MarshalAs(UnmanagedType.LPWStr)]internal string HostName;
        }
       
        [StructLayout(LayoutKind.Sequential)]
        internal struct DHCP_IP_ADDRESS {
          internal uint IPAddress;
        }
       
        [StructLayout(LayoutKind.Sequential)]
        internal struct DHCP_IP_ARRAY {
          internal uint NumElements;
          internal IntPtr Elements;
        }

        // Complex
        
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        internal struct DHCP_CLIENT_INFO {
          internal uint ClientIPAddress;
          internal uint SubnetMask;
          internal DHCP_BINARY_DATA ClientHardwareAddress;
          [MarshalAs(UnmanagedType.LPWStr)]internal string ClientName;
          [MarshalAs(UnmanagedType.LPWStr)]internal string ClientComment;
          internal DATE_TIME ClientLeaseExpires;
          internal DHCP_HOST_INFO OwnerHost;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
        internal struct DHCP_SUBNET_INFO {
          internal uint SubnetAddress;
          internal uint SubnetMask;
          [MarshalAs(UnmanagedType.LPWStr)]internal string SubnetName;
          [MarshalAs(UnmanagedType.LPWStr)]internal string SubnetComment;
          internal DHCP_HOST_INFO PrimaryHost;
          internal SubnetState SubnetState;
        }

        //
        // Methods
        //

        [DllImport("dhcpsapi.dll")]
        internal static extern uint DhcpEnumSubnets(
          [MarshalAs(UnmanagedType.LPWStr)]string ServerIPAddress,
          ref uint ResumeHandle,
          uint PreferredMaximum,
          out IntPtr SubnetIPArray,
          out uint ElementsRead,
          out uint ElementsTotal
        );

        [DllImport("dhcpsapi.dll")]
        internal static extern uint DhcpEnumSubnetClients(
          [MarshalAs(UnmanagedType.LPWStr)]string ServerIpAddress,
          uint SubnetAddress,
          ref uint ResumeHandle,
          uint PreferredMaximum,
          out IntPtr ClientInfo,
          out uint ElementsRead,
          out uint ElementsTotal
        );
        
        [DllImport("dhcpsapi.dll")]
        internal static extern uint DhcpGetSubnetInfo(
          [MarshalAs(UnmanagedType.LPWStr)]string ServerIPAddress,
          uint SubnetAddress,
          out IntPtr SubnetInfo
        );
      }
    }
  }
"@