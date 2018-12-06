#
# Cookbook:: mongodb_cluster
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

yum_package 'net-snmp-agent-libs'

user 'was' do
    manage_home true
    home '/home/was/'
    shell '/bin/bash'
end

%w[ /apps /apps/mongoapp /apps/mongoapp/data /apps/mongoapp/data/db /apps/mongoapp/conf /apps/mongoapp/logs /apps/mongoapp/conf/certs ].each do |path|
  directory path do
    owner 'was'
    group 'was'
    mode '0755'
  end
end

cookbook_file '/apps/mongoapp/mongodb.tgz' do
  source 'mongodb-linux-x86_64-enterprise-rhel70-3.6.2.tgz'
  owner 'was'
  group 'was'
  mode '0755'
  action :create
end

tar_extract '/apps/mongoapp/mongodb.tgz' do
  action :extract_local
  target_dir '/apps/mongoapp/'
  creates '/apps/mongoapp/mongodb/bin/mongod'
  user 'was'
  group 'was'
end

execute 'Move mongodb archive on server' do
    command 'mv /apps/mongoapp/mongodb-linux-x86_64-enterprise-rhel70-3.6.2 /apps/mongoapp/mongodb'
    not_if { File.exist?('/apps/mongoapp/mongodb/bin/mongod') }
end

template '/apps/mongoapp/conf/mongod.conf' do
  source 'mongod.conf.erb'
  owner 'was'
  group 'was'
  mode '0755'
  not_if { ::File.exists?('/apps/mongoapp/conf/mongod.conf')}
end

cookbook_file '/apps/mongoapp/conf/mongodb.key' do
  source 'keys/mongodb.key'
  owner 'was'
  group 'was'
  mode '0400'
  action :create
end

execute 'Add MONGO_HOME env variable' do
    command "echo 'export MONGO_HOME=/apps/mongoapp/mongodb/bin' >> /home/was/.bashrc"
    not_if { File.readlines("/home/was/.bashrc").grep(/MONGO_HOME/).size > 0 }
end

execute 'Add mongo dit to environment' do
    command "echo 'export PATH=$PATH:/apps/mongoapp/mongodb/bin' >> /home/was/.bashrc"
    not_if { File.readlines("/home/was/.bashrc").grep(/PATH/).size > 0 }
end

execute 'Execute bashrc' do
	user "was"
	command "source ~/.bashrc"
end

directory '/apps/mongoapp' do
  owner 'was'
  group 'was'
  mode '0755'
  recursive true
end

cookbook_file '/apps/mongoapp/conf/certs/root.ca.crt.pem' do
  source 'keys/root.ca.crt.pem'
  owner 'was'
  group 'was'
  mode '0400'
  action :create
end

cookbook_file "/apps/mongoapp/conf/certs/#{ node['hostname'] }.pem" do
  source "keys/#{ node['hostname'] }.pem"
  owner 'was'
  group 'was'
  mode '0400'
  action :create
end

include_recipe "::logrotate"

execute 'Chown /apps directory' do
	user "root"
	command "chown was:was -R /apps"
end

unless `netstat -tulpn | grep :27017` != ""
	execute 'Execute mongod daemon' do
        	user 'was'
		command '/apps/mongoapp/mongodb/bin/mongod --config /apps/mongoapp/conf/mongod.conf'
	end
end

execute 'delay' do
  command 'sleep 80'
end

include_recipe "::add_ssl"
