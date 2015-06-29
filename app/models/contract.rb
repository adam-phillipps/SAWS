class Contract < ActiveRecord::Base
  include Workflow

  belongs_to :smash_client, dependent: :destroy
  before_create :set_name
  delegate :ec2_client, :ec2_resource, :all_zones, :creds, :config, :zone_to_region, to: :smash_client
  self.inheritance_column = :instance_type

  workflow do
    state :new do
      event :start, transition_to: :running
      event :save, transition_to: :created
      event :stop, transition_to: :deleted
      event :terminate, transition_to: :deleted
      event :delete_all, transition_to: :destroyed
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
    state :destroyed
  end

  def self.instance_type
    %w(spot on_demand)
  end

  def cannot_be_stopped?
    ['stopped', 'stopping', 'terminated', 'shutting-down', 'inactive'].include? instance_state
  end

  def cannot_be_started?
    ['terminated', 'shutting-down', 'starting', 'running', 'rebooting', nil].include? instance_status_check
  end

  def save_to_destroy
    self.save!
    self.destroy!
  end

  def instance_status_check
    begin
    instance_state = ec2_client.describe_instances(
      filters: [
        {name: 'tag:Name', values: ["#{name}*"] },
        {name: 'tag:version', values: [newest_instance_version_number]}]).
      first.reservations.first.instances.first[:state].name
      self.update(instance_state: instance_state)
    rescue => e
#      logger.info "no such instance: #{e}, getting AMI"
      self.update(instance_id: nil)
      nil
    end
    instance_state
  end
  
  def set_name
    self.name ||= self.smash_client.name
  end

  def set_instance_id
    begin
      @instance_id ||= ec2_client.describe_instances(
        filters: [
          {name: 'tag:Name', values: ["#{name}*"] },
	   {name: 'tag:version', values: [newest_instance_version_number]}]).
            first.reservations.first.instances.first.instance_id
      self.update(instance_id: @instance_id) unless self.instance_id
    rescue => e
      logger.info "no such instance: #{e}, getting AMI"
      self.update(instance_id: nil)
    end
    nil
  end

  def new_version_number
    today = Time.now.to_i
    epoch = Date.new(1970,1,1).to_time.to_i
    (today - epoch).to_i
  end

  def status
    begin
      ec2_client.describe_instances(instance_ids: [self.instance_id])[:reservations].
        first.instances.first[:state].name
    rescue => e
        "gone"
    end
  end

  def newest_ami_version_number
    ec2_client.describe_images( 
      owners: ['self'],
      filters: [
        {name: 'tag:Name', values: [name]},
        {name: 'tag:version', values: ['*']}]).
      images.map{|image| image.tags.select{|tag| tag.value if tag.key.eql? 'version'}}.
        flatten.max_by{|tag| tag.value.to_i}.value
  end

  def newest_instance_version_number
    ec2_client.describe_instances(
      filters: [
        {name: 'tag:Name', values: ["#{name}*"]},
        {name: 'instance-state-name', values: ['stopping', 'stopped', 'running']}]).
      reservations.map{|res| res.instances.map{|inst| inst.tags.select{|tag| tag.value if tag.key.eql? 'version'}}}.
        flatten.max_by{|tag| tag.value.to_i}.value
  end

  def get_ami
    image_name = name+'*'
    @image ||= ec2_client.describe_images( 
      owners: ['self'], 
      filters: [
        { name: 'tag:Name', values: [image_name] },
        { name: 'tag:version', values: [newest_ami_version_number] }]).images.first
  end

  def get_block_device_mappings
    self.smash_client.ec2_client.describe_images(image_ids: [newest_ami(get_ami.image_id)]).
      first.images.first.block_device_mappings
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
      if self.instance_id
        @memories[ec2_client.describe_instance_attribute(instance_id: self.instance_id, attribute: 'instanceType').instance_type.first]
      else
        'unk'
      end
  end

  def instance_cpu
    'coming soon...'
  end

  def terminate
    if instance_id.nil?
      return 'instance is already terminated or does not exist'
    else
      ec2_client.terminate_instances(instance_ids: [instance_id])
      self.update(instance_state: 'terminated') 
      begin
        ec2_client.wait_until(:instance_terminated, instance_ids:[instance_id])
        logger.info "instance terminated"
      rescue => e
        raise "There was a problem terminating the instance: #{e.message}"
      end
    end
  end
end
