class InvitedUser
  include Mongoid::Document

  field :accepted,    type: Boolean
  field :email,       type: String
  field :inviter_id,  type: String

  embedded_in :project
  belongs_to :user

  def can_see?(user)
    (accepted ||
     (user.admin || user.id.to_s == inviter_id))
  end

  def can_see_email?(user)
    user.admin || (can_see?(user) && !accepted)
  end
end
