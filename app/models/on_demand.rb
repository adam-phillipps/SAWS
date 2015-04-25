class OnDemand < Contract
  after_create :start_on_demand_instance

  def start_on_demand_instance
    ec2 = self.smash_client.aws_client
    start_instance_with_id( (self.instance_id || instance_id) )
  end # end_start_on_demand_instance

    # uses an instance id to start an on_demand instance
  def start_instance_with_id( id )
    begin
      instance = self.smash_client.aws_client.
        start_instances( instance_ids: [id] ).starting_instances.first
      instance_id = instance.instance_id
      begin
        self.update(instance_id: instance_id)
        ec2.wait_until(:instance_running, instance_ids:[instance_id])
        "instance running"
      rescue => e
        "failed updating instance: #{e}"
      end
    rescue => e
      "error starting instance: #{e}"
    end
    instance
  end # end start_instance
end
