# frozen_string_literal: true

require 'spec_helper'

describe 'resource_documents_dashboard::kibana' do
  context 'installs Kibana' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'installs the kibana package' do
      expect(chef_run).to install_apt_package('kibana')
    end

    it 'enables the kibana service' do
      expect(chef_run).to enable_service('kibana')
    end

    it 'creates the PID file' do
      expect(chef_run).to create_file('/run/kibana.pid')
    end

    kibana_config_content = <<~CONF
      # Kibana is served by a back end server. This setting specifies the port to use.
      server.port: 5601

      # Specifies the address to which the Kibana server will bind. IP addresses and host names are both valid values.
      # The default is 'localhost', which usually means remote machines will not be able to connect.
      # To allow connections from remote users, set this parameter to a non-loopback address.
      server.host: "0.0.0.0"

      # Enables you to specify a path to mount Kibana at if you are running behind a proxy.
      # Use the `server.rewriteBasePath` setting to tell Kibana if it should remove the basePath
      # from requests it receives, and to prevent a deprecation warning at startup.
      # This setting cannot end in a slash.
      server.basePath: "/dashboards/documents"

      # Specifies whether Kibana should rewrite requests that are prefixed with
      # `server.basePath` or require that they are rewritten by your reverse proxy.
      # This setting was effectively always `false` before Kibana 6.3 and will
      # default to `true` starting in Kibana 7.0.
      server.rewriteBasePath: false

      # The maximum payload size in bytes for incoming server requests.
      #server.maxPayloadBytes: 1048576

      # The Kibana server's name.  This is used for display purposes.
      #server.name: "your-hostname"

      # The URLs of the Elasticsearch instances to use for all your queries.
      elasticsearch.hosts: ["http://127.0.0.1:9200"]

      # When this setting's value is true Kibana uses the hostname specified in the server.host
      # setting. When the value of this setting is false, Kibana uses the hostname of the host
      # that connects to this Kibana instance.
      #elasticsearch.preserveHost: true

      # Kibana uses an index in Elasticsearch to store saved searches, visualizations and
      # dashboards. Kibana creates a new index if the index doesn't already exist.
      kibana.index: ".kibana"

      # The default application to load.
      kibana.defaultAppId: "home"

      # If your Elasticsearch is protected with basic authentication, these settings provide
      # the username and password that the Kibana server uses to perform maintenance on the Kibana
      # index at startup. Your Kibana users still need to authenticate with Elasticsearch, which
      # is proxied through the Kibana server.
      #elasticsearch.username: "user"
      #elasticsearch.password: "pass"

      # Enables SSL and paths to the PEM-format SSL certificate and SSL key files, respectively.
      # These settings enable SSL for outgoing requests from the Kibana server to the browser.
      #server.ssl.enabled: false
      #server.ssl.certificate: /path/to/your/server.crt
      #server.ssl.key: /path/to/your/server.key

      # Optional settings that provide the paths to the PEM-format SSL certificate and key files.
      # These files validate that your Elasticsearch backend uses the same key files.
      #elasticsearch.ssl.certificate: /path/to/your/client.crt
      #elasticsearch.ssl.key: /path/to/your/client.key

      # Optional setting that enables you to specify a path to the PEM file for the certificate
      # authority for your Elasticsearch instance.
      #elasticsearch.ssl.certificateAuthorities: [ "/path/to/your/CA.pem" ]

      # To disregard the validity of SSL certificates, change this setting's value to 'none'.
      #elasticsearch.ssl.verificationMode: full

      # Time in milliseconds to wait for Elasticsearch to respond to pings. Defaults to the value of
      # the elasticsearch.requestTimeout setting.
      #elasticsearch.pingTimeout: 1500

      # Time in milliseconds to wait for responses from the back end or Elasticsearch. This value
      # must be a positive integer.
      #elasticsearch.requestTimeout: 30000

      # List of Kibana client-side headers to send to Elasticsearch. To send *no* client-side
      # headers, set this value to [] (an empty list).
      #elasticsearch.requestHeadersWhitelist: [ authorization ]

      # Header names and values that are sent to Elasticsearch. Any custom headers cannot be overwritten
      # by client-side headers, regardless of the elasticsearch.requestHeadersWhitelist configuration.
      #elasticsearch.customHeaders: {}

      # Time in milliseconds for Elasticsearch to wait for responses from shards. Set to 0 to disable.
      #elasticsearch.shardTimeout: 30000

      # Time in milliseconds to wait for Elasticsearch at Kibana startup before retrying.
      #elasticsearch.startupTimeout: 5000

      # Logs queries sent to Elasticsearch. Requires logging.verbose set to true.
      #elasticsearch.logQueries: false

      # Specifies the path where Kibana creates the process ID file.
      pid.file: /run/kibana.pid

      # Enables you specify a file where Kibana stores log output.
      logging.dest: stdout

      # Set the value of this setting to true to suppress all logging output.
      #logging.silent: false

      # Set the value of this setting to true to suppress all logging output other than error messages.
      #logging.quiet: false

      # Set the value of this setting to true to log all events, including system usage information
      # and all requests.
      #logging.verbose: false

      # Set the interval in milliseconds to sample system and process performance
      # metrics. Minimum is 100ms. Defaults to 5000.
      #ops.interval: 5000

      # Specifies locale to be used for all localizable strings, dates and number formats.
      #i18n.locale: "en"
    CONF
    it 'creates the /etc/kibana/kibana.yml' do
      expect(chef_run).to create_file('/etc/kibana/kibana.yml')
        .with_content(kibana_config_content)
    end
  end

  context 'configures the firewall for Kibana' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    it 'opens the Kibana HTTP port' do
      expect(chef_run).to create_firewall_rule('kibana-http').with(
        command: :allow,
        dest_port: 5601,
        direction: :in
      )
    end
  end

  context 'registers the service with consul' do
    let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

    consul_kibana_http_config_content = <<~JSON
      {
        "services": [
          {
            "checks": [
              {
                "http": "http://127.0.0.1:5601/api/status",
                "id": "kibana_http_health_check",
                "interval": "30s",
                "method": "GET",
                "name": "Kibana HTTP health check",
                "timeout": "5s"
              }
            ],
            "enable_tag_override": false,
            "id": "kibana_http",
            "name": "dashboards",
            "port": 5601,
            "tags": [
              "documents",
              "edgeproxyprefix-/dashboards/documents strip=/dashboards/documents"
            ]
          }
        ]
      }
    JSON
    it 'creates the /etc/consul/conf.d/kibana-http.json' do
      expect(chef_run).to create_file('/etc/consul/conf.d/kibana-http.json')
        .with_content(consul_kibana_http_config_content)
    end
  end
end
