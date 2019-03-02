# frozen_string_literal: true

require 'spec_helper'

describe 'resource_documents_dashboard::elasticsearch' do
  context 'installs Elastic Search' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'creates and mounts the data file system at /srv/elasticsearch' do
      expect(chef_run).to create_directory('/srv/elasticsearch')
    end

    it 'creates and mounts the meta file system at /srv/elasticsearch/data' do
      expect(chef_run).to create_directory('/srv/elasticsearch/data').with(
        group: 'elasticsearch',
        mode: '770',
        owner: 'elasticsearch'
      )
    end

    it 'creates the elasticsearch user' do
      expect(chef_run).to create_elasticsearch_user('elasticsearch')
    end

    it 'installs elasticsearch' do
      expect(chef_run).to install_elasticsearch('elasticsearch')
    end

    it 'configures elasticsearch' do
      expect(chef_run).to manage_elasticsearch_configure('elasticsearch')
    end

    elasticsearch_security_override_content = <<~PROPERTIES
      networkaddress.cache.ttl=0
      networkaddress.cache.negative.ttl=0
    PROPERTIES
    it 'creates the /etc/elasticsearch/java.security' do
      expect(chef_run).to create_file('/etc/elasticsearch/java.security')
        .with_content(elasticsearch_security_override_content)
    end

    elasticsearch_jvm_options_content = <<~PROPERTIES
      -XX:+UseConcMarkSweepGC
      -XX:CMSInitiatingOccupancyFraction=75
      -XX:+UseCMSInitiatingOccupancyOnly
      -XX:+AlwaysPreTouch
      -server
      -Xss1m
      -Djava.awt.headless=true
      -Dfile.encoding=UTF-8
      -Djna.nosys=true
      -XX:-OmitStackTraceInFastThrow
      -Dio.netty.noUnsafe=true
      -Dio.netty.noKeySetOptimization=true
      -Dio.netty.recycler.maxCapacityPerThread=0
      -Dlog4j.shutdownHookEnabled=false
      -Dlog4j2.disable.jmx=true
      -XX:+HeapDumpOnOutOfMemoryError
      -Djava.security.properties=/etc/elasticsearch/java.security
    PROPERTIES
    it 'creates the /etc/elasticsearch/jvm.options' do
      expect(chef_run).to create_file('/etc/elasticsearch/jvm.options')
        .with_content(elasticsearch_jvm_options_content)
    end
  end

  context 'configures the firewall for ElasticSearch' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'opens the ElasticSearch discovery port' do
      expect(chef_run).to create_firewall_rule('elasticsearch-discovery').with(
        command: :allow,
        dest_port: 9300,
        direction: :in
      )
    end
  end
end
