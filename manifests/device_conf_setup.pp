$project = ''

file { "${confdir}/device.conf":
  ensure  => file,
  content => "[$fqdn]
                type gce
                url [/dev/null]:$project",
}
