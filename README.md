compute-demo-puppet
========================

This is the supporting documentation for **Using Puppet with Google
Compute Engine** 

The goal of this repository is to provide the extra detail necessary for
you to completely replicate the recorded demo. The video's main goal
is to show a quick, fully working demo without bogging you down with all
of the required details so you can easily see the "Good Stuff".

At the end of the demo, you will have used Puppet to automate:
* Creating 4 Compute Engine instances
* Install the Apache web server on each
* Allow HTTP traffic to the instances with a custom firewall rule
* Create a Compute Engine Load-balancer to distribute traffic over the 4 instances
* Do a live test of the full configuration

This is intended to be a fairly trival example.  And, this can be
the foundational tools for building more real-world configurations.

## Google Cloud Platform Project

1. You will need to create a Google Cloud Platform Project as a first step.
Make sure you are logged in to your Google Account (gmail, Google+, etc) and
point your browser to https://console.developers.google.com/. You should see a
page asking you to create your first Project.

2. When creating a Project, you will see a pop-up dialog box. You can specify
custom names but the *Project ID* is globally unique across all Google Cloud
Platform customers.

3. It's OK to create a Project first, but you will need to set up billing
before you can create any virtual machines with Compute Engine. Look for the
*Billing* link in the left-hand navigation bar.


