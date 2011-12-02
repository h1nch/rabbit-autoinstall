#!/usr/bin/env ruby
STDOUT.sync = true
require 'yaml'
require 'erb'
require 'pp'

def gprint(message)
  print "\033[32m#{message}\033[0m"
end

def gputs(message)
  puts "\033[32m#{message}\033[0m"
end

def execwrap(commands, checkretval = false)
  if commands.kind_of?(Array)
    commands.each { |command| execwrap(command,checkretval)}
  elsif commands.kind_of?(String)
    puts system("#{commands} 2>&1")
    raise "Command failed.\n#{commands}" if (checkretval && $? != 0)
  else
    raise "execwrap only takes an array or string as a first argument"
  end
end

privkey = <<-EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAwER4LjRgvk4+mI3uzuqAosTH7YzZ8ph02V+B1SfeV6peeEdz
nmdlcAzx1wCfIMFLY0DwCjRfySMydC7WsLu7dSb7IUZRUr9PJDyiLnHOnH48nDF9
fzxOMpNl48dC/ioFFEieXSYoQfUIO22SsQAFrK3Ezm4jFySB2H/ZNrp5Mshh+rLC
opxH9UALoijD1NWMbpKvJmGLS7VDTLtyAmuSwNNoeEFrA8SR6j5QR/OxyQcpMzCI
L3z5TdOkMlSoGnxxoUJvZR/2IR+ju7qgzR+jCijj0AJADGfCtOs1dI1I1K842E1M
YtYsWt3hxUEdemoD6G+ZkX5+017xs5i1QRXOSQIDAQABAoIBADzOqs+6IwqtBmEL
KoboZYyU/cIkdN2j1/jTmuVGOayyJjSWLHvhqZQ5k9byzGD4oRYf+IrRq6Waax+R
nLbCePQBQxVv/tJTzPzh7E0SE00tI5AmmtE9ymF2epgCci6eLYMPwH4nTj4l99eL
vQQbxK+rOX4sGQ79rc9CB/mmGiSz7MLioB+Alwplp7/rWaEY8ubIMoUvrA7Zb+M2
b/7pF8tPaE4NtBmzCEEp2ADFCjgdOwSfqV765/7GV3EYBBqkM04cZSgeX+8C/P5t
vDd2dpRTSS2akOY/ayMuDB9qHq4ryZCGtUq0GIsdzQAKmwJe1QBOVCPcARoL7TEl
mosHFs0CgYEA6LFXkMEA9nTE2ZQTST9CPu9XqQAMUsbKgOmEJjoS3p2JPGH3BeVn
mAcx/ygLaUZIOvZI23JA0+qV08Bb3XXvKZVubaszEacx486pfu1gfApB4qFNahdr
0pdCD7clYiyJSda88HqW/+oEPfL/dorP3JtjDpIaZZQmGuXnJT+RjjcCgYEA04aN
BNK3A9nelSDB56nDID8BAeiZmv/9MLlGJtlELgzLxsQLgGjQSTcYgVw3ij211q+v
6O4kQmqitQuTeTqc/hvptEdmY5aiLHMREy+pcE4/JdRP8j4/H3MzpfNHMbw2fL4m
B/oQhUqk5kjB18jb4ZPgzWtQB1Za7My+vrKJR38CgYAKaQS14Syd2hOEeG90c3QP
RL3zPaFPgr1Ejy3uV+LIOtwM64UVqnG8B3ZhJ/V6vD43BRW1W6My1+fkFVMG0WPl
xF2wYlxiicxdmL1UhGIwqnTQIs9H08xrG4FFGrh9b+ikeQry50kiIeIWs2xibUtn
XzxLRpYPvVUHFwoETJfCeQKBgBM9VMxQgjcGdRlpXlm89jOTp3rN9lLD3/qzj27v
KiVqIorUwBsQ7YkLSt5RTffz/vslBcIRDxk/a8c9408OhsMSNOKh7+01AVE7shzl
o+rEIzhEpHTrNoCc0ODSTPJ4JRiZjwoAs8n77R3JFmCTM3TEJ5lnnmLcdu68/MiJ
orTvAoGBAI3/M6RQnb80Vy0L4Cux2I792qBVKxZFF/k9gy5h/zfT4P8pczvwQYsh
tSmg2mdxuRIN1KtTZIE0Go2EkMe/RDVAtK16BQofPyCPg1aqRZrAp2miY2geeuil
BqaSjU4nqOxG30W7qGd2I0iGoYZXu+gSZQhYXoTwmcFgVGyT9ysH
-----END RSA PRIVATE KEY-----
EOF

