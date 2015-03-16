class SmashClient < ActiveRecord::Base
  has_many :contract
  attr_accessor :name

  def make_instance
    byebug
    connect
    Contract.new(self.name)

  end

  # configures AWS and creates an EC2 object -> @ec2
  def connect()  # AKP B add return status indicating sucess / failure
    puts 'Configuring AWS...'
    conn = YAML.load(File.expand_path(__FILE__, 'config/connection_config.yml'))[@smash_client.name]
    #AWS.config( {access_key_id: 'AKIAJATYLIEZY3ISQSJQ',secret_access_key: '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',region: 'us-west-2'} )
    @ec2 = Aws::EC2::Client.new(region:'us-west-2')
  end  # end connect

end
# smash_client makes bids happen, security, memory allocation, instance types etc.
# bids take care of the ami copy and whatever else needs to happen for a bid to take place.
