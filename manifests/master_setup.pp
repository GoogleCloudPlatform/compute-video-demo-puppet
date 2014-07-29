$project = ''

package { 'git':
  ensure => present,
}

vcsrepo { "/home/${id}/compute-video-demo-puppet":
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
  source => "/home/${id}/compute-video-demo-puppet/manifests/site.pp",
}

firewall { '100 allow 443 and 8140':
  port   => [8140, 443],
  proto  => tcp,
  action => accept,
}
