# resource.documents.dashboard

This repository contains the scripts and tools to create a VM image with an installation of Kibana

This repository contains the source code for the Resource-Documents.Storage image which contains an
instance of the [Kibana](https://www.elastic.co/products/kibana) UI.

## Image

The image is created by using the [Linux base image](https://github.com/Calvinverse/base.linux)
and ammending it using a [Chef](https://www.chef.io/chef/) cookbook which installs the Java
Development Kit, Elasticsearch and Kibana. The Elasticsearch instance is a
[search instance only](https://www.elastic.co/guide/en/kibana/current/production.html#load-balancing),
i.e. it does not take in or processes data neither does it take part in the master election.

There are two different images that can be created. One for use on a Hyper-V server and one for use
in Azure. Which image is created depends on the build command line used.

When the image is created an extra virtual hard drive, called `data.vhdx` is attached on
which the Elasticsearch data will be stored. This disk is mounted at the `/srv/elasticsearch` path

NOTE: The disk is attached by using a powershell command so that we can attach the disk and then go
find it and set the drive assigment to the unique signature of the disk. When we deploy the VM we
only use the disks and create a new VM with those disks but that might lead to a different order in
which disks are attached. By having the drive assignments linked to the drive signature we prevent
issues with missing drives

### Contents

* The Java development kit. The version of which is determined by the version of the `java`
  cookbook in the `metadata.rb` file.
* The Elasticsearch files. The version of which is determined by the `default['elasticsearch']['version']`
  attribute in the `default.rb` attributes file in the cookbook.
* The Kibana files. The version of which is determined by the `default['kibana']['version']` attribute
  in the `default.rb` attribute file in the cookbook. Note that the version number of Kibana
  needs to be the [same as the version number of the Elasticsearch nodes](https://www.elastic.co/guide/en/kibana/current/setup.html#elasticsearch-version)
  in the cluster.

### Configuration

* Elasticsearch is installed in the `/usr/share/elasticsearch` directory.
* The configuration files for Elasticsearch are stored in the `/etc/elasticsearch` directory.
* Kibana is installed in the `/usr/share/kibana` directory.
* The configuration files for Kibana are stored in the `/etc/kibana` directory.

The configuration for the Elasticsearch instance comes from a
[Consul-Template](https://github.com/hashicorp/consul-template) template file which replaces some
of the template parameters with values from the Consul Key-Value store.

Important parts of the configuration file are

* The cluster name is set to be the same as the Consul datacenter name.
* The Elasticsearch instance will only be linked to the `localhost` network interface meaning that
  it is not possible to reach the Elasticsearch instance via the network.
* Cluster formation is done by adding the IP addresses of the other Elasticsearch hosts to the
  [Zen Discovery host file](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery-zen.html#file-based-hosts-provider).

One service is added to [Consul](https://consul.io) for Kibana. This is:

* Service: dashboards - Tags: documents - Port: 5601

### Authentication

There currently are no credentials for connecting to Kibana.

### Clustering

The Elasticsearch instance in the image is able to cluster with other instances in the Consul
environment it is connected to by reading the list of known Elasticsearch hosts which gets collected
by Consul-Template. This list is updated when the machine first connects to the environment and then
every time a change occurs for a machine that publishes a `http.documents` service.

Depending on the environment there need to be a
[minimum of 2 master capable nodes](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#master-node)
before Elasticsearch will allow the cluster to become active. Once two nodes are available in the
environment Elasticsearch will cluster and start moving data around. It is recommended that there are
at least three nodes in the environment at any given time for redundancy purposes.

### Provisioning

No changes to the provisioning are applied other than the default one for the base image.

### Logs

The logging configuration for Kibana is set to write to syslog so that the logs
can be processed the same way as other logs are.

### Metrics

Metrics are collected from Elasticsearch and Kibana and the JVM via the metrics API and
[Telegraf](https://www.influxdata.com/time-series-platform/telegraf/).

## Build, test and deploy

The build process follows the standard procedure for
[building Calvinverse images](https://www.calvinverse.net/documentation/how-to-build).

### Hyper-V

For building Hyper-V images use the following command line

    msbuild entrypoint.msbuild /t:build /P:ShouldCreateHypervImage=true /P:RepositoryArchive=PATH_TO_ARTIFACTLOCATION

where `PATH_TO_ARTIFACTLOCATION` is the full path to the directory where the base image artifact
file is stored.

In order to run the smoke tests on the generated image run the following command line

    msbuild entrypoint.msbuild /t:test /P:ShouldCreateHypervImage=true


### Azure

For building Azure images use the following command line

    msbuild entrypoint.msbuild /t:build
        /P:ShouldCreateAzureImage=true
        /P:AzureLocation=LOCATION
        /P:AzureClientId=CLIENT_ID
        /P:AzureClientCertPath=CLIENT_CERT_PATH
        /P:AzureSubscriptionId=SUBSCRIPTION_ID
        /P:AzureImageResourceGroup=IMAGE_RESOURCE_GROUP

where:

* `LOCATION` - The azure data center in which the image should be created. Note that this needs to be the same
  region as the location of the base image. If you want to create the image in a different location then you need to
  copy the base image to that region first.
* `CLIENT_ID` - The client ID of the user that [Packer](https://packer.io) will use to
  [authenticate with Azure](https://www.packer.io/docs/builders/azure#azure-active-directory-service-principal).
* `CLIENT_CERT_PATH` - The client certificate which Packer will use to authenticate with Azure
* `SUBSCRIPTION_ID` - The subscription ID in which the image should be created.
* `IMAGE_RESOURCE_GROUP` - The resource group from which the base image will be pulled and in which the new image
  will be placed once the build completes.

For running the smoke tests on the Azure image

    msbuild entrypoint.msbuild /t:test
        /P:ShouldCreateAzureImage=true
        /P:AzureLocation=LOCATION
        /P:AzureClientId=CLIENT_ID
        /P:AzureClientCertPath=CLIENT_CERT_PATH
        /P:AzureSubscriptionId=SUBSCRIPTION_ID
        /P:AzureImageResourceGroup=IMAGE_RESOURCE_GROUP
        /P:AzureTestImageResourceGroup=TEST_RESOURCE_GROUP

where all the arguments are similar to the build arguments and `TEST_RESOURCE_GROUP` points to an Azure resource
group in which the test images are placed. Note that this resource group needs to be cleaned out after successful
tests have been run because Packer will in that case create a new image.

## Deploy

### Environment

Prior to the provisioning of a new Kibana host the following information should be available in
the environment in which the Kibana instance will be created.

* An Elasticsearch cluster needs to be available.


### Image provisioning

#### Hyper-V

* Download the new image to one of your Hyper-V hosts.
* Create a directory for the image and copy the image VHDX file there.
* Create a VM that points to the image VHDX file with the following settings
  * Generation: 2
  * RAM: 2048 Mb. Do *not* use dynamic memory
  * Network: VM
  * Hard disk: Use existing. Copy the path to the VHDX file
* Update the VM settings:
  * Enable secure boot. Use the Microsoft UEFI Certificate Authority
  * Set the number of CPUs to 2
  * Attach the additional HDD
  * Attach a DVD image that points to an ISO file containing the settings for the environment. These
    are normally found in the output of the [Calvinverse.Infrastructure](https://github.com/Calvinverse/calvinverse.infrastructure)
    repository. Pick the correct ISO for the task, in this case the `Linux Consul Client` image
  * Disable checkpoints
  * Set the VM to always start
  * Set the VM to shut down on stop
* Start the VM, it should automatically connect to the correct environment once it has provisioned
* Once the machine is connected to the environment wait for about 1 - 2 minutes and then provide the
  machine with credentials for Consul-Template so that it can start handling logs.
* Once Elasticsearch has activated and has connected at this point it is possible to take the other
  Kibana instances out of the environment
  * Shut down the Kibana service
    * SSH into the host
    * Disconnect Kibana by stopping the service: `sudo systemctl stop kibana`
    * Disconnect Elasticsearch by stopping the service: `sudo systemctl stop elasticsearch`
    * Issue the `consul leave` command
    * Shut the machine down with the `sudo shutdown now` command
  * Once the machine has stopped, delete it

#### Azure

The easiest way to deploy the Azure images into a cluster on Azure is to use the terraform scripts
provided by the [Azure logs diagnositcs](https://github.com/Calvinverse/infrastructure.azure.observability.logs)
repository. Those scripts will create an Elasticsearch cluster of the suitable size and add a single instance
of a node with the Kibana enabled.

## Usage

Once the resource is started and provided with the correct permissions to retrieve information
from [Vault](https://vaultproject.io) it will automatically connect to the other Elasticsearch nodes
and become part of a cluster. Once that is done Kibana will be able to load. This may take several
minutes.