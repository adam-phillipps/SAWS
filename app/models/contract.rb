class Contract < ActiveRecord::Base
  belongs_to :smash_client
  after_create :set_name, :determine_instance_type_and_start
  before_destroy :stop_instances
  
  def set_name
    unless self.name
      self.update(name: self.smash_client.name)
    end
  end

  def status( options={} )
    ec2 = self.smash_client.aws_client
    ec2.describe_instances( instance_ids: [options[:id]] )[:reservations].first.instances.first[:state].name
  end # end status

  def determine_instance_type_and_start
    if self.instance_type.eql? 'spot'
      start_spot_instance 
      else
      start_on_demand_instance
    end
  end

  # gets images and returns a mapping of snapshots to an appropriate ami to the server given
  # as the parameter
  def get_ami( options={} )
    options[:name] = 'Adam'
    image_name = (self.name || options[:name])+'*'
    @image = self.smash_client.aws_client.
      describe_images( owners: ['self'],filters: [ {name: 'name', values: [image_name]} ] ).images.last # returns an Aws::EC2::Image
  end # end get_ami

  def best_choice_for( image )
    spot_prices = []
    ec2 = self.smash_client.aws_client
    tags = image.tags
    all_zones.each do |az|
      spot_prices << ec2.describe_spot_price_history( 
      start_time: (Time.now + 36000).iso8601.to_s,
      instance_types: [tags.select{|t| t.key.eql? 'instance_types' }.first.value],
      product_descriptions: [tags.select{|t| t.key.eql? 'product_descriptions' }.first.value],
      availability_zone: az )#.data[:spot_price_history_set]
    end
    best_match = spot_prices.each.map(&:spot_price_history).flatten.
      map{|sp| {spot_price: sp.spot_price, availability_zone: sp.availability_zone }}.min_by{|p| p[:price]}
    best_match[:spot_price] = ( best_match[:spot_price].to_f + 
      ( best_match[:spot_price].to_f*0.2 ) ).round(3).to_s
    best_match
  end # best_choice

  def start_on_demand_instance
    ec2 = self.smash_client.aws_client
    start_instance_with_id( (self.instance_id || get_instance_id) )
  end # end_start_on_demand_instance

  # TODO find a better way 'cause it has to exist
  # finds the instance id using the name the user gives
  def get_instance_id
    @instance_id ||= self.smash_client.aws_client.describe_instances(
      filters: [name: 'tag:Name', values: [self.name]]).
        first.reservations.first.instances.first.instance_id # gets an instance id
  end # end get_instance_id


  # uses an instance id to start an on_demand instance
  def start_instance_with_id( id )
    begin
      instance = self.smash_client.aws_client.start_instances( instance_ids: [id] ).starting_instances.first
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

  def start_spot_instance( options={} )
    image = get_ami
    suggested_offer = best_choice_for( image )
    # this is what is in suggested_offer
    # best_match = {:spot_price=>"1.08", :availability_zone=>"us-west-2a"}
    instance = self.smash_client.aws_client.
      request_spot_instances( suggested_offer )
#    instance = ec2.request_spot_instances( best_choice_for( get_ami( self.name ) ) )
    begin
      ec2.wait_until( :instance_running, instance_ids[@instance.instance_id] )
      self.update( instance_id: instance.instance_id )
      'insance running'
    rescue => e
      "failed updating instance: #{e}"
    end
    instance
  end

  def stop_instances
    id = (self.instance_id || get_instance_id)
    ec2 = self.smash_client.aws_client
    ec2.stop_instances( instance_ids: [id] ) 
    begin
      ec2.wait_until(:instance_stopped, instance_ids:[id])
      logger.info "instance stopped"
    rescue Aws::Waiters::Errors::WaiterFailed => error
      raise "failed waiting for instance running: #{error.message}"
    end
  end # end stop_instance

  def all_regions
    @regions ||= self.smash_client.aws_client.describe_regions.regions.map(&:region_name)
  end # end all_regions

  def all_zones
    @zones ||= self.smash_client.aws_client.describe_availability_zones.
      availability_zones.map(&:zone_name)
  end # end all_zones
end # end Contract
