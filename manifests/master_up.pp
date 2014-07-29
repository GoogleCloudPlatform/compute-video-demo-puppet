gce_instance { "puppet-enterprise-master":
    ensure       => present,
    description  => 'A PE Master, Console and PuppetDB',
    machine_type => 'n1-standard-1',
    zone         => 'us-central1-a',
    network      => 'default',
    image        => 'projects/centos-cloud/global/images/centos-6-v20131120',
    tags         => ['puppet', 'master'],
    startupscript        => 'puppet-enterprise.sh',
    metadata             => {
      'pe_role'          => 'master',
      'pe_version'       => '3.3.0',
      'pe_consoleadmin'  => 'admin@example.com',
      'pe_consolepwd'    => 'puppetenterprise',
    },
    modules      => ['puppetlabs-apache', 'puppetlabs-firewall', 'puppetlabs-stdlib', 'puppetlabs-vcsrepo', 'puppetlabs-gce_compute'],
    manifest     => $manifest,
}

gce_firewall { 'allow-puppet-master':
    ensure      => present,
    network     => 'default',
    description => 'allows incoming 8140 connections',
    allowed     => 'tcp:8140',
}
