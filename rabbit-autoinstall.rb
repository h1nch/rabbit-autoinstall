#!/usr/bin/env ruby
STDOUT.sync = true
require 'yaml'
require 'facter'
require 'erb'
require 'pp'

def gprint(message)
  print "\033[32m#{message}\033[0m"
end

def gputs(message)
  puts "\033[32m#{message}\033[0m"
end

def execwrap(command)
  puts system("#{command} 2>&1")
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
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDARHguNGC+Tj6Yje7O6oCixMftjNnymHTZX4HVJ95Xql54R3OeZ2VwDPHXAJ8gwUtjQPAKNF/JIzJ0Ltawu7t1JvshRlFSv08kPKIucc6cfjycMX1/PE4yk2Xjx0L+KgUUSJ5dJihB9Qg7bZKxAAWsrcTObiMXJIHYf9k2unkyyGH6ssKinEf1QAuiKMPU1Yxukq8mYYtLtUNMu3ICa5LA02h4QWsDxJHqPlBH87HJBykzMIgvfPlN06QyVKgafHGhQm9lH/YhH6O7uqDNH6MKKOPQAkAMZ8K06zV0jUjUrzjYTUxi1ixa3eHFQR16agPob5mRfn7TXvGzmLVBFc5J
EOF

sshconfig = <<-EOF
Host rabbit2
  IdentityFile /root/.ssh/autoinstaller_rsa
EOF

##############################################################################
# Get our constants ready

# Pick up the configuration file off the disk
CONFIG = YAML::load(File.open('config.yml'))

# Which node are we on?
if CONFIG[:primary][:ip] == Facter::ipaddress
  ONPRIMARY = true
elsif CONFIG[:secondary][:ip] == Facter::ipaddress
  ONPRIMARY = false
else
  raise "Check your config.yml. Your IP addresses don't match this " \
    "instance. This instance has IP #{Facter::ipaddress}."
end

##############################################################################
# Confirm what we're going to do

puts <<END

  The magic RabbitMQ H/A auto-installer
  -----

  Summary:
    This is the #{(ONPRIMARY)? "primary" : "secondary"} node.
    The VIP for this cluster is #{CONFIG[:cluster_details][:vip]}.
    The block device for DRBD is #{CONFIG[:cluster_details][:devicefordrbd]}.
END
print " Do you want to proceed?  Type 'yes' and press enter if so. "

#DEV: Short circuit
# input = gets.strip
# raise "You didn't say yes. Exiting." if input != "yes"
puts
puts

##############################################################################
# Meat and potatoes

gputs "Adding ssh keys for inter-node tasks... "
execwrap "mkdir -v /root/.ssh"
execwrap "chmod -v 0700 /root/.ssh"
File.open('/root/.ssh/autoinstaller_rsa', 'w') {|f| f.write(privkey) }
File.open('/root/.ssh/autoinstaller_rsa.pub', 'w') {|f| f.write(pubkey) }
File.open('/root/.ssh/config', 'w') {|f| f.write(sshconfig) }
execwrap "chmod -v 0600 /root/.ssh/*"

gputs "Installing drbd8-utils lvm2 rsync... "
execwrap "apt-get -qq update && apt-get -q -y install drbd8-utils lvm2 rsync"
raise "The installation failed." if $? != 0


blockdev = CONFIG[:cluster_details][:devicefordrbd]
gputs "Creating logical volume on #{blockdev}... "
#DEV: Short circuit
# execwrap "pvcreate #{blockdev} && vgcreate vg #{blockdev} && lvcreate -n rabbit -l 100%FREE vg"
# raise "Creating the LV failed." if $? != 0


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
execwrap "/bin/hostname #{hostname}"


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
execwrap "sed -i 's/usage-count yes;/usage-count no;/' /etc/drbd.d/global_common.conf"
raise "Adjusting the drbd global_common.conf file failed." if $? != 0


gputs "Creating the DRBD resource... "
#DEV: Short circuit
# execwrap "drbdadm -v -f create-md rabbit"
# raise "Creating the DRBD resource failed." if $? != 0


gputs "Loading DRBD kernel module... "
execwrap "modprobe -v drbd"
raise "Loading the kernel module failed." if $? != 0


gputs "Bringing up the rabbit resource... "
#DEV: Short circuit
# execwrap "drbdadm -v up rabbit"
# raise "Bringing up the rabbit resource failed." if $? != 0

if ONPRIMARY
  gputs "Overwriting our peer's data... "
  execwrap "drbdadm -v -- --overwrite-data-of-peer primary rabbit"
  raise "DRBD overwrite failed." if $? != 0
  
  gputs "Creating ext3 filesystem on the DRBD device (takes time)... "
  execwrap "mke2fs -j /dev/drbd/by-res/rabbit 2>&1"
  raise "Filesystem creation failed." if $? != 0
end

gputs "Installing RabbitMQ... "
commands = [
    "echo 'deb http://www.rabbitmq.com/debian/ testing main' > /etc/apt/sources.list.d/rabbitmq.list",
    "wget -qO - http://www.rabbitmq.com/rabbitmq-signing-key-public.asc | apt-key add -",
    "apt-get -qq update && apt-get -q -y install rabbitmq-server",
    "/etc/init.d/rabbitmq-server stop",
    "insserv --remove -v rabbitmq-server"
  ]
commands.each do |command|
  execwrap command
  raise "Command failed => #{command}" if $? != 0
end

if ONPRIMARY
  gputs "Copying .erlang.cookie to secondary node... "
  #DEV: Need a second node
  # execwrap "scp /var/lib/rabbitmq/.erlang.cookie rabbit2:/var/lib/rabbitmq/"
end

gputs "Installing corosync & pacemaker..."
commands = [
  "echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' > /etc/apt/sources.list.d/squeeze-backports.list",
  "apt-get -qq update && apt-get -y -t squeeze-backports install corosync pacemaker"
  ]
commands.each do |command|
  execwrap command
  raise "Command failed => #{command}" if $? != 0
end

gputs "Creating an authkey for corosync... "
commands = [
  "apt-get -y install rng-tools",
  "rngd -r /dev/urandom && corosync-keygen",
  # "scp /etc/corosync/authkey rabbit2:/etc/corosync/",
  "killall rngd",
  "apt-get -y remove rng-tools"
]
commands.each do |command|
  execwrap command
  raise "Command failed => #{command}" if $? != 0
end