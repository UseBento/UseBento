class Message
  include Mongoid::Document

  field :body,           type: String
  field :posted_date,    type: DateTime
  
  belongs_to :user
  embedded_in :project

  def body_as_html
    body = self.body.gsub(URI.regexp, "<a href='\\0'>\\0</a>")
    "<p>" + body.split(/(\r?\n){2,}/).join("</p><p>") + "</p>"
  end
end
