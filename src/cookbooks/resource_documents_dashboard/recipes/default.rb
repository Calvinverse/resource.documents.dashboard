# frozen_string_literal: true

#
# Cookbook Name:: resource_documents_dashboard
# Recipe:: default
#
# Copyright 2018, P. van der Velde
#

# Always make sure that apt is up to date
apt_update 'update' do
  action :update
end

#
# Include the local recipes
#

include_recipe 'resource_documents_dashboard::firewall'

include_recipe 'resource_documents_dashboard::meta'

include_recipe 'resource_documents_dashboard::java'

include_recipe 'resource_documents_dashboard::elastic'

include_recipe 'resource_documents_dashboard::elasticsearch'
include_recipe 'resource_documents_dashboard::elasticsearch_service'
include_recipe 'resource_documents_dashboard::elasticsearch_templates'

include_recipe 'resource_documents_dashboard::kibana'
include_recipe 'resource_documents_dashboard::kibana_service'
include_recipe 'resource_documents_dashboard::kibana_templates'

include_recipe 'resource_documents_dashboard::provisioning'