pubkey = <<-EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDARHguNGC+Tj6Yje7O6oCixMftjNnymHTZX4HVJ95Xql54R3OeZ2VwDPHXAJ8gwUtjQPAKNF/JIzJ0Ltawu7t1JvshRlFSv08kPKIucc6cfjycMX1/PE4yk2Xjx0L+KgUUSJ5dJihB9Qg7bZKxAAWsrcTObiMXJIHYf9k2unkyyGH6ssKinEf1QAuiKMPU1Yxukq8mYYtLtUNMu3ICa5LA02h4QWsDxJHqPlBH87HJBykzMIgvfPlN06QyVKgafHGhQm9lH/YhH6O7uqDNH6MKKOPQAkAMZ8K06zV0jUjUrzjYTUxi1ixa3eHFQR16agPob5mRfn7TXvGzmLVBFc5J whee
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCxjfFIIlGfCn9iclHymWrEBrTU2lL6tkSGT1ep7dCPzw1jY6WnhQlPXMpePriNxNXlG8cWO9/RFpBd0z9FwNy+kfgh9fuyNY49I+Ma6OyTVBg5hNoFxfRXG5iHtc/SQlnbEFiKpSk4lipo4QZtBtmgAqgkSA6Dzhygb6u5M9ixTIx4WBjuSM0GXQzNjpefyiWu+sIR+h2UrQkKABuuIYQbrjl+FhVmaLvrvyTO2usOtvnYBjhbPwyO72WPjapKd/9hTaqPE1wFy6UF2nXc4Pgw0giQb6sibFTz7NTexW35Q98qpQOWMYKcpgZrlSaHHKZSMhtzO7MdZrOLFUXoS1AeAy4ghtcNrOBTlb5SvP73zz0qBRF2cCO4O0wp5wwqPhvw2ntb3pTLPtdetJ+V50QPnpnXySSnZp2zFwce21bXx67nh9lnhLrZgje7coQnPAFx/cl36ESJygiuPcBw+k18YulYMXUqaBtkwJLkRjDpjTX2e5MJ16oD7sJHc4/W5kyfLvdMsVhdq1CXHGVVOpzogb095VYi0RXFpnZR/1eVgC/R+WVytYfY80rfVOcdAo2GZfnJ5zYRUXJJ9MZkanxx3E7UOikEJN9sUj200z6Cyy0IfIqTbJ1B5f7fd3acRrL4DcYUdFI/1ByNW6F1j7cZiAGOJKNbzXF0T3tf8x0e1Q== major@iridium.local

EOF

sshconfig = <<-EOF
Host rabbit2
  IdentityFile /root/.ssh/autoinstaller_rsa
  StrictHostKeyChecking no
EOF

##############################################################################
# Get our constants ready

# Pick up the configuration file off the disk
CONFIG = YAML::load(File.open('config.yml'))

# What is our IP address?
ipaddress = `ip addr show eth0`.scan(/^    inet ([0-9\.]+)\/[0-9]{2}/)[0].to_s

# Which node are we on?
if CONFIG[:primary][:ip] == ipaddress
  ONPRIMARY = true
elsif CONFIG[:secondary][:ip] == ipaddress
  ONPRIMARY = false
else
  raise "Check your config.yml. Your IP addresses don't match this " \
    "instance. This instance has IP #{ipaddress}."
end


##############################################################################
# Confirm what we're going to do

