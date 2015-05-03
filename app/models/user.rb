class User < ActiveRecord::Base
  has_many :smash_clients
  attr_accessor :login
  # adds case insensitivity to validations on user_name
  validates :user_name,
    :presence => true,
    :uniqueness => {
    :case_sensitive => false
  } # etc.
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # creates read/write for login var.  not sure why we need this since it's in attr_accessor.  research later
  def login=(login)
    @login = login
  end

  def login
    @login || self.user_name
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions).where(["lower(user_name) = :value", { :value => login.downcase }]).first
    else
      if conditions[:user_name].nil?
        where(conditions).first
      else
        where(user_name: conditions[:user_name]).first
      end
    end
  end
end
