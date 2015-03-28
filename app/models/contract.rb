class Contract < ActiveRecord::Base
  belongs_to :smash_client
  def initialize( ec2, name )
    byebug
    puts 'fuck you '
  end
end
