class Contract < ActiveRecord::Base
  include Workflow

  belongs_to :smash_client, dependent: :destroy
  before_create :set_name
#  before_destroy :stop, unless: :cannot_be_stopped?
  delegate :ec2_client, :ec2_resource, to: :smash_client
  self.inheritance_column = :instance_type # this line is not needed when using :type but is for other column names

  workflow do
    state :new do
      event :start, transition_to: :running
      event :save, transition_to: :created
      event :stop, transition_to: :deleted
      event :terminate, transition_to: :deleted
    end

    state :created do
      event :start, transition_to: :running
      event :stop, transition_to: :deleted
      event :terminate, transition_to: :deleted
    end

    state :running do
      event :stop, transition_to: :deleted
      event :terminate, transition_to: :deleted
    end

    state :deleted
  end

  # We will need a way to know which types
  # will subclass the contract model
  def self.instance_type
    %w(spot on_demand)
  end

  def cannot_be_stopped?
    ['stopped', 'stopping', 'terminated', 'shutting-down', 'inactive'].include? self.instance_state
  end
  
  def set_name
    byebug
    self.name ||= self.smash_client.name
  end

  def status( options={} )
    begin
      ec2_client.describe_instances(instance_ids: [self.instance_id])[:reservations].
        first.instances.first[:state].name
    rescue => e
        "gone"
    end
  end # end status

#  def start
#    self.instance_type.eql? 'Spot' ? self.start_spot_instance : self.start_on_demand_instance
#  end # end start

  def set_instance_id
    begin
      byebug
      @instance_id ||= ec2_client.describe_instances(
        filters: [
          { name: 'tag:Name', values: [self.name] },
          { name: 'instance-state-name', values: ['stopping', 'stopped']} ]).
            first.reservations.first.instances.first.instance_id # gets an instance id
      self.update(instance_id: @instance_id) unless self.instance_id
    rescue => e
      logger.info "no such instance: #{e}, getting AMI"
      self.update(instance_id: nil)
    end
    nil
  end

  def get_ami( options={} )
    image_name = self.name+'*'
    @image ||= self.smash_client.ec2_client.
      describe_images( owners: ['self'],filters: [name: 'tag:Name', values: [image_name]] ).images.last 
  end

  def get_block_device_mappings
    self.smash_client.ec2_client.describe_images(image_ids: [get_ami.image_id]).
      first.images.first.block_device_mappings
  end

  def get_related_instances
    ec2 = ec2_client.describe_instances()
  end

  def stop
    byebug
    id = self.instance_id
    if id.nil?
      'instance is already stopped or does not exist'
    else
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
  end

  def terminate
    id = self.instance_id
    if id.nil?
      return 'instance is already terminated or does not exist'
    else
      ec2_client.terminate_instances(instance_ids: [id])
      self.update(instance_state: 'terminated') 
      begin
        ec2_client.wait_until(:instance_terminated, instance_ids:[id])
        logger.info "instance stopped"
        true
      rescue => e
        raise "failed waiting for instance: #{e.message}"
      end
    end
  end
end
