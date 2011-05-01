class Relay < ActiveRecord::Base
  attr_accessible :name, :url, :dollarsraised_goal, :participants_goal, :teams_goal

  validates_presence_of :name
  validates_presence_of :url
  validates_numericality_of :dollarsraised_goal, :greater_than => 0, :only_integer => true
  validates_numericality_of :participants_goal, :greater_than => 0, :only_integer => true
  validates_numericality_of :teams_goal, :greater_than => 0, :only_integer => true

  belongs_to :user

  default_score :order => 'relays.created_at DESC'

  def goals
    {
            :dollarsraised => self.dollarsraised_goal,
            :teams => self.teams_goal,
            :participants => self.participants_goal
    }
  end
end
