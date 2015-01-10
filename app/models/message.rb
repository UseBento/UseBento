class Message
  include Mongoid::Document
  include ActionView::Helpers::DateHelper

  field :body,           type: String
  field :posted_date,    type: DateTime
  
  belongs_to :user
  embedded_in :project
  embeds_many :attachments

  def serialize_message(request)

    {avatar:       self.user.avatar(request.host_with_port),
     user_name:    self.user.full_name,
     body:         self.body_as_html,
     posted:       time_ago_in_words(self.posted_date)}
  end

  def body_as_html
    body = self.body.gsub(URI.regexp, "<a href='\\0'>\\0</a>")
    "<p>" + body.split(/(\r?\n){2,}/).join("</p><p>") + "</p>"
  end
end
