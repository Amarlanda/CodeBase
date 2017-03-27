New-KSEnum -ModuleBuilder $Script:ADModuleBuilder -Name "KScript.AD.IADSControlCode" -Type "Int32" -Members @{
  Clear  = 1    # Instructs the directory service to remove all the property value(s) from the object.
  Update = 2    # Instructs the directory service to replace the current value(s) with the specified value(s).
  Append = 3    # Instructs the directory service to append the specified value(s) to the existing values(s).
                #
                # When the ADS_PROPERTY_APPEND operation is specified, the new attribute value(s) are automatically committed to the directory service and removed from 
                # the local cache. This forces the local cache to be updated from the directory service the next time the attribute value(s) are retrieved.
  Delete = 4    # Instructs the directory service to delete the specified value(s) from the object.
}