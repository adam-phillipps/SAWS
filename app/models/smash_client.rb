class SmashClient < ActiveRecord::Base
  include Workflow

  has_many :contracts, dependent: :destroy
  accepts_nested_attributes_for :contracts, allow_destroy: true,
    reject_if: lambda { |attributes| attributes[:instance_type].blank? }

  workflow do
    state :new do
      event :save, transition_to: :created
      event :create, transition_to: :created
    end

    state :created do
      event :destroy, transition_to: :destroyed
    end
    
    state :destroyed
  end

  def ec2_client
    @client ||= Aws::EC2::Client.new(credentials: creds, region: home_region)
  end

  def ec2_resource
  	@resource ||= Aws::EC2::Resource.new(client: ec2_client)
  end

  def creds
    @creds ||= Aws::Credentials.new(config[:access_key_id], config[:secret_access_key])
  end

  def config
    @config ||= YAML.load(File.open(File.expand_path(File.join(Rails.root, 'config/connection_config.yml'))))[self.user]
  end

  def home_region
    config[:regions].first
  end

  def all_regions
    @regions ||= ec2_client.describe_regions.regions.map(&:region_name)
  end

  def all_zones
    @zones ||= ec2_client.describe_availability_zones.
      availability_zones.map(&:zone_name)
  end

  def home_zone
    @home_zone ||= all_zones.first
  end

  def zone_to_region( zone )
    zone[0...-1]
  end
end
