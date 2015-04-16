class Contract < ActiveRecord::Base
  belongs_to :smash_client
#  after_create :determine_instance_type_and_start
  before_destroy :stop_instances
  
  def status( params={} )
    ec2 = self.smash_client.aws_client
    ec2.describe_instances( instance_ids: [params[:id]] )[:reservations].first.instances.first[:state].name
  end # end status

  def determine_instance_type_and_start
    puts "%%%%%%%%%%%%%%%%%%%%%%%\n%%%%%%%%%%%%%%%%%%%%%%%\n%%%%%%%%%%%%%%%%%%%%%%%\n"
    puts "%%%%%%%%%%%%%%%%%%%%%%%\n%%%%%%%%%%%%%%%%%%%%%%%\n%%%%%%%%%%%%%%%%%%%%%%%\n"
    puts "%%%%%%%%%%%%%%%%%%%%%%%\n%%%%%%%%%%%%%%%%%%%%%%%\n%%%%%%%%%%%%%%%%%%%%%%%\n"
    eval("start_#{self.instance_type}_instance")
  end

  def start_instance
    begin
      ec2 = self.smash_client.aws_client
      instance = ec2.start_instances( instance_ids: ['i-9155569a'] ).starting_instances.first
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

  def start_spot_instance
    ec2 = self.smash_client.aws_client
    instance = ec2.request_spot_instance(
      dry_run: true)
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
  end # end stop_instance

    # gets images and returns a mapping of snapshots to an appropriate ami to the server given
  # as the parameter
  def get_ami( options={} )
    image_name = options[:name].nil? ? self.name+"*" : options[:name]+"*"
    self.smash_client.aws_client.
      describe_images( owners: ['self'],filters: [ {name: 'name', values: [image_name]} ] ).images.last # returns an Aws::EC2::Image
  end # end get_ami

    def spot_shopper( image )
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
  end # end spot_shopper

  def all_regions
    self.smash_client.aws_client.describe_regions.regions.map(&:region_name)
  end # end all_regions

  def all_zones
    self.smash_client.aws_client.describe_availability_zones.availability_zones.map(&:zone_name)
  end # end all_zones
end # end Contract
