class Contract < ActiveRecord::Base
  belongs_to :smash_client
  def initialize( ec2, name )
    @ec2 = ec2
    @name = name
    status = start_instance( {id: 'i-9155569a'} )
    puts status
    byebug
    status = status( {id: 'i-9155569a'} )
    puts "Current instance status: #{status}"
    status
  end

  def status( params={} )
    @ec2.describe_instances( instance_ids: [params[:id]] )[:reservations].first.instances.first[:state].name
  end

  def start_instance( params={} )
    @ec2.start_instances( instance_ids: [params[:id]] )
  end

  def stop_instance( params={} )
    @ec2.stop_instances( instance_ids: [params[:id]] )
  end
end

