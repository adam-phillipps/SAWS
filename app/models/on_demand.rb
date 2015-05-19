class OnDemand < Contract
  after_create :set_instance_id, :start_on_demand_instance

  def start_on_demand_instance
    if instance_id.nil?
      start_on_demand_instance_from_ami(get_ami(name: self.smash_client.name, zone: self.smash_client.home_zone))
    else
      start_instance_with_id(self.instance_id)
    end
  end # end_start_on_demand_instance

  # uses an instance id to start an on_demand instance
  def start_instance_with_id( id )
    ec2 = self.smash_client.ec2_client
    begin
      instance = ec2.start_instances(instance_ids: [id]).starting_instances.first
      id = instance.first.id
      begin
        self.update(instance_id: id)
        ec2.wait_until(:instance_running, instance_ids:[id])
        ec2.create_tags(resources: [id], tags: [key: 'Name', value: self.name])
        "instance running"
      rescue => e
        "failed updating instance: #{e}"
      end
    rescue => e
      "error starting instance: #{e}"
    end
    ec2.describe_instances(instance_ids: [id])
  end # end start_instance

  def start_on_demand_instance_from_ami( image )
    ec2 = self.smash_client.ec2_client
    # watch for the bug fix from amazon.  the api won't accept encrypted = false
    image.block_device_mappings.map { |bdm| bdm.ebs.encrypted = nil if bdm.ebs.encrypted.eql? false }
    id = nil
    begin
      instance = self.smash_client.ec2_resource.create_instances(
        image_id: image.image_id,
        max_count: 1,
        min_count: 1,
        instance_type: image.tags.select { |tag| tag.key.eql? 'instance_types' }.map { |t| t.value }.first,
        placement: {availability_zone: self.smash_client.home_zone},
        block_device_mappings: image.block_device_mappings)
      id = instance.first.id
      self.update(instance_id: id)
      ec2.wait_until(:instance_running, instance_ids: [id])
      self.update(instance_state: 'running')
      ec2.create_tags(resources: [id], tags: [{key: 'Name', value: self.name}])
      logger.info 'instance running'
    rescue => e
      "error starting instance: #{e}"
    end
    ec2.describe_instances(instance_ids: [id])
  end
end
