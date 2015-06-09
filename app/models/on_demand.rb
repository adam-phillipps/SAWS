class OnDemand < Contract
  after_create :set_instance_id, :start!

  def start
    byebug
    if cannot_be_started?
      'cannot start the instance'
      smash_client.contracts.delete_all
      smash_client.delete
#      smash_client.save_to_destroy! unless smash_client.destroyed?
    else
      if instance_id.nil?
        start_on_demand_instance_from_ami( get_ami( name: self.smash_client.name, zone: self.smash_client.home_zone ))
      else
        start_instance_with_id(instance_id)
      end
    end
  end # end_start_on_demand_instance

  # uses an instance id to start an on_demand instance
  def start_instance_with_id( id )
    begin
      instance = ec2_client.start_instances( instance_ids: [id] ).starting_instances.first
      id = instance.first.id
      begin
        self.update(instance_id: id)
        ec2_client.wait_until( :instance_running, instance_ids:[id] )
        ec2_client.create_tags( resources: [id], tags: [
          { key: 'Name', value: name },
          { key: 'version', value: new_version_number }] )
        "instance running"
      rescue => e
        "failed updating instance: #{e}"
      end
    rescue => e
      "error starting instance: #{e}"
    end
    ec2_client.describe_instances( instance_ids: [id] )
  end # end start_instance

  def start_on_demand_instance_from_ami( image )
    # watch for the bug fix from amazon.  the api won't accept encrypted = false
    image.block_device_mappings.map do |bdm|
      unless bdm.ebs.nil?
        bdm.ebs.encrypted = nil if bdm.ebs.encrypted.eql? false
      end
    end
    id = nil
    begin
      instance = ec2_resource.create_instances(
        image_id: image.image_id,
        max_count: 1,
        min_count: 1,
        instance_type: image.tags.select { |tag| tag.key.eql? 'instance_types' }.map { |t| t.value }.first,
        placement: { availability_zone: self.smash_client.home_zone },
        block_device_mappings: image.block_device_mappings )
      id = instance.first.id
      self.update( instance_id: id )
      ec2_client.wait_until( :instance_running, instance_ids: [id] )
      self.update( instance_state: 'running')
      ec2_client.create_tags( resources: [id], tags: [
        { key: 'Name', value: name },
        { key: 'version', value: new_version_number }])
      logger.info 'instance running'
    rescue => e
      "error starting instance: #{e}"
    end
    ec2_client.describe_instances( instance_ids: [id] )
  end

  def stop
    id = self.instance_id
    if id.nil?
      'instance is already stopped or does not exist'
    else
      ec2_client.stop_instances(instance_ids: [id]) 
      begin
        ec2_client.wait_until(:instance_stopped, instance_ids: [id])
        self.update(instance_state: 'stopped')
        logger.info "instance stopped"
      rescue => e
        raise "There was a problem stopping the instance: #{e}"
      end
    end
  end
end
