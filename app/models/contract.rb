class Contract < ActiveRecord::Base
  include Workflow

  belongs_to :smash_client, dependent: :destroy
  before_create :set_name
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
    id = self.instance_id
    if id.nil?
      'instance is already stopped or does not exist'
    else
      ec2_client.stop_instances(instance_ids: [id]) 
      begin
        ec2_client.wait_until(:instance_stopped, instance_ids:[id])
        self.update(instance_state: 'stopped')
        logger.info "instance stopped"
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
      rescue => e
        raise "There was a problem terminating the instance: #{e.message}"
      end
    end
  end

  def instance_memory
    @memories = {'t2.micro' => '1-GiB', 't2.small' => '2-GiB', 't2.medium' => '4-GiB',
      'm3.medium' => '3.75-GiB', 'm3.large' => '7.5-GiB', 'm3.xlarge' => '15-GiB', 'm3.2xlarge' => '30-GiB',
      'c4.large' => '3.75-GiB', 'c4.xlarge' => '7.5-GiB', 'c4.2xlarge' => '15-GiB', 'c4.4xlarge' => '30-GiB', 'c4.8xlarge' => '60-GiB',
      'c3.large' => '3.75-GiB', 'c3.xlarge' => '7.5-GiB', 'c3.2xlarge' => '15-GiB', 'c3.4xlarge' => '30-GiB', 'c3.8xlarge' => '60-GiB',
      'r3.large' => '15.25-GiB', 'r3.xlarge' => '30.5-GiB', 'r3.2xlarge' => '61-GiB', 'r3.4xlarge' => '122-GiB', 'r3.8xlarge' => '244-GiB',
      'g2.2xlarge' => '15-GiB', 'g2.8xlarge' => '60-GiB',
      'i2.xlarge' => '30.5-GiB', 'i2.2xlarge' => '61-GiB', 'i2.4xlarge' => '122-GiB', 'i2.8xlarge' => '244-GiB',
      'd2.xlarge' => '30.5-GiB', 'd2.2xlarge' => '61-GiB', 'd2.4xlarge' => '122-GiB', 'd2.8xlarge' => '244-GiB'}
      byebug
      @memories[ec2_client.describe_instance_attribute(instance_id: self.instance_id, attribute: 'instanceType').instance_type.first]
  end

  def instance_cpu
    'coming soon...'
  end
end
