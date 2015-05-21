class Contract < ActiveRecord::Base
  include Workflow

  belongs_to :smash_client
  before_create :set_name
  before_destroy :stop, unless: :cannot_be_stopped?
  self.inheritance_column = :instance_type # this line is not needed when using :type but is for other column names

  delegate :ec2_client, to: :smash_client # this will eliminate the need to keep calling self.smash_client.ec2client now I can just call ec2client

  workflow do
    state :new do
      event :save, transition_to: :created
    end

    state :created do
      event :start, transition_to: :running
    end

    state :running do
      event :stop, transition_to: :deleted
      event :terminate_instances, transition_to: :deleted
    end

    state :deleted
  end

  def cannot_be_stopped?
    ['stopped', 'stopping', 'terminated', 'shutting-down', 'inactive'].include? self.instance_state
  end

  def set_name
    self.name ||= self.smash_client.name
  end

  def status(options={})
    begin
      ec2_client.describe_instances(instance_ids: [self.instance_id])[:reservations].
        first.instances.first[:state].name
    rescue => e
        "gone"
    end
  end # end status

  def start
    self.instance_type.eql? 'Spot' ? self.start_spot_instance : self.start_on_demand_instance
  end # end start

  # TODO find a better way 'cause it has to exist
  # finds the instance id using the name the user gives
  def set_instance_id
    # TODO
    # figure out why the instance-stat-name filter returns different amounts of instances than the UI
    # so far it seems like the owner determines it so it should be a good thing
    begin
      @instance_id ||= ec2_client.describe_instances(
        filters: [
          {name: 'tag:Name', values: [self.name]},
          {name: 'instance-state-name', values: ['stopping', 'stopped']}]).
            first.reservations.first.instances.first.instance_id # gets an instance id
      self.update(instance_id: @instance_id) unless self.instance_id
    rescue => e
      logger.info "no such instance: #{e}, getting AMI"
      self.update(instance_id: nil)
    end
    nil
  end # end instance_id

  # gets images and should return a mapping of snapshots to an appropriate AMIs
  # uses the name of the desired instance as a param.
  # returns an Aws::EC2::Image
  def get_ami(options={})
    image_name = self.name+'*'
    @image ||= ec2_client.
      describe_images(owners: ['self'],filters: [name: 'tag:Name', values: [image_name]]).images.last
  end # end get_ami

  # gets AMI block_device_mappings for an image
  def get_block_device_mappings
    ec2_client.describe_images(image_ids: [get_ami.image_id]).
      first.images.first.block_device_mappings
  end # end get_block_device_mappings

  # not sure if we need this yet
  def get_related_instances
    ec2_client.describe_instances()
  end # end get_related_instances

  def stop
    return 'instance is already stopped or does not exist' if instance_id.nil?
    ec2_client.stop_instances(instance_ids: [id])
    begin
      ec2_client.wait_until(:instance_stopped, instance_ids:[id])
      self.update(instance_state: 'stopped')
      logger.info "instance stopped"
      true
    rescue => e
      raise "There was a problem stopping the instance: #{e}"
    end
  end

  def terminate_instances
    return 'instance is already terminated or does not exist' if instance_id.nil?
    ec2_client.terminate_instances(instance_ids: [id])
    self.update(instance_state: 'terminated')
    begin
      ec2_client.wait_until(:instance_terminated, instance_ids:[id])
      logger.info "instance stopped"
      true
    rescue => e
      raise "failed waiting for instance: #{error.message}"
    end
  end

end
