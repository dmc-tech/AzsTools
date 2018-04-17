#requires -Version 4.0
#requires -Modules AzureRM.Profile, AzureRM.AzureStackAdmin

<#
    Updated Connect module, removing requiremnt for VPNClient so can use in Server Core 2016
#>
<#
    .SYNOPSIS
    Connecting to your environment requires that you obtain the value of your Directory Tenant ID. 
    For **Azure Active Directory** environments provide your directory tenant name.
#>

function Get-AzsDirectoryTenantId () {
    [CmdletBinding(DefaultParameterSetName = 'AzureActiveDirectory')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ADFS')]
        [switch] $ADFS,

        [parameter(mandatory = $true, ParameterSetName = 'AzureActiveDirectory', HelpMessage = "AAD Directory Tenant <myaadtenant.onmicrosoft.com>")]
        [string] $AADTenantName,

        [Parameter(Mandatory = $true, ParameterSetName = 'ADFS')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AzureActiveDirectory')]
        [string] $EnvironmentName
    )
    
    $ADauth = (Get-AzureRmEnvironment -Name $EnvironmentName).ActiveDirectoryAuthority
    if ($ADFS -eq $true) {
        if (-not (Get-AzureRmEnvironment -Name $EnvironmentName).EnableAdfsAuthentication) {
            Write-Error "This environment is not configured to do ADFS authentication." -ErrorAction Stop
        }
        return $(Invoke-RestMethod $("{0}/.well-known/openid-configuration" -f $ADauth.TrimEnd('/'))).issuer.TrimEnd('/').Split('/')[-1]
    }
    else {
        $endpt = "{0}{1}/.well-known/openid-configuration" -f $ADauth, $AADTenantName
        $OauthMetadata = (Invoke-WebRequest -UseBasicParsing $endpt).Content | ConvertFrom-Json
        $AADid = $OauthMetadata.Issuer.Split('/')[3]
        $AADid
    }
} 

Export-ModuleMember Get-AzsDirectoryTenantId