class InvitedUser
  include Mongoid::Document

  field :accepted,    type: Boolean
  field :email,       type: String
  field :inviter_id,  type: String

  embedded_in :project
  embedded_in :private_chat
  belongs_to :user

  def self.send_invite(project, from, email)
    to = User.where(email: email).first

    if from == to
      error = "You can't invite yourself!"
    elsif (project.invited_users.where(email: email).first ||
           (to && project.invited_users.where(user: to).first))
      error = "You already invited " + ((to && to.full_name) || email)
    else
      invitation  = project.invited_users.create({accepted:   false,
                                                  email:      email})
      invitation.inviter_id  = from.id
      invitation.user        = to if to
      invitation.save

      if project.class == Project
        UserMailer.invited_to_project_mail(invitation, project, from).deliver
      elsif project.class == PrivateChat
        UserMailer.invited_to_private_chat_mail(invitation, project, from).deliver
      end
    end
    invitation || error
  end

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

  def get_project
    self.project || self.private_chat.project
  end

  def can_delete?(user)
    return false if !(user.admin || user.id.to_s == inviter_id)
    return false if self.user == get_project.user
    !(self.user && self.user.admin && get_project.invited_admins.count == 1)
  end
end
