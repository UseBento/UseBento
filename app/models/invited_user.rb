class InvitedUser
  include Mongoid::Document

  field :accepted,    type: Boolean
  field :email,       type: String
  field :inviter_id,  type: String

  embedded_in :project
  belongs_to :user

  def short_email
    if email.length > 20
      email.slice(0,20) + "..."
    else
      email
    end
  end

  def can_see?(user)
    (accepted ||
     (user.admin || user.id.to_s == inviter_id))
  end

  def can_see_email?(user)
    user.admin || (can_see?(user) && !accepted)
  end

  def can_delete?(user)
    return false if !(user.admin || user.id.to_s == inviter_id)
    return false if self.user == project.user
    !(self.user && self.user.admin && self.project.invited_admins.count == 1)
  end
end
