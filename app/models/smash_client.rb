class SmashClient < ActiveRecord::Base
  include Workflow

  has_many :contracts, dependent: :destroy
  accepts_nested_attributes_for :contracts, allow_destroy: true#, 
#    reject_if: lambda { |attributes| attributes[:instance_type].blank? }

  workflow do
    state :created do
      event :new, transition_to: :destroyed
    end

    state :destroyed
  end

  # configures Aws and creates an EC2 object -> @ec2
  def ec2_client
    @client ||= Aws::EC2::Client.new(credentials: creds, region: home_region)#config[:regions].first)
  end  # end connect

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
  end # end all_regions

  def all_zones
    @zones ||= ec2_client.describe_availability_zones.
      availability_zones.map(&:zone_name)
  end # end all_zones

  def home_zone
    @home_zone ||= all_zones.first
  end
end
# smash_client makes bids happen, security, memory allocation, instance types etc.
# bids take care of the ami copy and whatever else needs to happen for a bid to take place.
