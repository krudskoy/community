cookbook_file '/etc/logrotate.d/mongodb' do
  source 'logrotate'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end
