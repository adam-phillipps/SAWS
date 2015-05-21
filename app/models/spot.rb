class Spot < Contract
  after_create :start

  def start
    ec2 = self.smash_client.ec2_client
    best_choice_params = best_choice_for(get_ami)
    instance = 'nothing yet'
    if instance_already_exists_in(best_choice_params[:availability_zone])
      instance = ec2.request_spot_instance(spot_instance_params)
    else
      image = get_ami
      config = YAML.load(File.expand_path(__FILE__, '../config/connection_config.yml'))
      aws_creds = Aws::Credentials.new(config['AccessKeyId'], config['SecretAccessKey'])
      Aws::EC2::Client.new(credentials: aws_creds).create_instance(image)
    end
    begin
      ec2.wait_until(:instance_running, instance_ids[@instance.instance_id])
      self.update(instance_id: instance.instance_id)
      'insance running'
    rescue => e
      "Starting the instance failed with: #{e}"
    end
    instance
  end

  # checks if the instance already exists in the given zone and returns boolean
  def instance_already_exists_in(zone)
    self.smash_client.ec2_client.describe_instances(filters: [
      {name: 'tag:Name', values: [self.name]},
      {name: 'tag:availability_zone', values: [zone]}]).reservations.count > 0
  end # end instance_already_exists_in?

  # asks Aws what the best price is for this type of instance, then returns info
  # about the price and zone that had the best value
  def best_choice_for(image)
    spot_prices = []
    ec2 = self.smash_client.ec2_client
    tags = image.tags
    all_zones.each do |az|
      spot_prices << ec2.describe_spot_price_history(
      start_time: (Time.now + 36000).iso8601.to_s,
      instance_types: [tags.select {|t| t.key.eql? 'instance_types'}.first.value],
      product_descriptions: [tags.select{|t| t.key.eql? 'product_descriptions'}.first.value],
      availability_zone: az)#.data[:spot_price_history_set]
    end
    best_match = spot_prices.each.map(&:spot_price_history).flatten.
      map{|sph| {spot_price: sph.spot_price, availability_zone: sph.availability_zone, instance_type: sph.instance_type}}.
        min_by {|sp| sp[:price]}

    best_match[:spot_price] = (best_match[:spot_price].to_f +
      (best_match[:spot_price].to_f*0.2)).round(3).to_s # TODO: add a method that does this 20% increase, etc.
    best_match
  end # best_choice_for

  # creates a hash that can be used to start a spot instance and map it to its ebs/other instances/etc
  def spot_instance_params(options={})
    best_choice_params = best_choice_for(get_ami(options[:name]))
    {spot_price: best_choice_params[:spot_price],
      instance_count: 1,
      launch_specification: {
        image_id: get_ami.image_id,
        instance_type: get_ami.tags.select{|tag| tag.key.eql? "instance_types"}.first.value,
        placement: {availability_zone: best_choice_params[:availability_zone]},
        block_device_mappings: get_block_device_mappings}}
  end # end spot_instance_params
end
