# Copyright (c) 2019 Ansible Project
# Simplified BSD License (see licenses/simplified_bsd.txt or https://opensource.org/licenses/BSD-2-Clause)

Function Load-ActiveDirectory-Module {
    <#
    .SYNOPSIS
    Load the ActiveDirectory PowerShell Module

    .DESCRIPTION
    It tries to load the ActiveDirectory PowerShell Module and fail gracefully.

    .PARAMETER Module
    The AnsibleBasic module that can be used as to fail gracefully.

    .EXAMPLE
    Load-ActiveDirectory-Module -Module $module
    #>
    [CmdletBinding()]
    Param (
        [ValidateScript({ $_.GetType().FullName -eq 'Ansible.Basic.AnsibleModule' })]
        [System.Object]
        $Module
    )

    if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
      $module.FailJson("ActiveDirectory PS module to be installed")
    }
    Import-Module ActiveDirectory
}

Function Get-WinDomainConnectionArgs {
    <#
    .SYNOPSIS
    Returns the connections argument Hashtable.

    .DESCRIPTION
    Returns the connections arguments raccording to the AnsibleModule parameters as a Hashtable which can be passed to PowerShell functions from the ActiveDirectory Module.

    .PARAMETER Module
    The Ansible.Basic module to read the parameters from.

    .EXAMPLE Basic module example
    $spec = @{
        options = @{
        }
    }
    $spec.options += $ansible_win_domain_options
    $module = Ansible.Basic.AnsibleModule]::Create($args, $spec)

    $extra_args = Get-WinDomainConnectionArgs -Module $module

    $user = Ad-GetUser -Identity alice @extra_args
    #>
    [CmdletBinding()]
    [OutputType(Hashtable)]
    param (
        [Parameter(Mandatory=$true)]
        [System.Object]
        [ValidateScript({ $_.GetType().FullName -eq 'Ansible.Basic.AnsibleModule' })]
        $Module,
    )

    $connection_args = @{}
    if ($null -ne $Module.Params.domain_username) {
        $domain_password = ConvertTo-SecureString $Module.Params.domain_password -AsPlainText -Force
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Module.Params.domain_username, $domain_password
        $connection_args.Credential = $credential
    }
    if ($null -ne $Module.Params.domain_server) {
        $connection_args.Server = $Module.Params.domain_server
    }

    $doamin = Get-ADDomain @extra_args

    $domain_info = @{
      name=$domain.Name
      dns=$domain.DNSRoot
      dn=$domain.DistinguishedName
    }

    $Module.Result.domain = $domain_info

    return $connection_args
}

$ansible_win_domain_options = @{
    domain_username = @{ type = "str" }
    domain_password = @{ type = "str"; no_log=$true }
    domain_server = @{ type = "str" }
}

$export_members = @{
    Function = "Load-ActiveDirectory-Module", "Get-WinDomainAuthArgs"
    Variable = "ansible_win_domain_options"
}
Export-ModuleMember @export_members
