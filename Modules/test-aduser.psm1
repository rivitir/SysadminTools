<#

  Function to check AD to see if a user exists in AD and provide a boolean value.
  Written by Stackoverflow user James C.
  https://stackoverflow.com/questions/48813700/how-to-check-if-an-ad-user-exists

#>

Function Test-ADUser {  
    [CmdletBinding()]  
   param(  
     [parameter(Mandatory=$true,position=0)]  
     [string]$Username  
     )  
      Try {  
        Get-ADuser $Username -ErrorAction Stop  
        return $true  
        }   
     Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {  
         return $false  
         }  
 }   
