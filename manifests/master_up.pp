gce_instance { "ash-puppet-enterprise-master":
    ensure       => present,
    description  => 'A PE Master, Console and PuppetDB',
    machine_type => 'n1-standard-1',
    zone         => 'us-central1-a',
    network      => 'default',
    require      => Gce_disk['ash-puppet-enterprise-master'],
    disk         => 'ash-puppet-enterprise-master',
    tags         => ['puppet', 'master'],
    startupscript        => 'puppet-enterprise.sh',
    metadata             => {
      'pe_role'          => 'master',
      'pe_version'       => '3.3.0',
      'pe_consoleadmin'  => 'admin@example.com',
      'pe_consolepwd'    => 'puppetenterprise',
    },
    modules      => ['puppetlabs-apache', 'puppetlabs-firewall', 'puppetlabs-stdlib', 'puppetlabs-vcsrepo', 'puppetlabs-gce_compute'],
    manifest     => '
      class puppet-enterprise-master {
        package { "git":
          ensure  => present,
        }

        vcsrepo { "/opt/compute-video-demo-puppet":
          ensure    => present,
          provider  => git,
          source    => "https://github.com/GoogleCloudPlatform/compute-video-demo-puppet.git",
          require   => Package["git"],
        }
      }

      include puppet-enterprise-master'
}

gce_disk { "ash-puppet-enterprise-master":
  ensure        => present,
  source_image  => 'centos-6',
  zone          => 'us-central1-a',
  size_gb       => 10,
}

gce_firewall { 'allow-puppet-master':
    ensure      => present,
    network     => 'default',
    description => 'allows incoming 8140 connections',
    allowed     => 'tcp:8140',
}