4. Next you will want to install the [Cloud SDK](https://developers.google.com/cloud/sdk/)
and make sure you've successfully authenticated and set your default project
as instructed.

## Create the Puppet master Compute Engine instance

Next you will create a Virtual Machine for your Puppet master named `master` so
that your managed nodes (or agents) will be able to automatcially find the
master.

You can create the master in the
[Developers Console](https://console.developers.google.com/)  under the
*Compute Engine -&gt; VM Instances* section and then click the *NEW INSTANCE*
button.

Or, you can create the Puppet master with the `gcutil` command-line
utility (part of the Cloud SDK) with the following command:

```
# Make sure to use a Debian-7-wheezy image for this demo
gcutil addinstance master --image=debian-7 --zone=us-central1-b --machine_type=n1-standard-1
```

## Software

1. SSH to your Puppet master and then become root
    ```
    gcutil ssh master
    sudo -i
    ```

2. Update packages and install puppet and gce_compute
    ```
    wget https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb
    dpkg -i puppetlabs-release-wheezy.deb
    apt-get update
    apt-get install puppetmaster
    puppet module install puppetlabs-gce_compute
    ```


## Puppet-Cloud setup

1. Configure the Puppet Master service for autosigning
  `echo "*.$(hostname --domain)" | sudo tee /etc/puppet/autosign.conf`
2. Create a site manifest file to specify instance software and services(`/etc/puppet/manifests/site.pp`). 
  ```
  class apache ($version = "latest") {
  	package {"apache2":
		  ensure => $version,
	  }
	  file {"/var/www/index.html":
		  ensure	=> present,
		  content	=> "<html>\n<body>\n\t<h2>Hi, this is $hostname.</h2>\n</body>\n</html>\n",
		  require	=> Package["apache2"],
	  }
	  service {"apache2":
		  ensure => running,
		  enable => true,
		  require => File["/var/www/index.html"],
	  }
  }

  node /^demo-puppet-child-\d+\.c.upbeat-airway-600\.internal/ {
	  include apache
  }
  ```
3. Set up `device.conf`.
  ```
  PROJECT=$(/usr/share/google/get_metadata_value project-id)

  cat > ~/.puppet/device.conf << EOF
  [my_project]
  type gce
  url [/dev/null]:${PROJECT}
  EOF
  ```
  'my_project' can be substituted with a name of your choice as long as it is used consistently.
4. Create a manifest file in the same directory as the `site.pp` file (`/etc/puppet/manifests/gce_www_up.pp`) to create the 4 Compute Engine instatnces, firewall, and load balancer.
  ```
  $master = $fqdn
  $zonea = 'us-central1-a'
  $zoneb = 'us-central1-b'

  gce_firewall { 'allow-http':
	  ensure			=> present,
	  description		=> 'Allow HTTP',
	  network			=> 'default',
	  allowed			=> 'tcp:80',
	  allowed_ip_sources	=> '0.0.0.0/0',
  }
  
  gce_httphealthcheck { 'basic-http':
	  ensure		=> present,
	  require		=> Gce_instance['demo-puppet-child-1', 'demo-puppet-child-2', 'demo-puppet-child-3', 'demo-puppet-child-3'],
	  description	=> 'basic http health check',
  }

  gce_targetpool { 'www-pool':
	  ensure		=> present,
	  require		=> Gce_httphealthcheck['basic-http'],
	  health_checks	=> 'basic-http',
	  instances	=> "$zonea/demo-puppet-child-1,$zonea/demo-puppet-child-2,$zoneb/demo-puppet-child-3,$zoneb/demo-puppet-child-4",
	  region		=> 'us-central1',
  }

  gce_forwardingrule { 'www-rule':
	  ensure		=> present,
	  require		=> Gce_targetpool['www-pool'],
	  description	=> 'Forward HTTP to web instances',
	  port_range	=> '80',
	  region		=> 'us-central1',
	  target		=> 'www-pool',
  }

  gce_disk { 'demo-puppet-child-1':
	  ensure		=> present,
	  description	=> 'Boot disk for puppet-child-www',
	  size_gb		=> 10,
	  zone		=> "$zonea",
	  source_image	=> 'debian-7',
  }

  gce_instance { 'demo-puppet-child-1':
	  ensure		=> present,
	  description	=> 'Basic web node',
	  machine_type	=> 'n1-standard-1',
  	zone		=> "$zonea",
	  disk		=> 'demo-puppet-child-1,boot',
	  network		=> 'default',

  	require		=> Gce_disk['demo-puppet-child-1'],
  
	  puppet_master 	=> "$master",
	  puppet_service	=> present,
  }

  gce_disk { 'demo-puppet-child-2':
	  ensure		=> present,
  	description	=> 'Boot disk for puppet-child-www',
	  size_gb		=> 10,
  	zone		=> "$zonea",
	  source_image	=> 'debian-7',
  }

  gce_instance { 'demo-puppet-child-2':
	  ensure		=> present,
	  description	=> 'Basic web node',
	  machine_type	=> 'n1-standard-1',
	  zone		=> "$zonea",
	  disk		=> 'demo-puppet-child-2,boot',
	  network		=> 'default',
  
	  require		=> Gce_disk['demo-puppet-child-2'],
  
	  puppet_master 	=> "$master",
  	puppet_service	=> present,
  }

  gce_disk { 'demo-puppet-child-3':
	  ensure		=> present,
	  description	=> 'Boot disk for puppet-child-www',
	  size_gb		=> 10,
	  zone		=> "$zoneb",
	  source_image	=> 'debian-7',
  }

  gce_instance { 'demo-puppet-child-3':
	  ensure		=> present,
	  description	=> 'Basic web node',
	  machine_type	=> 'n1-standard-1',
	  zone		=> "$zoneb",
	  disk		=> 'demo-puppet-child-3,boot',
	  network		=> 'default',

	  require		=> Gce_disk['demo-puppet-child-3'],

	  puppet_master 	=> "$master",
	  puppet_service	=> present,
  }

  gce_disk { 'demo-puppet-child-4':
	  ensure		=> present,
	  description	=> 'Boot disk for puppet-child-www',
	  size_gb		=> 10,
	  zone		=> "$zoneb",
	  source_image	=> 'debian-7',
  }

  gce_instance { 'demo-puppet-child-4':
	  ensure		=> present,
	  description	=> 'Basic web node',
	  machine_type	=> 'n1-standard-1',
	  zone		=> "$zoneb",
	  disk		=> 'demo-puppet-child-4,boot',
	  network		=> 'default',

	  require		=> Gce_disk['demo-puppet-child-4'],

	  puppet_master 	=> "$master",
	  puppet_service	=> present,
  }
  ```
  * Firewall rule is created in this file with the `gce_firewall` hash.
  * Each of the four instances are created in the `gce_instance` hashes with the instance names as the key. A disc is created for each instance in `gce_disk` hashes.
  * The load balancer is created with the `gce_targetpool`, `gce_httphealthcheck`, and `gce_forwardingrule` hashes.
5. Apply the `gce_www_up.pp` manifest file.
`puppet apply --certname=my_project gce_www_up.pp`
6. To modify any instance or resource, change the manifest file and apply it again.
7. Now, if you like, you can put the public IP address of the load balancer
into your browser and you should start to see a flicker of pages that will randomly bounce across each of your
instances.


## Cleaning up

When you're done with the demo, make sure to tear down all of your
instances and clean-up. You will get charged for this usage and you will
accumulate additional charges if you do not remove these resources.

To delete a resource, open the manifest file used to create them and change the `ensure` key of the resource you would like to delete to point to `absent`. To delete and instance, the `ensure` key of the corresponding disc must also be changed. 

## Troubleshooting


## Contributing

Have a patch that will benefit this project? Awesome! Follow these steps to have it accepted.

1. Please sign our [Contributor License Agreement](CONTRIB.md).
1. Fork this Git repository and make your changes.
1. Run the unit tests. (gcimagebundle only)
1. Create a Pull Request
1. Incorporate review feedback to your changes.
1. Accepted!

## License
All files in this repository are under the
[Apache License, Version 2.0](LICENSE) unless noted otherwise.
