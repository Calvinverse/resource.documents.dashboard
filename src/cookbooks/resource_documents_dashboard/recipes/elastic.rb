# frozen_string_literal: true

#
# Cookbook Name:: resource_documents_dashboard
# Recipe:: elastic
#
# Copyright 2017, P. van der Velde
#

apt_repository 'elastic-apt-repository' do
  action :add
  components %w[main]
  distribution 'stable'
  key 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
  uri 'https://artifacts.elastic.co/packages/6.x/apt'
end
