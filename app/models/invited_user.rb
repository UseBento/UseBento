class InvitedUser
  include Mongoid::Document

  field :accepted,    type: Boolean
  field :email,       type: String
  field :inviter_id,  type: String

  embedded_in :project
  belongs_to :user

  def can_see?(user)
    (user.id == inviter_id || 
     user.admin || 
     (self.user && (self.user.admin ||
                    self.user == user)))
  end
end
