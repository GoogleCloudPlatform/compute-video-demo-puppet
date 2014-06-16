$zonea = 'us-central1-a'
$zoneb = 'us-central1-b'
$region = 'us-central1'

gce_firewall { 'puppet-firewall':
	ensure			=> present,
	description		=> 'Allow HTTP',
	network			=> 'default',
	allowed			=> 'tcp:80',
	allowed_ip_sources	=> '0.0.0.0/0',
}

#Declare load balancer and other resources required by the load balancer
gce_httphealthcheck { 'puppet-http':
	ensure		=> present,
	require		=> Gce_instance['puppet-agent-1', 'puppet-agent-2', 'puppet-agent-3', 'puppet-agent-3'],
	description	=> 'basic http health check',
}

gce_targetpool { 'puppet-pool':
	ensure		=> present,
	require		=> Gce_httphealthcheck['puppet-http'],
	health_checks	=> 'puppet-http',
	instances	=> "$zonea/puppet-agent-1,$zonea/puppet-agent-2,$zoneb/puppet-agent-3,$zoneb/puppet-agent-4",
	region		=> "$region",
}

gce_forwardingrule { 'puppet-rule':
	ensure		=> present,
	require		=> Gce_targetpool['puppet-pool'],
	description	=> 'Forward HTTP to web instances',
	port_range	=> '80',
	region		=> "$region",
	target		=> 'puppet-pool',
}

#create 4 nodes in 2 different zones
gce_disk { 'puppet-agent-1':
	ensure		=> present,
	description	=> 'Boot disk for puppet-agent-1',
	size_gb		=> 10,
	zone		=> "$zonea",
	source_image	=> 'debian-7',
}

gce_instance { 'puppet-agent-1':
	ensure		=> present,
	description	=> 'Basic web node',
	machine_type	=> 'n1-standard-1',
	zone		=> "$zonea",
	disk		=> 'puppet-agent-1,boot',
	network		=> 'default',

	require		=> Gce_disk['puppet-agent-1'],

	puppet_master 	=> "$fqdn",
	puppet_service	=> present,
}

gce_disk { 'puppet-agent-2':
	ensure		=> present,
	description	=> 'Boot disk for puppet-agent-2',
	size_gb		=> 10,
	zone		=> "$zonea",
	source_image	=> 'debian-7',
}

gce_instance { 'puppet-agent-2':
	ensure		=> present,
	description	=> 'Basic web node',
	machine_type	=> 'n1-standard-1',
	zone		=> "$zonea",
	disk		=> 'puppet-agent-2,boot',
	network		=> 'default',

	require		=> Gce_disk['puppet-agent-2'],

	puppet_master 	=> "$fqdn",
	puppet_service	=> present,
}

gce_disk { 'puppet-agent-3':
	ensure		=> present,
	description	=> 'Boot disk for puppet-agent-3',
	size_gb		=> 10,
	zone		=> "$zoneb",
	source_image	=> 'debian-7',
}

gce_instance { 'puppet-agent-3':
	ensure		=> present,
	description	=> 'Basic web node',
	machine_type	=> 'n1-standard-1',
	zone		=> "$zoneb",
	disk		=> 'puppet-agent-3,boot',
	network		=> 'default',

	require		=> Gce_disk['puppet-agent-3'],

	puppet_master 	=> "$fqdn",
	puppet_service	=> present,
}
gce_disk { 'puppet-agent-4':
	ensure		=> present,
	description	=> 'Boot disk for puppet-agent-4',
	size_gb		=> 10,
	zone		=> "$zoneb",
	source_image	=> 'debian-7',
}

gce_instance { 'puppet-agent-4':
	ensure		=> present,
	description	=> 'Basic web node',
	machine_type	=> 'n1-standard-1',
	zone		=> "$zoneb",
	disk		=> 'puppet-agent-4,boot',
	network		=> 'default',

	require		=> Gce_disk['puppet-agent-4'],

	puppet_master 	=> "$fqdn",
	puppet_service	=> present,
}
