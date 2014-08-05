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
* Create a Compute Engine Load-balancer to send traffic over the 4 instances
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


4. Next you will want to install the
[Cloud SDK](https://developers.google.com/cloud/sdk/) and make sure you've
successfully authenticated and set your default project as instructed.


## Quick Start with Puppet Enterprise

These instructions assume you have installed and configured the Google Cloud
SDK from the previous step. They also assume you have installed
a [Puppet](http://docs.puppetlabs.com/guides/install_puppet/pre_install.html) or
[Puppet Enterprise](http://docs.puppetlabs.com/pe/latest/install_agents.html)
Agent.

Though Puppet Enterprise is free to use for this demo, you may skip this section
to use instructions for an [open-source Puppet Master](#create-the-puppet-master-foss-compute-engine-instance).

1. Install the Google Compute Engine Puppet module
    ```
    puppet module install puppetlabs-gce_compute
    ```

2. Bring up a GCE instance that will auto-install the PE Master
    ```
    puppet apply compute-video-demo-puppet/manifests/master_up.pp --certname myproject
    ```

   The install may take up to ten minutes but the instance should be up within a
   minute or two. You can SSH into it...

   ```
   gcutil ssh puppet-enterprise-master
   ```

   and tail the log until it's finished.

   ```
   sudo tail -f /var/log/messages
   ```

   When finished, you'll see a line like this in your log.

   ```
   puppet-enterprise-master startupscript: Puppet installation finished!
   ```
   
3. Fetch the setup manifest from the metadata server
 
    ```
    curl http://metadata/computeMetadata/v1/instance/attributes/setup -H 'Metadata-Flavor: Google' > master_setup.pp
    ```

4. Use Puppet to setup the demo

    ```
    sudo /opt/puppet/bin/puppet apply master_setup.pp
    ```

   This setup manifest will prepare your Puppet master for the demo and will clone
   the demo repository into /opt for convenience.

6. Authenticate the root user on your puppet master with Compute Engine.

    ```
    sudo env PATH=$PATH gcloud auth login
    ```

7. Set up `/etc/puppetlabs/puppet/device.conf` which the gce_compute module references
for your Google Cloud project-id.

    ```
    CERTNAME=$(/usr/local/bin/puppet config print certname)
    PROJECT=$(/usr/share/google/get_metadata_value project-id)
    sudo bash -c "cat > /etc/puppetlabs/puppet/device.conf" <<EOF
[$CERTNAME]
  type gce
  url [/dev/null]:$PROJECT
EOF
    ```

    You can also create a link so that device.conf is available as root or as the
    local user.

       ```
       mkdir ~/.puppet; ln -s /etc/puppetlabs/puppet/device.conf ~/.puppet/device.conf
       ```


8. Use Puppet to build the additional instances and agents.

    ```
    sudo env PATH=$PATH /opt/puppet/bin/puppet apply --modulepath=/etc/puppetlabs/puppet/modules /opt/compute-video-demo-puppet/manifests/puppet_up.pp --certname $CERTNAME
    ```

9. Now, you can put the public IP address of the load balancer into your
browser and you should start to see a flicker of pages that will bounce across
each of your instances. You can find your load-balancer IP in the Developers
Console or with,
    ```
    gcutil getforwardingrule puppet-rule --region us-central1
    ```
    Note: You may have to authenticate your regular user with Compute Engine as well by using the ```gcloud compute auth login``` command.


## Create the Puppet Master (FOSS) Compute Engine Instance

Next you will create a Virtual Machine for your Puppet master named `master`
so that your managed nodes (or agents) will be able to automatcially find the
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

1. SSH to your Puppet master
    ```
    gcutil ssh master
    ```

2. Update packages and install puppet, gce_compute, and apache. It is
important to install these packages and modules as root.
    ```
    wget https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb
    sudo dpkg -i puppetlabs-release-wheezy.deb
    sudo apt-get update
    sudo apt-get install puppetmaster
    sudo puppet module install puppetlabs-gce_compute
    sudo puppet module install puppetlabs-apache
    ```
3. Authenticate the root user on your puppet master with Compute Engine,
    ```
    sudo gcloud auth login
    ```

4. Check out this repository so that you can use pre-canned configuration
and demo files.
    ```
    cd $HOME
    git clone https://github.com/GoogleCloudPlatform/compute-video-demo-puppet
    ```

## Puppet Setup

You can watch a simple terminal screencast, https://asciinema.org/a/10310, of
the below configuration and demo. The screencast is useful for showing the
expected output from the commands listed below.

1. Configure the Puppet Master service for autosigning,
    ```
    echo "*.$(hostname --domain)" | sudo tee /etc/puppet/autosign.conf
    ```

2. Create a site manifest file to specify instance software and services. For
this demo, a simple Apache site manifest is being defined.  The below contents
should be used to create `/etc/puppet/manifests/site.pp`.
    ```
    node /^puppet-agent-\d+/ { # Regex to match node names like puppet-agent-N
      class { 'apache': }      # Installs apache web server

      include apache::mod::headers

      file {"/var/www/index.html":    # Include a custom index.html
        ensure    => present,
        content    => template("apache/index.html.erb"),
        require    => Class["apache"],
      }
    }
    ```
  Or, you can use the site.pp included in the repo and copy it with,
    ```
    sudo cp compute-video-demo-puppet/manifests/site.pp /etc/puppet/manifests/site.pp
    ```
  * This example uses the puppetlabs-apache module to install and manage the
    apache service. More information about this module can be found at
    https://github.com/puppetlabs/puppetlabs-apache.

3. Set up `/etc/puppet/device.conf` where the project ID can either be found
on the Developer's Console or by using these commands,

    ```
    CERTNAME=$(puppet config print certname)
    PROJECT=$(/usr/share/google/get_metadata_value project-id)
    sudo bash -c "cat > /etc/puppet/device.conf" <<EOF
    [$CERTNAME]
      type gce
      url [/dev/null]:$PROJECT
    EOF
    ```

1. Create another manifest file (`/etc/puppet/manifests/puppet_up.pp`) used to
create the 4 Compute Engine instances, firewall, and load balancer.
    ```
    $zonea = 'us-central1-a'
    $zoneb = 'us-central1-b'
    $region = 'us-central1'

    gce_firewall { 'puppet-firewall':
      ensure => present,
      description => 'Allow HTTP',
      network => 'default',
      allowed => 'tcp:80',
      allowed_ip_sources => '0.0.0.0/0',
    }

    # Declare load balancer and other resources required by the load balancer
    gce_httphealthcheck { 'puppet-http':
      ensure => present,
      require => Gce_instance['puppet-agent-1', 'puppet-agent-2', 'puppet-agent-3', 'puppet-agent-4'],
      description => 'basic http health check',
    }

    gce_targetpool { 'puppet-pool':
      ensure => present,
      require => Gce_httphealthcheck['puppet-http'],
      health_checks => 'puppet-http',
      instances => "$zonea/puppet-agent-1,$zonea/puppet-agent-2,$zoneb/puppet-agent-3,$zoneb/puppet-agent-4",
      region => "$region",
    }

    gce_forwardingrule { 'puppet-rule':
      ensure => present,
      require => Gce_targetpool['puppet-pool'],
      description => 'Forward HTTP to web instances',
      port_range => '80',
      region => "$region",
      target => 'puppet-pool',
    }

    # Create 4 nodes in 2 different zones
    gce_disk { 'puppet-agent-1':
      ensure => present,
      description => 'Boot disk for puppet-agent-1',
      size_gb => 10,
      zone => "$zonea",
      source_image => 'debian-7',
    }

    gce_instance { 'puppet-agent-1':
      ensure => present,
      description => 'Basic web node',
      machine_type => 'n1-standard-1',
      zone => "$zonea",
      disk => 'puppet-agent-1,boot',
      network => 'default',
      require => Gce_disk['puppet-agent-1'],
      puppet_master => "$fqdn",
      puppet_service => present,
    }

    gce_disk { 'puppet-agent-2':
      ensure => present,
      description => 'Boot disk for puppet-agent-2',
      size_gb => 10,
      zone => "$zonea",
      source_image => 'debian-7',
    }

    gce_instance { 'puppet-agent-2':
      ensure => present,
      description => 'Basic web node',
      machine_type => 'n1-standard-1',
      zone => "$zonea",
      disk => 'puppet-agent-2,boot',
      network => 'default',
      require => Gce_disk['puppet-agent-2'],
      puppet_master => "$fqdn",
      puppet_service => present,
    }

    gce_disk { 'puppet-agent-3':
      ensure => present,
      description => 'Boot disk for puppet-agent-3',
      size_gb => 10,
      zone => "$zoneb",
      source_image => 'debian-7',
    }

    gce_instance { 'puppet-agent-3':
      ensure => present,
      description => 'Basic web node',
      machine_type => 'n1-standard-1',
      zone => "$zoneb",
      disk => 'puppet-agent-3,boot',
      network => 'default',
      require => Gce_disk['puppet-agent-3'],
      puppet_master => "$fqdn",
      puppet_service => present,
    }

    gce_disk { 'puppet-agent-4':
      ensure => present,
      description => 'Boot disk for puppet-agent-4',
      size_gb => 10,
      zone => "$zoneb",
      source_image => 'debian-7',
    }

    gce_instance { 'puppet-agent-4':
      ensure => present,
      description => 'Basic web node',
      machine_type => 'n1-standard-1',
      zone => "$zoneb",
      disk => 'puppet-agent-4,boot',
      network => 'default',
      require => Gce_disk['puppet-agent-4'],
      puppet_master => "$fqdn",
      puppet_service => present,
    }
    ```
  This file can also be copied from the included manifest file with,
    ```
    sudo cp compute-video-demo-puppet/manifests/puppet_up.pp /etc/puppet/manifests/puppet_up.pp
    ```
  * The firewall rule is created in this file with the `gce_firewall` block.
  * Each of the four instances are created in the `gce_instance` blocks with
    the instance names as the key. A matching disk is created for each
    instance in `gce_disk` blocks.
  * The load balancer is created with the `gce_targetpool`,
    `gce_httphealthcheck`, and `gce_forwardingrule` blocks.

5. Place the `index.html.erb` file included in this repository into the apache
module template directory,
    ```
    sudo cp compute-video-demo-puppet/index.html.erb /etc/puppet/modules/apache/templates
    ```

6. Apply the `puppet_up.pp` manifest file.
    ```
    sudo puppet apply /etc/puppet/manifests/puppet_up.pp --certname $CERTNAME
    ```

7. Now, you can put the public IP address of the load balancer into your
browser and you should start to see a flicker of pages that will bounce across
each of your instances. You can find your load-balancer IP in the Developers
Console or with,
    ```
    gcutil getforwardingrule puppet-rule --region us-central1
    ```
    Note: You may have to authenticate your regular user with Compute Engine as well by using the ```gcloud compute auth login``` command.

## Cleaning Up

When you're done with the demo, make sure to tear down all of your instances
and clean-up. You will get charged for this usage and you will accumulate
additional charges if you do not remove these resources.

To teardown your setup, apply the following manifest:
  ```
  $zonea = 'us-central1-a'
  $zoneb = 'us-central1-b'
  $region = 'us-central1'

  # Destroy the 4 compute nodes and their persistent disks
  gce_disk { 'puppet-agent-1':
    ensure => absent,
    zone => "$zonea",
  }

  gce_instance { 'puppet-agent-1':
    ensure => absent,
    zone => "$zonea",
  }

  gce_disk { 'puppet-agent-2':
    ensure => absent,
    zone => "$zonea",
  }

  gce_instance { 'puppet-agent-2':
    ensure => absent,
    zone => "$zonea",
  }

  gce_disk { 'puppet-agent-3':
    ensure => absent,
    zone => "$zoneb",
  }

  gce_instance { 'puppet-agent-3':
    ensure => absent,
    zone => "$zoneb",
  }

  gce_disk { 'puppet-agent-4':
    ensure => absent,
    zone => "$zoneb",
  }

  gce_instance { 'puppet-agent-4':
    ensure => absent,
    zone => "$zoneb",
  }

  gce_firewall { 'puppet-firewall':
    ensure => absent,
  }

  # Destroy load balancer and other resources required by the load balancer
  gce_httphealthcheck { 'puppet-http':
    ensure => absent,
  }

  gce_targetpool { 'puppet-pool':
    ensure => absent,
    region => "$region",
  }

  gce_forwardingrule { 'puppet-rule':
    ensure => absent,
    region => "$region",
  }

  # Dependency chaining to make sure that resources are deleted in the correct order
  Gce_instance['puppet-agent-1', 'puppet-agent-2', 'puppet-agent-3', 'puppet-agent-4'] -> Gce_disk['puppet-agent-1', 'puppet-agent-2', 'puppet-agent-3', 'puppet-agent-4']
  Gce_forwardingrule['puppet-rule'] -> Gce_targetpool['puppet-pool']
  Gce_targetpool['puppet-pool'] -> Gce_httphealthcheck['puppet-http']
  ```

## Troubleshooting

* Ensure the module path is correct with `sudo puppet config print modulepath`
  Path should be: `/etc/puppet/modules` on FOSS and `/etc/puppetlabs/puppet/modules` on PE.
* Ensure that puppet modules are installed as root with `sudo puppet module list`.
* Ensure that you are running puppet apply as root by including `sudo` in the command.
* Make sure that if you have created instances and then destroyed them and are now
  trying to create new instances with the same name as the old ones you have cleaned
  the certificates of the old instances off the puppet master. Use
  `sudo puppet cert list --all` to see what certificates the master has and
  `sudo puppet cert clean <certificate name>` to remove old certificates.
* If you have waited several minutes and your isntances still aren't serving web
  pages, check run `tail /var/log/daemon.log` on your puppet agents to see if
  puppet had any issues while applying your manifest.

## Contributing

Have a patch that will benefit this project? Awesome! Follow these steps to have it accepted.

1. Please sign our [Contributor License Agreement](CONTRIB.md).
2. Fork this Git repository and make your changes.
3. Run the unit tests. (gcimagebundle only)
4. Create a Pull Request
5. Incorporate review feedback to your changes.
6. Accepted!

## License
All files in this repository are under the
[Apache License, Version 2.0](LICENSE) unless noted otherwise.
