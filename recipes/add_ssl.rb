if `grep requireSSL /apps/mongoapp/conf/mongod.conf` == ""
	template '/apps/mongoapp/conf/mongod.conf' do
	  source 'mongod_require_ssl.conf.erb'
	  owner 'was'
	  group 'was'
	  mode '0755'
	end

	execute 'MongoDB shutdown' do
       		user 'was'
		command '/apps/mongoapp/mongodb/bin/mongod --shutdown --config /apps/mongoapp/conf/mongod.conf'
	end

	execute 'MongoDB start' do
        	user 'was'
		command '/apps/mongoapp/mongodb/bin/mongod --config /apps/mongoapp/conf/mongod.conf'
	end
else
	print "================ Host already use requireSSL option =================="
end


