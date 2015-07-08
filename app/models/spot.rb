class Spot < Contract
  after_create :start!

  def start
    @instance = 'nothing yet'
    request_zone = spot_instance_params[:launch_specification][:placement][:availability_zone]
    if instance_already_exists_in?( request_zone )
      @instance = ec2_client.request_spot_instances( spot_instance_params )
    else
      spot_request = Aws::EC2::Client.new( credentials: creds, region: zone_to_region( request_zone )).
        request_spot_instances( spot_instance_params )
    end
    begin
      request_ids = spot_request.spot_instance_requests.map(&:spot_instance_request_id)
      ec2_client.wait_until(:spot_instance_request_fulfilled, spot_instance_request_ids: request_ids)
      @instance = ec2_client.describe_spot_instance_requests(spot_instance_request_ids: request_ids)     
      self.update(instance_id: @instance.spot_instance_requests.first.instance_id,
        request_id: request_ids.first,
        instance_state: 'running')
      'insance running'
    rescue => e
      "Starting the instance failed with: #{e}"
    end
    set_tags
    @instance
  end

  def set_tags
    tags = get_ami.tags
    ec2_client.create_tags( resources: [instance_id, request_id],
      tags: [{key: 'Name', value: name},
        {key: 'version', value: new_version_number}])
  end

  def instance_already_exists_in?( zone )
    ec2_client.describe_instances(filters: [
      {name: 'tag:Name', values: [self.name]},
      {name: 'tag:availability_zone', values: [zone]},
      {name: 'tag:version', values: [new_version_number.to_s]}]).
    reservations.count > 0
  end

  # asks Aws what the best price is for this type of instance, then returns info 
  # about the price and zone that had the best value
  def best_choice_for( image )
    spot_prices = []
    tags = image.tags
    all_zones.each do |az|
      spot_prices << ec2_client.describe_spot_price_history(
      start_time: (Time.now + 36000).iso8601.to_s,
      instance_types: [tags.select {|t| t.key.eql? 'instance_types'}.first.value],
      product_descriptions: [tags.select{|t| t.key.eql? 'product_descriptions'}.first.value],
      availability_zone: az)
    end
    best_match = spot_prices.each.map(&:spot_price_history).flatten.
      map{ |sph| {spot_price: sph.spot_price, availability_zone: sph.availability_zone, instance_type: sph.instance_type} }.
        min_by {|sp| sp[:price]}

    best_match[:spot_price] = (best_match[:spot_price].to_f + 
      (best_match[:spot_price].to_f*0.2)).round(3).to_s # TODO: add a method that does this 20% increase, etc.
    best_match
  end

  def spot_instance_params( options={} )
    @image = get_ami
    @best_choice_params = best_choice_for @image
    {spot_price: @best_choice_params[:spot_price],
      instance_count: 1, 
      launch_specification: {
        image_id: @image.image_id,
        instance_type: @image.tags.select{|tag| tag.key.eql? "instance_types"}.first.value,
        placement: {availability_zone: @best_choice_params[:availability_zone]},
        block_device_mappings: get_block_device_mappings}}
  end

  def stop
    if instance_id.nil?
      'instance is already stopped or does not exist'
    else
      ec2_client.cancel_spot_instance_requests(spot_instance_request_ids: [request_id])
      terminate!
    end
  end
end