class Message
  include Mongoid::Document
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::SanitizeHelper

  field :body,           type: String
  field :posted_date,    type: DateTime
  
  belongs_to :user
  embedded_in :project
  embeds_many :attachments

  def serialize_message(request)
    {avatar:       self.user.avatar(request.host_with_port),
     user_name:    self.user.full_name,
     body:         self.body_as_html(true),
     posted:       time_ago_in_words(self.posted_date)}
  end

  def attachments_as_html
    html = ""
    attachments.map do |attachment|
                 if attachment.is_image?
                   html += ("<p class=\"responsive_img\">" + 
                            ("<img src=\"" + 
                             URI.encode_www_form_component(attachment.url) + "\" />") +
                            "</p><p class=\"img_txt\">" +
                            sanitize(attachment.name) +
                                       "</p>")
                 else
                   html += ("<p class=\"img_txt\">" +
                            "<a href=\"" + 
                            URI.encode_www_form_component(attachment.url) +
                                "\">" + sanitize(attachment.name) + 
                                "</a></p>")
                 end
               end
    html
  end

  def body_as_html(with_attachments=false)
    body = self.body.gsub(URI.regexp(['http', 'https']), "<a href='\\0'>\\0</a>")
    ("<p>" + body.split(/(\r?\n){2,}/).join("</p><p>") + "</p>") +
      (with_attachments ? self.attachments_as_html : '')

  end
end
