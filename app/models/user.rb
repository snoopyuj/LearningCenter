class User < ActiveRecord::Base

  serialize :friend, Array #store friends in array structure

  has_many :user_course_relationships
  has_many :courses, :through => :user_course_relationships

  has_many :user_learning_histories
  has_many :courses, :through => :user_learning_histories

  
  #for omniauth
  has_many :authentications

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         :confirmable # for e-mail authentication

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  #for omniauth
  def apply_omniauth(omniauth)
    self.email = omniauth['extra']['raw_info']['email']
    authentications.build( :provider => omniauth['provider'], :uid => omniauth['uid'], :token => omniauth['credentials']['token'] )
  end
  
  def password_required?
    (authentications.empty? || !password.blank?) && super
  end
end