summary = ERB.new <<-END

  Major's RabbitMQ H/A auto-installer
  -----

  Summary:
    This is the <%=(ONPRIMARY) ? "primary" : "secondary" %> node.
    The VIP for this cluster is #{CONFIG[:cluster_details][:vip]}.
    The block device for DRBD is #{CONFIG[:cluster_details][:devicefordrbd]}.
END
puts summary.result
print " \033[31mDo you want to proceed?  Type 'yes' and press enter if so. \033[0m"

#DEV: Short circuit
input = gets.strip
raise "You didn't say yes. Exiting." if input != "yes"
puts

##############################################################################
# Meat and potatoes

gputs "Adding ssh keys for inter-node tasks... "
execwrap("mkdir -v /root/.ssh")
execwrap("chmod -v 0700 /root/.ssh", true)
File.open('/root/.ssh/autoinstaller_rsa', 'w') {|f| f.write(privkey) }
File.open('/root/.ssh/autoinstaller_rsa.pub', 'w') {|f| f.write(pubkey) }
File.open('/root/.ssh/authorized_keys', 'w') {|f| f.write(pubkey) }
File.open('/root/.ssh/config', 'w') {|f| f.write(sshconfig) }
execwrap("chmod -v 0600 /root/.ssh/*", true)

gputs "Installing drbd8-utils lvm2 rsync... "
execwrap("apt-get -qq update && apt-get -q -y install drbd8-utils lvm2 rsync",true)


blockdev = CONFIG[:cluster_details][:devicefordrbd]
gputs "Creating logical volume on #{blockdev}... "
#DEV: Short circuit
execwrap("pvcreate #{blockdev} && vgcreate vg #{blockdev} && lvcreate -n rabbit -l 100%FREE vg", true)


gputs "Writing /etc/hosts & /etc/hostname... "
hostfile = ERB.new <<-END
127.0.0.1	localhost

# Added by Major's H/A auto-installer
<%=CONFIG[:primary][:ip]%>\t<%=CONFIG[:primary][:hostname]%>
<%=CONFIG[:secondary][:ip]%>\t<%=CONFIG[:secondary][:hostname]%>
<%=CONFIG[:cluster_details][:vip]%>\t<%=CONFIG[:cluster_details][:viphostname]%>

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
END
File.open('/etc/hosts', 'w') {|f| f.write(hostfile.result) }
hostname = ONPRIMARY ? CONFIG[:primary][:hostname] : CONFIG[:secondary][:hostname]
File.open('/etc/hostname', 'w') {|f| f.write(hostname) }
execwrap("/bin/hostname #{hostname}", true)


gputs "Adding DRBD resource for rabbit.. "
drbdresource = ERB.new <<-END
resource rabbit {
  syncer {
    rate            100M;
  }
  disk              /dev/mapper/vg-rabbit;
  device            /dev/drbd0;
  meta-disk         internal;
  on <%=CONFIG[:primary][:hostname]%> {
    address   <%=CONFIG[:primary][:ip]%>:7789;
  }
  on <%=CONFIG[:secondary][:hostname]%> {
    address   <%=CONFIG[:secondary][:ip]%>:7789;
  }
}
END
File.open('/etc/drbd.d/rabbit.res', 'w') {|f| f.write(drbdresource.result) }


gputs "Disabling DRBD usage count reporting... "
execwrap("sed -i 's/usage-count yes;/usage-count no;/' /etc/drbd.d/global_common.conf",true)


gputs "Creating the DRBD resource... "
#DEV: Short circuit
execwrap("drbdadm -v -f create-md rabbit",true)


gputs "Loading DRBD kernel module... "
execwrap("modprobe -v drbd",true)


gputs "Bringing up the rabbit resource... "
#DEV: Short circuit
execwrap("drbdadm -v up rabbit",true)

if ONPRIMARY
  gputs "Overwriting our peer's data... "
  execwrap("drbdadm -v -- --overwrite-data-of-peer primary rabbit",true)
  
  gputs "Creating ext3 filesystem on the DRBD device (takes time)... "
  execwrap("mke2fs -j /dev/drbd/by-res/rabbit 2>&1",true)
end

