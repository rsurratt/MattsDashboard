class User < ActiveRecord::Base
  attr_accessible :name

  validates_presence_of :name
  
  has_many :relays, :dependent => :destroy
end
