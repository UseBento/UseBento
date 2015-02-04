class InvitedUser
  include Mongoid::Document

  field :invited,     type: Boolean
  field :email,       type: String
  
  embedded_in :project
  belongs_to :user
end
