class Contract < ActiveRecord::Base
  belongs_to :smash_client
  after_create :set_name#, :determine_instance_type_and_start
  before_destroy :stop_instances
  self.inheritance_column = :instance_type # this line is not needed when using :type but is for other column names

  # We will need a way to know which types
  # will subclass the contract model
  def self.instance_type
    %w(spot on_demand)
  end
  
  def set_name
    byebug
    self.update(name: self.smash_client.name) unless self.name
  end

  def status(options={})
    self.smash_client.aws_client.describe_instances(instance_ids: [options[:id]])[:reservations].
      first.instances.first[:state].name
  end # end status

  def determine_instance_type_and_start
    self.instance_type.eql? 'Spot' ? self.start_spot_instance : self.start_on_demand_instance
  end # end determine_instance_type_and_start

# TODO find a better way 'cause it has to exist
  # finds the instance id using the name the user gives
  def instance_id
    begin
      @instance_id ||= self.smash_client.aws_client.describe_instances(
        filters: [name: 'tag:Name', values: [self.name]]).
          first.reservations.first.instances.first.instance_id # gets an instance id
    rescue => e
      "no such instance: #{e}"
    end
  end # end instance_id

  # gets images and should return a mapping of snapshots to an appropriate AMIs
  # uses the name of the desired instance as a param.
  # returns an Aws::EC2::Image
  def get_ami(options={})
    image_name = (self.name || options[:name])+'*'
    byebug
    @image ||= self.smash_client.aws_client.
      describe_images(owners: ['self'],filters: [name: 'tag:Name', values: [image_name]]).images.last 
  end # end get_ami
################################################################################
  # gets AMI block_device_mappings for an image
  def get_block_device_mappings
    self.smash_client.aws_client.describe_images(image_ids: [get_ami.image_id]).
      first.images.first.block_device_mappings
  end # end get_block_device_mappings

  # not sure if we need this yet
  def get_related_instances
    ec2 = self.smash_client.aws_client
    ec2.describe_instances
  end # end get_related_instances

  def stop_instances
    id = (self.instance_id || instance_id)
    byebug
    if id.eql? ("no such instance: undefined method `instances' for nil:NilClass") 
      return 'instance is already stopped or does not exist'
    else
      ec2 = self.smash_client.aws_client
      ec2.stop_instances(instance_ids: [id]) 
      begin
        ec2.wait_until(:instance_stopped, instance_ids:[id])
        logger.info "instance stopped"
      rescue Aws::Waiters::Errors::WaiterFailed => error
        raise "failed waiting for instance: #{error.message}"
      end
    end
  end # end stop_instance

  def all_regions
    @regions ||= self.smash_client.aws_client.describe_regions.regions.map(&:region_name)
  end # end all_regions

  def all_zones
    @zones ||= self.smash_client.aws_client.describe_availability_zones.
      availability_zones.map(&:zone_name)
  end # end all_zones
end # end Contract
