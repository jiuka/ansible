#!powershell

# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Module Ansible.ModuleUtils.Domain

$spec = @{
    options = @{
				name = @{ type = "str"; required=$true; aliases=@("user") }
    }
    supports_check_mode = $true
}
$spec.options += $ansible_win_domain_options
$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Load-ActiveDirectory-Module -Module $module
$extra_args = Get-WinDomainConnectionArgs -Module $module

try {
		$group $Get-ADGroup -Identity $name -Properties * @extra_args

		$module.Result.name = $group.Name
		$module.Result.state = 'present'
		$module.Result.group = $group
} catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
		$module.Result.name = $name
	  $module.Result.state = 'absent'
} catch {
	  $module.FailJson("Failed to retrieve details for group $($name): $($_.Exception.Message)", $_)
}

$module.ExitJson()
