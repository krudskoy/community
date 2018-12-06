admin = data_bag_item('mongodb', 'admin_pass')

template '/apps/mongoapp/conf/mongod.conf' do
  source 'mongod.conf.erb'
  owner 'was'
  group 'was'
  mode '0755'
end

unless `ps aux | grep '/apps/mongoapp/mongodb/bin/mongod'` == ""
	execute 'MongoDB shutdown' do
        	user 'was'
		command '/apps/mongoapp/mongodb/bin/mongod --shutdown --config /apps/mongoapp/conf/mongod.conf'
	end
end

execute 'MongoDB start' do
        user 'was'
	command '/apps/mongoapp/mongodb/bin/mongod --config /apps/mongoapp/conf/mongod.conf'
end

execute 'Initiate MongoDB' do
        user 'was'
	command <<-EOF
            /apps/mongoapp/mongodb/bin/mongo \
            --host 127.0.0.1 --port 27017 \
            --eval "rs.initiate({_id:'rs0', members: [{_id: 0, host: '#{ node.default['mongo1']['ip']}:27017', priority: 100 },{_id: 1, host: '#{ node.default['mongo2']['ip'] }:27017'}]})"
        EOF
end

execute 'delay' do
  command 'sleep 30'
end

execute 'Add privilege user' do
        user 'was'
	command <<-EOF
		/apps/mongoapp/mongodb/bin/mongo \
		--host 127.0.0.1 --port 27017 \
		--eval "db.getSiblingDB('admin').createUser({ user: 'mongoadmin' , pwd: '#{admin['password']}', roles: ['userAdminAnyDatabase', 'dbAdminAnyDatabase', 'readWriteAnyDatabase', 'clusterAdmin']})"
		EOF
end

execute 'Add an Arbiter' do
        user 'was'
	command <<-EOF
        /apps/mongoapp/mongodb/bin/mongo \
        --host 127.0.0.1 --port 27017 \
        --eval "rs.addArb('#{ node.default['mongo3']['ip']}:27017')" \
        -u mongoadmin -p #{admin['password']} --authenticationDatabase admin
        EOF
end

execute 'delay' do
  command 'sleep 10'
end

file '/apps/mongoapp/conf/initiate' do
  content '1'
  mode '0644'
  owner 'was'
  group 'was'
end

