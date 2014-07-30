package { 'git':
  ensure => present,
}

vcsrepo { '/opt/compute-video-demo-puppet':
  ensure   => present,
  provider => git,
  source   => 'https://github.com/GoogleCloudPlatform/compute-video-demo-puppet.git',
  require  => Package['git'],
}

file { '/etc/puppetlabs/puppet/autosign.conf':
  ensure  => file,
  content => "*.${domain}",
}

file { '/etc/puppetlabs/puppet/manifests/site.pp':
  ensure => file,
  content => "node /^puppet-agent-\\d+/ {
    class { 'apache': }

    include apache::mod::headers

    file {'/var/www/index.html':
      ensure	=> present,
      content	=> template('/opt/compute-video-demo-puppet/index.html.erb'),
      require	=> Class['apache'],
    }
  }"
}

firewall { '100 allow 443 and 8140':
  port   => [8140, 443],
  proto  => tcp,
  action => accept,
}
