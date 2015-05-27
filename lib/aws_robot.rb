module AwsRobot
  def ec2_client
    byebug
    Aws::EC2::Client.new(credentials: aws_creds, region: home_zone)
  end

  def ec2
    Aws::EC2.new(credentials: aws_creds)
  end

  def aws_creds
    byebug
    Aws::Credentials.new(aws_config['AccessKeyId'], aws_config['SecretAccessKey'])
  end

  def aws_config
    byebug
    YAML.load(File.open(File.expand_path(File.join(Rails.root, 'config/connection_config.yml'))))[self.user]
  end


  # gets images and should return a mapping of snapshots to an appropriate AMIs
  # uses the name of the desired instance as a param.
  # returns an Aws::EC2::Image
  def get_ami(options={})
    byebug
    image_name = options[:name]+'*'
    ec2_client.
      describe_images(owners: ['self'],filters: [name: 'tag:Name', values: [image_name]]).images.last 
  end # end get_ami
################################################################################
  # gets AMI block_device_mappings for an image
  def get_block_device_mappings
    self.smash_client.ec2_client.describe_images(image_ids: [get_ami.image_id]).
      first.images.first.block_device_mappings
  end # end get_block_device_mappings

  # gets images and returns a mapping of snapshots to an appropriate ami to the server given
  # as the parameter
#  def get_ami( options={} )
#    byebug
#    server_name = options[:server]+"*"
#    image = Aws.memoize do # memoize caches results so it makes less requests to gather useful info
#      ami_array = $ec2.images.with_owner("self").filter("name", server_name).to_a # gets an image collection filtered to find only SA AMIs
#      ami_array.sort_by(&:name).last  # highest version number will sort to the last
#    end
#    puts "Using AMI: #{image.id} \t name: #{image.name} \t state: #{image.state} \t root: #{image.root_device_name}" 
#    image.block_device_mappings.each do |device, map| # useful data mapped out from the image
#      id = map.snapshot_id 
#      puts "snapshot #{id}  #{device} for deletion" if id
#    end
#    image # returns an AWS.EC2.image
#  end # end get_ami

  def home_zone
    byebug
    aws_config[:regions].first
  end
end
