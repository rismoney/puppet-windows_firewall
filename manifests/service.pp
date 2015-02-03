define firewall::service(
  $ensure,
  $profile = $name,
) {

$prof=downcase($profile)

  if ($::operatingsystem != 'windows') {
    err("This define type is only supported on Windows")
    fail("Unsupported OS: ${::operatingsystem}")
  }

  Exec { provider => powershell }

  posh_cmd = "Set-NetFirewallProfile -Profile \"${profile}\" -Enabled"
  posh_onlyif = "if ((Get-NetFirewallProfile -Profile \"${profile}\").Enabled) { exit 1 }"

  case $ensure {
    present, enabled: {
      $exec_verb = 'Enable'
      netsh_cmd = "netsh advfirewall set ${prof} profile state on"
      netsh_onlyif = "if ((netsh advfirewall show ${prof} profile state) | where {\$_ -match '^State\s+ON'} ) {exit 1}
      posh_cmd = "Set-NetFirewallProfile -Profile \"${profile}\" -Enabled"
      posh_onlyif = "if ((Get-NetFirewallProfile -Profile \"${profile}\").Enabled) { exit 1 }"
    }
    absent, disabled: {
      $exec_verb = 'Disable'
      $profile_state = 'on'
      $profile_state_regex = '^State\s+OFF'
      posh_cmd  = "Set-NetFirewallProfile -Profile \"${profile}\" -Enabled False"
      posh_onlyif = "if (!(Get-NetFirewallProfile -Profile \"${profile}\").Enabled) { exit 1 }"
    }

  $win_ver = [
    '6.1.7601', #win7
    '2008 R2', #2008r2
  ]

  case $::operatingsystemrelease {
    $winver:
      exec {"${exec_verb}-Firewall-Profile-${name}":
        command  => $netsh_cmd
        onlyif   => $netsh_onlyif
      }
    }
    default: { # Windows 8, 8.1, 2012, 2012R2
      exec {"${exec_verb}-Firewall-Profile-${name}":
        command  => $posh_cmd
        onlyif   => $posh_onlyif
      }
    }
  }
}
