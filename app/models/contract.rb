class Contract < ActiveRecord::Base
  belongs_to :smash_client
  after_create :start_instance
  before_destroy :stop_instances
  
  def status( params={} )
    ec2 = params[:ec2]
    ec2.describe_instances( instance_ids: [params[:id]] )[:reservations].first.instances.first[:state].name
  end

  def start_instance
    begin
      ec2 = self.smash_client.aws_client
      instance = ec2.start_instances( instance_ids: ['i-9155569a'] ).starting_instances.first
      instace_id = instance.instace_id
      begin
        self.update(instace_id: instace_id)
        ec2.wait_until(:instance_running, instance_ids:[instace_id])
        "instance running"
      rescue => e
        "failed updating instance: #{e}"
      end
    rescue => e
      "error starting instance: #{e}"
    end
    instance
  end

  def stop_instances
    id = 'i-9155569a'
    ec2 = self.smash_client.aws_client
    ec2.stop_instances( instance_ids: [id] ) 
    begin
      ec2.wait_until(:instance_stopped, instance_ids:[id])
      logger.info "instance stopped"
    rescue Aws::Waiters::Errors::WaiterFailed => error
      raise "failed waiting for instance running: #{error.message}"
    end
  end
end

