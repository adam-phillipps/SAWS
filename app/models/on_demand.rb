class OnDemand < Contract
  after_create :set_instance_id, :start!

  def start
    if cannot_be_started?
      logger.info 'cannot start the instance'
    end
    if instance_id.nil?
      start_instance_from_ami(get_ami)#( name: self.smash_client.name, zone: self.smash_client.home_zone ))
    else
      start_instance_with_id(instance_id)
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

  def start_instance_from_ami( image )
    # watch for the bug fix from amazon.  the api won't accept encrypted = false
    image.block_device_mappings.map do |bdm|
      unless bdm.ebs.nil?
        bdm.ebs.encrypted = nil if bdm.ebs.encrypted.eql? false
      end
    end
    begin
      instance = ec2_resource.create_instances(
        image_id: image.image_id,
        max_count: 1,
        min_count: 1,
        instance_type: image.tags.select { |tag| tag.key.eql? 'instance_types' }.map { |t| t.value }.first,
        placement: { availability_zone: self.smash_client.home_zone },
        block_device_mappings: image.block_device_mappings )
      self.update( instance_id: instance.first.id )
      begin
        ec2_client.wait_until( :instance_running, instance_ids: [instance_id] )
        self.update( instance_state: 'running')
        ec2_client.create_tags( resources: [instance_id], tags: [
          { key: 'Name', value: name },
          { key: 'version', value: new_version_number.to_s }])
        logger.info 'instance running'
      rescue => e
        logger.info "there was a problem starting your instance #{e}"
      end
    rescue => e
      "error starting instance: #{e}"
    end
    ec2_client.describe_instances( instance_ids: [instance_id] )
  end

  def stop
    if instance_id.nil?
      'instance is already stopped or does not exist'
    else
      begin
        ec2_client.stop_instances(instance_ids: [instance_id]) 
        begin
          ec2_client.wait_until(:instance_stopped, instance_ids: [instance_id])
          self.update(instance_state: 'stopped')
          logger.info "instance stopped"
        rescue => e
          logger.info "There was a problem stopping the instance: #{e}"
        end
      rescue => e
        self.update(instance_state: 'unk')
      end
    end
  end
end
