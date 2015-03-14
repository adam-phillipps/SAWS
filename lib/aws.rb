module Aws
  def ec2
    Aws::EC2::Client.new(credentials: aws_creds)
  end

  def aws_creds
    config = YAML.load(File.expand_path(__FILE__, '../config/connection_config.yml')
    aws_creds = Aws::Credentials.new(config['AccessKeyId'], config['SecretAccessKey'])
    aws_creds
  end

    # gets images and returns a mapping of snapshots to an appropriate ami to the server given
  # as the parameter
  def get_ami_image( options={} )#server )
    server_name = options[:server]+"*"
    image = Aws.memoize do # memoize caches results so it makes less requests to gather useful info
      ami_array = $ec2.images.with_owner("self").filter("name", server_name).to_a # gets an image collection filtered to find only SA AMIs
      ami_array.sort_by(&:name).last  # highest version number will sort to the last
    end
    puts "Using AMI: #{image.id} \t name: #{image.name} \t state: #{image.state} \t root: #{image.root_device_name}" 
    image.block_device_mappings.each do |device, map| # useful data mapped out from the image
      id = map.snapshot_id 
      puts "snapshot #{id}  #{device} for deletion" if id
    end
    image # returns an AWS.EC2.image
  end # end get_ami
end
