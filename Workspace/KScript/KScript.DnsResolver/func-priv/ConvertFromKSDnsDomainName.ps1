function ConvertFromKSDnsDomainName {
  # .SYNOPSIS
  #   Converts a DNS domain name from a string to a byte array.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   RFC 1034:
  #
  #   "Internally, programs that manipulate domain names should represent them
  #    as sequences of labels, where each label is a length octet followed by
  #    an octet string.  Because all domain names end at the root, which has a
  #    null string for a label, these internal representations can use a length
  #    byte of zero to terminate a domain name."
  #
  #   RFC 1035:
  #
  #   "<domain-name> is a domain name represented as a series of labels, and
  #    terminated by a label with zero length.  <character-string> is a single
  #    length octet followed by that number of characters.  <character-string>
  #    is treated as binary information, and can be up to 256 characters in
  #    length (including the length octet)."
  #
  # .PARAMETER Name
  #   The name to convert to a byte array.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Byte[]
  # .LINK
  #   http://www.ietf.org/rfc/rfc1034.txt
  #   http://www.ietf.org/rfc/rfc1035.txt

  [CmdLetBinding()]
  param(
    [String]$Name
  )

  # Drop any trailing . characters from the name. They are no longer necessary all names must be absolute by this point.
  $Name = $Name.TrimEnd('.')

  $Bytes = @()
  if ($Name) {
    $Bytes += $Name -split '\.' | ForEach-Object {
      $_.Length
      "$_" | ConvertTo-KSByte
    }
  }
  # Add a zero length root label
  $Bytes += [Byte]0

  return [Byte[]]$Bytes
}

