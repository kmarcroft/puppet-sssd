# @summary Joins the system to an Active Directory domain
#
# Installs required packages and uses adcli to join the AD domain.
# AD join credentials are expected to be provided via Hiera (password via eyaml).
#
class sssd::join {
  $base_authentication_packages = $facts['os']['family'] ? {
    'Debian' => ['sssd-tools', 'adcli', 'packagekit', 'krb5-user'],
    'RedHat' => ['sssd-tools', 'adcli', 'PackageKit', 'krb5-workstation'],
    default  => ['sssd-tools', 'adcli', 'PackageKit'],
  }

  # Lookup AD join parameters from Hiera (password from eyaml)
  $ad_pass   = Sensitive(lookup('sssd::join::ad_pass', String))
  $ad_ou     = lookup('sssd::join::ad_ou', String)
  $ad_user   = lookup('sssd::join::ad_user', String)
  $ad_domain = lookup('sssd::join::ad_domain', String)

  $ad_pass_value = $ad_pass.unwrap

  package { $base_authentication_packages:
    ensure => installed,
  }

  -> exec { 'join_domain':
    path    => '/usr/bin:/usr/sbin:/bin:/sbin',
    command => Sensitive("echo -n '${ad_pass_value}' | adcli join --verbose -O '${ad_ou}' -U '${ad_user}' --stdin-password '${ad_domain}'"),
    unless  => '/usr/bin/klist -k /etc/krb5.keytab > /dev/null 2>&1 && /usr/sbin/adcli testjoin',
  }
}
