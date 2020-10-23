# frozen_string_literal: true

#
# CONSULTEMPLATE
#

default['consul_template']['config_path'] = '/etc/consul-template.d/conf'
default['consul_template']['template_path'] = '/etc/consul-template.d/templates'

#
# ELASTICSEARCH
#

default['elasticsearch']['version'] = '7.9.0'
default['elasticsearch']['service_name'] = 'elasticsearch'
default['elasticsearch']['service_user'] = 'elasticsearch'
default['elasticsearch']['service_group'] = 'elasticsearch'

default['elasticsearch']['path']['data_base'] = '/srv/elasticsearch'
default['elasticsearch']['path']['data'] = '/srv/elasticsearch/data'

default['elasticsearch']['path']['home'] = '/usr/share/elasticsearch'
default['elasticsearch']['path']['config'] = '/etc/elasticsearch'
default['elasticsearch']['path']['logs'] = '/var/log/elasticsearch'
default['elasticsearch']['path']['pid'] = '/var/run/elasticsearch'
default['elasticsearch']['path']['plugins'] = '/usr/share/elasticsearch/plugins'
default['elasticsearch']['path']['bin'] = '/usr/share/elasticsearch/bin'

default['elasticsearch']['port']['discovery'] = 9300
default['elasticsearch']['port']['http'] = 9200

default['elasticsearch']['telegraf']['consul_template_inputs_file'] = 'telegraf_elasticsearch_inputs.ctmpl'

#
# FIREWALL
#

# Allow communication on the loopback address (127.0.0.1 and ::1)
default['firewall']['allow_loopback'] = true

# Do not allow MOSH connections
default['firewall']['allow_mosh'] = false

# Do not allow WinRM (which wouldn't work on Linux anyway, but close the ports just to be sure)
default['firewall']['allow_winrm'] = false

# No communication via IPv6 at all
default['firewall']['ipv6_enabled'] = false

#
# KIBANA
#

home_directory = '/usr/share/kibana'
settings_directory = '/etc/kibana'
default['kibana']['path']['home'] = home_directory
default['kibana']['path']['bin'] = "#{home_directory}/bin"
default['kibana']['path']['settings'] = settings_directory
default['kibana']['path']['pid'] = '/tmp'
default['kibana']['path']['plugins'] = "#{home_directory}/plugins"
default['kibana']['path']['data'] = '/var/lib/kibana'

default['kibana']['port']['http'] = 5601
default['kibana']['proxy']['path'] = 'dashboards/documents'

default['kibana']['consul']['service_name'] = 'logs'

default['kibana']['service_name'] = 'kibana'

default['kibana']['service_user'] = 'kibana'
default['kibana']['service_group'] = 'kibana'

default['kibana']['version'] = '7.9.0'

default['kibana']['telegraf']['consul_template_inputs_file'] = 'telegraf_kibana_inputs.ctmpl'

#
# TELEGRAF
#

default['telegraf']['service_user'] = 'telegraf'
default['telegraf']['service_group'] = 'telegraf'
default['telegraf']['config_directory'] = '/etc/telegraf/telegraf.d'
