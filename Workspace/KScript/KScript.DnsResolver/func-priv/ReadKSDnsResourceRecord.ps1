function ReadKSDnsResourceRecord {
  # .SYNOPSIS
  #   Reads common DNS resource record fields from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Reads a byte array in the following format:
  #
  #                                   1  1  1  1  1  1
  #     0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                      NAME                     /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TYPE                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     CLASS                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TTL                      |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   RDLENGTH                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
  #    /                     RDATA                     /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-KSBinaryReader (Indented.Common) containing a byte array representing a DNS resource record.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-KSBinaryReader (Indented.Common)  
  # .OUTPUTS
  #   KScript.DnsResolver.Message.ResourceRecord
  # .LINK
  #   http://www.ietf.org/rfc/rfc1035.txt

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader
  )
  
  if ($Script:IndentedDnsTCEndFound) {
    # Return $null, cannot read past the end of a truncated packet.
    return 
  }
  
  $ResourceRecord = New-Object PsObject -Property ([Ordered]@{
    Name             = "";
    TTL              = [UInt32]0;
    RecordClass      = [KScript.DnsResolver.RecordClass]::IN;
    RecordType       = [KScript.DnsResolver.RecordType]::Empty;
    RecordDataLength = 0;
    RecordData       = "";
  })
  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord")
  
  # Property: Name
  $ResourceRecord.Name = ConvertToKSDnsDomainName $BinaryReader
  
  # Test whether or not the response is complete enough to read basic fields.
  if ($BinaryReader.BaseStream.Capacity -lt ($BinaryReader.BaseStream.Position + 10)) {
    # Set a variable to globally track the state of the packet read.
    $Script:IndentedDnsTCEndFound = $true
    # Return what we know.
    return $ResourceRecord    
  }
  
  # Property: RecordType
  $ResourceRecord.RecordType = $BinaryReader.ReadBEUInt16()
  if ([Enum]::IsDefined([KScript.DnsResolver.RecordType], $ResourceRecord.RecordType)) {
    $ResourceRecord.RecordType = [KScript.DnsResolver.RecordType]$ResourceRecord.RecordType
  } else {
    $ResourceRecord.RecordType = "UNKNOWN ($($ResourceRecord.RecordType))"
  }
  # Property: RecordClass
  if ($ResourceRecord.RecordType -eq [KScript.DnsResolver.RecordType]::OPT) {
    $ResourceRecord.RecordClass = $BinaryReader.ReadBEUInt16()
  } else {
    $ResourceRecord.RecordClass = [KScript.DnsResolver.RecordClass]$BinaryReader.ReadBEUInt16()
  }
  # Property: TTL
  $ResourceRecord.TTL = $BinaryReader.ReadBEUInt32()
  # Property: RecordDataLength
  $ResourceRecord.RecordDataLength = $BinaryReader.ReadBEUInt16()
  
  # Method: ToString
  $ResourceRecord | Add-Member ToString -MemberType ScriptMethod -Force -Value {
    return [String]::Format("{0} {1} {2} {3} {4}",
      $this.Name.PadRight(29, ' '),
      $this.TTL.ToString().PadRight(10, ' '),
      $this.RecordClass.ToString().PadRight(5, ' '),
      $this.RecordType.ToString().PadRight(5, ' '),
      $this.RecordData)
  }
  
  # Mark the beginning of the RecordData
  $BinaryReader.SetPositionMarker()
  
  $Params = @{BinaryReader = $BinaryReader; ResourceRecord = $ResourceRecord}
  
  if ($BinaryReader.BaseStream.Capacity -lt ($BinaryReader.BaseStream.Position + $ResourceRecord.RecordDataLength)) {
    # Set a variable to globally track the state of the packet read.
    $Script:IndentedDnsTCEndFound = $true
    # Return what we know.
    return $ResourceRecord
  }

  # Create appropriate properties for each record type  
  switch ($ResourceRecord.RecordType) {
    ([KScript.DnsResolver.RecordType]::A)           { $ResourceRecord = ReadKSDnsARecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NS)          { $ResourceRecord = ReadKSDnsNSRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MD)          { $ResourceRecord = ReadKSDnsMDRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MF)          { $ResourceRecord = ReadKSDnsMFRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::CNAME)       { $ResourceRecord = ReadKSDnsCNAMERecord @Params; break }
    ([KScript.DnsResolver.RecordType]::SOA)         { $ResourceRecord = ReadKSDnsSOARecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MB)          { $ResourceRecord = ReadKSDnsMBRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MG)          { $ResourceRecord = ReadKSDnsMGRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MR)          { $ResourceRecord = ReadKSDnsMRRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NULL)        { $ResourceRecord = ReadKSDnsNULLRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::WKS)         { $ResourceRecord = ReadKSDnsWKSRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::PTR)         { $ResourceRecord = ReadKSDnsPTRRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::HINFO)       { $ResourceRecord = ReadKSDnsHINFORecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MINFO)       { $ResourceRecord = ReadKSDnsMINFORecord @Params; break }
    ([KScript.DnsResolver.RecordType]::MX)          { $ResourceRecord = ReadKSDnsMXRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::TXT)         { $ResourceRecord = ReadKSDnsTXTRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::RP)          { $ResourceRecord = ReadKSDnsRPRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::AFSDB)       { $ResourceRecord = ReadKSDnsAFSDBRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::X25)         { $ResourceRecord = ReadKSDnsX25Record @Params; break }
    ([KScript.DnsResolver.RecordType]::ISDN)        { $ResourceRecord = ReadKSDnsISDNRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::RT)          { $ResourceRecord = ReadKSDnsRTRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NSAP)        { $ResourceRecord = ReadKSDnsNSAPRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NSAPPTR)     { $ResourceRecord = ReadDnsNSAPPTRRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::SIG)         { $ResourceRecord = ReadKSDnsSIGRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::KEY)         { $ResourceRecord = ReadKSDnsKEYRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::PX)          { $ResourceRecord = ReadKSDnsPXRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::GPOS)        { $ResourceRecord = ReadKSDnsGPOSRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::AAAA)        { $ResourceRecord = ReadKSDnsAAAARecord @Params; break }
    ([KScript.DnsResolver.RecordType]::LOC)         { $ResourceRecord = ReadKSDnsLOCRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NXT)         { $ResourceRecord = ReadKSDnsNXTRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::EID)         { $ResourceRecord = ReadKSDnsEIDRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NIMLOC)      { $ResourceRecord = ReadKSDnsNIMLOCRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::SRV)         { $ResourceRecord = ReadKSDnsSRVRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::ATMA)        { $ResourceRecord = ReadKSDnsATMARecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NAPTR)       { $ResourceRecord = ReadKSDnsNAPTRRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::KX)          { $ResourceRecord = ReadKSDnsKXRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::CERT)        { $ResourceRecord = ReadKSDnsCERTRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::A6)          { $ResourceRecord = ReadKSDnsA6Record @Params; break }
    ([KScript.DnsResolver.RecordType]::DNAME)       { $ResourceRecord = ReadKSDnsDNAMERecord @Params; break }
    ([KScript.DnsResolver.RecordType]::SINK)        { $ResourceRecord = ReadKSDnsSINKRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::OPT)         { $ResourceRecord = ReadKSDnsOPTRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::APL)         { $ResourceRecord = ReadKSDnsAPLRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::DS)          { $ResourceRecord = ReadKSDnsDSRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::SSHFP)       { $ResourceRecord = ReadDnsSSHFPRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::IPSECKEY)    { $ResourceRecord = ReadKSDnsIPSECKEYRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::RRSIG)       { $ResourceRecord = ReadKSDnsRRSIGRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NSEC)        { $ResourceRecord = ReadKSDnsNSECRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::DNSKEY)      { $ResourceRecord = ReadKSDnsDNSKEYRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::DHCID)       { $ResourceRecord = ReadKSDnsDHCIDRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NSEC3)       { $ResourceRecord = ReadKSDnsNSEC3Record @Params; break }
    ([KScript.DnsResolver.RecordType]::NSEC3PARAM)  { $ResourceRecord = ReadKSDnsNSEC3PARAMRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::HIP)         { $ResourceRecord = ReadKSDnsHIPRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::NINFO)       { $ResourceRecord = ReadKSDnsNINFORecord @Params; break }
    ([KScript.DnsResolver.RecordType]::RKEY)        { $ResourceRecord = ReadKSDnsRKEYRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::SPF)         { $ResourceRecord = ReadKSDnsSPFRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::TKEY)        { $ResourceRecord = ReadKSDnsTKEYRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::TSIG)        { $ResourceRecord = ReadKSDnsTSIGRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::TA)          { $ResourceRecord = ReadKSDnsTARecord @Params; break }
    ([KScript.DnsResolver.RecordType]::DLV)         { $ResourceRecord = ReadKSDnsDLVRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::WINS)        { $ResourceRecord = ReadKSDnsWINSRecord @Params; break }
    ([KScript.DnsResolver.RecordType]::WINSR)       { $ResourceRecord = ReadKSDnsWINSRRecord @Params; break }
    default                                         { ReadKSDnsUnknownRecord @Params }
  }
  
  return $ResourceRecord
}

