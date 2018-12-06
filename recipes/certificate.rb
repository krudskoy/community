cookbook_file '/apps/mongoapp/conf/ca_mongodb.sh' do
  source 'ca_mongodb.sh'
  owner 'was'
  group 'was'
  mode '0775'
  action :create
end

execute 'Execute ca_mongodb script without parameters' do
	user "root"
        cwd "/apps/mongoapp/conf/"
	command "./ca_mongodb.sh"
        not_if { File.exist?('/apps/mongoapp/conf/MongoDB-demo-CA/.ca_settings.sh') }
end

template '/apps/mongoapp/conf/MongoDB-demo-CA/.ca_settings.sh' do
  source 'ca_settings.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

execute 'Execute ca_mongodb script with initial_ca_init' do
	user "root"
        cwd "/apps/mongoapp/conf/"
	command "./ca_mongodb.sh initial_ca_init"
        not_if { File.exist?('/apps/mongoapp/conf/MongoDB-demo-CA/root/private/root.ca.key.pem') }
end

execute 'Execute ca_mongodb script with create_and_sign_cert CLUSTER' do
	user "root"
        cwd "/apps/mongoapp/conf/"
	command "./ca_mongodb.sh create_and_sign_cert CLUSTER MongoPri MongoPri #{node["ipaddress"]}"
        not_if { File.exist?('/apps/mongoapp/conf/MongoDB-demo-CA/root/private/MongoPri.key.pem') }
end

execute 'Execute ca_mongodb script with create_and_sign_cert CLIENT' do
	user "root"
        cwd "/apps/mongoapp/conf/"
	command "./ca_mongodb.sh create_and_sign_cert CLIENT shell 'MongoDB Shell'"
        not_if { File.exist?('/apps/mongoapp/conf/MongoDB-demo-CA/root/private/shell.key.pem') }
end
