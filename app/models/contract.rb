class Contract < ActiveRecord::Base
  belongs_to :smash_client
  
  def make_it( ec2, name )
    @ec2 = ec2
    @name = name
    @instance = start_instance( {id: 'i-9155569a'} )
    status = status( {id: @instance_id} )
    @instance
  end

  def status( params={} )
    @ec2.describe_instances( instance_ids: [params[:id]] )[:reservations].first.instances.first[:state].name
  end

  def start_instance( params={} )
    begin
      instance = @ec2.start_instances( instance_ids: [params[:id]] ).starting_instances.first
      @instance_id = instance.instance_id
      begin
        @ec2.wait_until(:instance_running, instance_ids:[@instance_id])
        "instance running"
      rescue Aws::Waiters::Errors::WaiterFailed => error
        "failed waiting for instance running: #{error.message}"
      end
    rescue Aws::EC2::Errors::IncorrectInstanceState => error
      "instance #{@instance_id} is already started or cannot be started\n#{error.message}"
    end
    instance
  end

  def stop_instances( params={} )
    id = 'i-9155569a'
    byebug
    @ec2.stop_instances( instance_ids: [id] )
    begin
      @ec2.wait_until(:instance_stopped, instance_ids:[@instance_id])
      "instance running"
    rescue Aws::Waiters::Errors::WaiterFailed => error
      "failed waiting for instance running: #{error.message}"
    end
  end
end

