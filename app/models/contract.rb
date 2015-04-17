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

  def start_on_demand_instance
    ec2 = self.smash_client.aws_client
    start_instance_with_id( (self.instance_id || get_instance_id) )
  end # end_start_on_demand_instance

  # TODO find a better way 'cause it has to exist
  # finds the instance id using the name the user gives
  def get_instance_id
    begin
      @instance_id ||= self.smash_client.aws_client.describe_instances(
        filters: [name: 'tag:Name', values: [self.name]]).
          first.reservations.first.instances.first.instance_id # gets an instance id
      rescue => e
        "no such instance: #{e}"
      end
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

  # gets images and returns a mapping of snapshots to an appropriate ami to the server given
  # as the parameter
  def get_ami( options={} )
    image_name = (self.name || options[:name])+'*'
    @image ||= self.smash_client.aws_client.
      describe_images( owners: ['self'],filters: [ {name: 'name', values: [image_name]} ] ).images.last # returns an Aws::EC2::Image
  end # end get_ami

  # asks Aws what the best price is for this type of instance, then returns info about the price and zone that had the best value
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
      ( best_match[:spot_price].to_f*0.2 ) ).round(3).to_s # TODO: add a method that does this 20% increase, etc.
    best_match
  end # best_choice

  def start_spot_instance
    instance = self.smash_client.aws_client.
      request_spot_instances( spot_instance_params )
    begin
      ec2.wait_until( :instance_running, instance_ids[@instance.instance_id] )
      self.update( instance_id: instance.instance_id )
      'insance running'
    rescue => e
      "failed updating instance: #{e}"
    end
    instance
  end

  def spot_instance_params
    price_for_zone = best_choice_for( get_ami )
    {spot_price: price_for_zone[:spot_price],
      instance_count: 1, 
      launch_specification: {
        image_id: get_ami.image_id,
        instance_type: get_ami.tags.select{ |tag| tag.key.eql? "instance_types" }.first.value,
        placement: {availability_zone: price_for_zone[:availability_zone]}}}
  end

  def stop_instances
    id = (self.instance_id || get_instance_id)
    byebug
    if id.eql? ("no such instance: undefined method `instances' for nil:NilClass") 
      return 'instance is already stopped or does not exist'
    else
      ec2 = self.smash_client.aws_client
      ec2.stop_instances( instance_ids: [id] ) 
      begin
        ec2.wait_until(:instance_stopped, instance_ids:[id])
        logger.info "instance stopped"
      rescue Aws::Waiters::Errors::WaiterFailed => error
        raise "failed waiting for instance: #{error.message}"
      end
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