gputs "Installing RabbitMQ... "
commands = [
    "echo 'deb http://www.rabbitmq.com/debian/ testing main' > /etc/apt/sources.list.d/rabbitmq.list",
    "wget -qO - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add -",
    "apt-get -qq update && apt-get -q -y install rabbitmq-server",
    "/etc/init.d/rabbitmq-server stop",
    "insserv --remove -v rabbitmq-server"
  ]
execwrap(commands, true)

if ONPRIMARY
  gputs "Copying .erlang.cookie to secondary node... "
  #DEV: Need a second node
  execwrap("scp /var/lib/rabbitmq/.erlang.cookie rabbit2:/var/lib/rabbitmq/",true)
end

gputs "Installing corosync & pacemaker..."
commands = [
  "echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' > /etc/apt/sources.list.d/squeeze-backports.list",
  "apt-get -qq update && apt-get -y -t squeeze-backports install corosync pacemaker"
  ]
execwrap(commands,true)

if ONPRIMARY
  gputs "Creating an authkey for corosync... "
  commands = [
    "apt-get -y install rng-tools",
    "rngd -r /dev/urandom && corosync-keygen",
    "scp /etc/corosync/authkey rabbit2:/etc/corosync/",
    "killall rngd",
    "apt-get -y remove rng-tools"
  ]
  execwrap(commands,true)
end

if !ONPRIMARY
  gputs "Ensuring the corosync authkey has come over from the primary node... "
  while true
    break if File.exists?("/etc/corosync/authkey")
    sleep 1
  end
end

gputs "Waiting on DRBD to finish its sync (may take a few minutes)... "
while true do 
  drbdstatus = `drbdadm dstate all`
  break if drbdstatus.match(/UpToDate\/UpToDate/)
  sleep 5
end

gputs "Generating corosync configuration file... "
corosyncconf = ERB.new(File.open("corosync.conf.erb").read)
File.open('/etc/corosync/corosync.conf', 'w') {|f| f.write(corosyncconf.result) }

gputs "Starting corosync... "
execwrap("sed -i 's/START=no/START=yes/' /etc/default/corosync",true)
execwrap("/etc/init.d/corosync start",true)

gputs "Waiting for corosync to settle down (~ 60 seconds or less)... "
while true do
  clusterstatus = `crm_mon -1 -s`
  break if clusterstatus.match(/2 nodes online/)
  sleep 1
end

if (ONPRIMARY)
  gputs "Disabling STONITH... "
  execwrap("crm configure property stonith-enabled=false",true)
  
  gputs "Configuring cluster quorum for two nodes... "
  execwrap("crm configure property no-quorum-policy=ignore")
  
  gputs "Adjusting resource stickiness to prevent failing back... "
  execwrap("crm configure rsc_defaults resource-stickiness=100")
  
  gputs "Adding DRBD to the cluster... "
  commands = [
    %{crm configure primitive drbd ocf:linbit:drbd params drbd_resource="rabbit" op monitor interval="60s"},
    %{crm configure ms drbd_ms drbd meta master-max="1" master-node-max="1" clone-max="2" clone-node-max="1" notify="true" target-role="Master"}
    ]
  execwrap(commands)
  
  gputs "Checking to see if the cluster promoted a DRBD master... "
  while true
    crmmon = `crm_mon -1`
    break if (crmmon.match(/Masters: \[ rabbit1 \]/))
    sleep 1
  end
  
  gputs "Testing DRBD mount... "
  execwrap("mkdir -v /mnt/rabbit")
  commands = [
    "mount /dev/drbd/by-res/rabbit /mnt/rabbit",
    "chown -v -R rabbitmq:rabbitmq /mnt/rabbit",
    "touch /mnt/rabbit/test.txt",
    "rm -vf /mnt/rabbit/test.txt",
    "umount /mnt/rabbit"
    ]
  execwrap(commands,true)
end

if (!ONPRIMARY)
  execwrap("mkdir -v /mnt/rabbit")
end

if (ONPRIMARY)
  gputs "Adding DRBD filesystem mount to cluster... "
  tempcrm = <<-EOF
