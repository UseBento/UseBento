class InvitedUser
  include Mongoid::Document

  field :accepted,    type: Boolean
  field :email,       type: String

  embedded_in :project
  belongs_to :user

  def get_code
    self.project.id + "-" + self.id
  end
end
