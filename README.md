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

## Create the Puppet Master Compute Engine Instance

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

1. SSH to your Puppet master
    ```
    gcutil ssh master
    ```

2. Update packages and install puppet and gce_compute
    ```
    wget https://apt.puppetlabs.com/puppetlabs-release-wheezy.deb
    sudo dpkg -i puppetlabs-release-wheezy.deb
    sudo apt-get update
    sudo apt-get install puppetmaster
    sudo puppet module install puppetlabs-gce_compute
    sudo puppet module install puppetlabs-apache
    ```
3. Authenticate with root: `sudo gcloud auth login`
4. Check out this repository so that you can use pre-canned configuration
and demo files.
    ```
    cd $HOME
    git clone https://github.com/GoogleCloudPlatform/compute-video-demo-puppet
    ```

## Puppet-Cloud Setup

1. Configure the Puppet Master service for autosigning
  `echo "*.$(hostname --domain)" | sudo tee /etc/puppet/autosign.conf`
2. Create a site manifest file to specify instance software and services(`/etc/puppet/manifests/site.pp`). 
  ```

  node /^puppet-agent-\d+/ { #regex match for hostname
	  include apache
  }
  ```
3. Set up `device.conf`.
  ```
  PROJECT=$(/usr/share/google/get_metadata_value project-id)

  cat > /etc/puppet/device.conf << EOF
  [my_project]
  type gce
  url [/dev/null]:${PROJECT}
  EOF
  ```
  'my_project' can be substituted with a name of your choice as long as it is used consistently.
4. Create a manifest file in the same directory as the `site.pp` file (`/etc/puppet/manifests/puppet_up.pp`) to create the 4 Compute Engine instatnces, firewall, and load balancer.
  ```
 insert puppet_up.pp here
  ```
  * Firewall rule is created in this file with the `gce_firewall` hash.
  * Each of the four instances are created in the `gce_instance` hashes with the instance names as the key. A disc is created for each instance in `gce_disk` hashes.
  * The load balancer is created with the `gce_targetpool`, `gce_httphealthcheck`, and `gce_forwardingrule` hashes.
5. Place the index.html.erb file found in this repository into the apache module template directory located at: `/etc/puppet/modules/apache/templates`
6. Apply the `puppet_up.pp` manifest file.
`puppet apply --certname=my_project /etc/puppet/manifests/puppet_up.pp`
7. To modify any instance or resource, change the manifest file and apply it again.
8. Now, if you like, you can put the public IP address of the load balancer
into your browser and you should start to see a flicker of pages that will randomly bounce across each of your
instances.


## Cleaning Up

When you're done with the demo, make sure to tear down all of your
instances and clean-up. You will get charged for this usage and you will
accumulate additional charges if you do not remove these resources.

To teardown your setup, apply the following manifest:
```
manifest
```

## Troubleshooting

* Ensure the module path is correct with `sudo puppet config print modulepath`
  Path should be: `/etc/puppet/modules`
* Ensure that puppet modules are installed as root.


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