configure primitive drbd_fs ocf:heartbeat:Filesystem params device="/dev/drbd/by-res/rabbit" directory="/mnt/rabbit" fstype="ext3" op monitor interval="60s"
configure colocation fs_on_drbd inf: drbd_fs drbd_ms:Master
EOF
  File.open('/tmp/crmconfig.tmp', 'w') {|f| f.write(tempcrm) }
  execwrap("crm -f /tmp/crmconfig.tmp",true)

  gputs "Verifying that the rabbit DRBD device is mounted... "
  (1..10).each do |i|
    break if `mount | grep rabbit`.strip == "/dev/drbd0 on /mnt/rabbit type ext3 (rw)"
    sleep 1
    raise "DRBD mount is missing." if i == 10
  end
  
  gputs "Adding the floating IP to the cluster... "
  execwrap(%{crm configure primitive ip ocf:heartbeat:IPaddr2 params ip="#{CONFIG[:cluster_details][:vip]}" cidr_netmask="24" op monitor interval="60s"},true)

  gputs "Adding RabbitMQ, setting a service group, and applying ordering constraints... "
  tempcrm = <<-EOF
configure primitive bunny ocf:rabbitmq:rabbitmq-server params mnesia_base="/mnt/rabbit/" op monitor interval="60s"
configure group servicegroup drbd_fs ip bunny meta target-role="Started"
configure order services_order inf: drbd_fs ip bunny
configure order fs_after_drbd inf: drbd_ms:promote servicegroup:start
EOF
  File.open('/tmp/crmconfig.tmp', 'w') {|f| f.write(tempcrm) }
  execwrap("crm -f /tmp/crmconfig.tmp",true)
end

if (!ONPRIMARY)
  gputs "Waiting for the primary node to finish up with the cluster configuration... "
  while true
    break if `crm_mon -1 -s`.match(/3 resources configured/)
    sleep 1
  end
end



if ONPRIMARY
  gputs "Generating a self-signed certificate and key for RabbitMQ... "
  execwrap("mkdir -v /etc/rabbitmq/ssl/")
  execwrap(%{openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/rabbitmq/ssl/server.key -out /etc/rabbitmq/ssl/server.crt -subj "/C=US/ST=Texas/L=San Antonio/O=My Organization/OU=My Org Unit/CN=rabbit"},true)
  execwrap("rsync -av /etc/rabbitmq/ssl rabbit2:/etc/rabbitmq/",true)
end

if !ONPRIMARY
  gputs "Waiting for the primary to send over the SSL certificate for RabbitMQ... "
  while true do
    break if File.exists?("/etc/rabbitmq/ssl/server.crt")
  end
end

if ONPRIMARY
  gputs "Writing the SSL configuration for RabbitMQ... "
  rabbitmqconfig = <<-EOF
[
  {rabbit, [
     {ssl_listeners, [5671]},
     {ssl_options, [{cacertfile,"/etc/rabbitmq/ssl/server.crt"},
                    {certfile,"/etc/rabbitmq/ssl/server.crt"},
                    {keyfile,"/etc/rabbitmq/ssl/server.key"},
                    {verify,verify_peer},
                    {fail_if_no_peer_cert,false}]}
   ]}
].
EOF
  File.open('/etc/rabbitmq/rabbitmq.config', 'w') {|f| f.write(rabbitmqconfig) }
  execwrap("scp /etc/rabbitmq/rabbitmq.config rabbit2:/etc/rabbitmq/",true)
end

if !ONPRIMARY
  gputs "Waiting for the primary to write a rabbitmq.config file...  "
  while true do
    break if File.exists?("/etc/rabbitmq/rabbitmq.config")
  end
end

