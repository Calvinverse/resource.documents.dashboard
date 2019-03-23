# frozen_string_literal: true

require 'spec_helper'

describe 'resource_documents_dashboard::elastic' do
  context 'configures the Elastic repository' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'installs the elastic apt repository' do
      expect(chef_run).to add_apt_repository('elastic-apt-repository').with(
        action: [:add],
        components: %w[main],
        distribution: 'stable',
        key: ['https://artifacts.elastic.co/GPG-KEY-elasticsearch'],
        uri: 'https://artifacts.elastic.co/packages/6.x/apt'
      )
    end
  end
end
