class PrivateChat
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :project
  embeds_many :invited_users
  embeds_many :messages

  def can_view?(user)
    user.admin || self.invited_users.where(user_id: user.id).first
  end

  def unread_messages_count(user)
    messages.count - messages.where(read_by: user.id.to_s).count
  end

  def people
    people = self.invited_users

    if (people.empty?)
      self.project.people.each do |p|
                           if p.user && p.user.admin
                             user = self.invited_users.create({accepted: true})
                             user.user = p.user
                             user.save
                           end
                         end
      people = self.invited_users
    end
    people
  end
end