if ONPRIMARY
  gputs "Changing RabbitMQ's non-ssl port to 5672 and adding the config file into the cluster... "
  commands = [
    'crm resource stop bunny',
    'crm_resource --resource bunny --set-parameter port --parameter-value 5672',
    'crm_resource --resource bunny --set-parameter config_file --parameter-value "/etc/rabbitmq/rabbitmq"',
    'crm resource start bunny'
    ]
  execwrap(commands,true)
  sleep 5 # Rabbit is slow to bounce
  
  gputs "Checking to see if RabbitMQ is listening on the correct ports... "
  (1..10).each do |i|
    netstat = `netstat -ntlp | grep beam`
    break if netstat.match(/:::5671/) && netstat.match(/:::5672/)
    raise "RabbitMQ didn't listen on the right ports." if i == 10
    sleep 1
  end
  
  execwrap("apt-get -y install curl") unless File.exists?('/usr/bin/curl')

  gputs "Verifying SSL connectivity on port 5671... "
  output = `curl -sk https://localhost:5671`
  raise "No SSL on port 5671." unless output.match(/AMQP/)
  
  gputs "Verifying that there's no encryption on port 5672... "
  output = `curl -s http://localhost:5672`
  raise "SSL active on port 5672." unless output.match(/AMQP/)
  
  gputs "Enabling the management plugin and restarting RabbitMQ... "
  commands = [
    'rabbitmq-plugins enable rabbitmq_management',
    'crm resource restart bunny'
  ]
  execwrap(commands,true)
  sleep 5 # Rabbit is slow to bounce
  
  gputs "Dropping the guest user and adding a user called 'management'... "
  commands = [
    'rabbitmqctl add_user management management',
    'rabbitmqctl set_user_tags management administrator',
    'rabbitmqctl set_permissions management ".*" ".*" ".*"',
    'rabbitmqctl delete_user guest'
  ]
  
  gputs "Attempting a failover... "
  execwrap("crm node standby rabbit1",true)
  sleep 5
  execwrap("crm node online rabbit1",true)
  
end

if !ONPRIMARY
  gputs "Waiting for the primary node to attempt a failover... "
  while true do
    break if `crm_mon -1`.match(/Masters: \[ rabbit2 \]/)
    sleep 1
  end
  
  gputs "Failover started - waiting for the cluster to settle... "
  while true do
    break if `crm_mon -1`.scan(/Started rabbit2/).size == 3
    sleep 1
  end
  # sleep 5 # Rabbit is slow to start
  
  gputs "Verifying DRBD mount... "
  raise "Mount failed." unless `mount | grep rabbit`.match(/\/dev\/drbd0 on \/mnt\/rabbit/)
  
  gputs "Verifying floating IP... "
  ipaddresses = `ip addr show eth0`.scan(/^    inet ([0-9\.]+)\/[0-9]{2}/).flatten
  raise "Floating IP failed." unless ipaddresses.include?(CONFIG[:cluster_details][:vip])
  
  gputs "Verifying RabbitMQ... "
  execwrap("apt-get -y install curl") unless File.exists?('/usr/bin/curl')
  output = `curl -sk https://localhost:5671`
  raise "RabbitMQ isn't listening w/SSL on 5671." unless output.match(/AMQP/)
  output = `curl -s http://localhost:5672`
  raise "Something is wrong with RabbitMQ on 5672." unless output.match(/AMQP/)
  
  gputs "Failing back to the primary... "
  execwrap("crm node standby rabbit2",true)
  sleep 5
  execwrap("crm node online rabbit2",true)
  
  gputs "<<< ALL DONE >>>"
  gputs "BE SURE TO CHECK THE PRIMARY NODE'S SCREEN FOR ADDITIONAL INSTRUCTIONS"
end

if ONPRIMARY
  gputs "Waiting for the secondary node to attempt a failover... "
  while true do
    break if `crm_mon -1`.match(/Masters: \[ rabbit1 \]/)
    sleep 1
  end
  
  gputs "Failover started - waiting for the cluster to settle... "
  while true do
    break if `crm_mon -1`.scan(/Started rabbit1/).size == 3
    sleep 1
  end
  
  gputs <<-EOF
------------------------------------------------------------------------------
<<< ALL DONE >>>
  1) Go back and set a decent password for RabbitMQ's management user:
      rabbitmqctl change_password management <something good>

  2) Check the failover after some hard poweroff and reboot operations
  
  3) Bring down a service and see if pacemaker starts it back up
EOF
end