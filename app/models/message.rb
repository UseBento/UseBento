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
     posted:       self.format_date}
  end

  def attachments_as_html
    html = ""
    attachments.map do |attachment|
                 if attachment.is_image?
                   html += ("<p class=\"responsive_img\">" + 
                            ("<a href=\"" + 
                             URI.encode_www_form_component(attachment.url) + 
                                 "\" target=\"_blank\">") +
                            ("<img src=\"" + 
                             URI.encode_www_form_component(attachment.url) + "\" />") +
                            "</a></p><p class=\"img_txt\">" +
                            sanitize(attachment.name) +
                                       "</p>")
                 else
                   html += ("<p class=\"img_txt\">" +
                            "Click file to download<br />" +
                            "<a target=\"_blank\" href=\"" + 
                            URI.encode_www_form_component(attachment.url) +
                                "\">" + sanitize(attachment.name) + 
                                "</a> " + 
                                attachment.filesize + 
                                "</p>")
                 end
               end
    html
  end

  def body_as_html(with_attachments=false, with_quotes=false)
    body          = self.body.gsub(URI.regexp(['http', 'https']), 
                                   "<a href='\\0'>\\0</a>")
    paragraphs    = body.split(/(\r?\n){2,}/).map { |p|
                      p.strip
                        .split(/\r\n/).join("<br />")
                        .split(/[\r\n]/).join("<br />") }
    "<p>" + 
      (with_quotes ? "&ldquo;" : "") + 
      (paragraphs.join("</p><p>")) + 
      (with_quotes ? "&rdquo;" : "") +
      "</p>" +
      (with_attachments ? self.attachments_as_html : '')
  end

  def format_date
    date          = self.posted_date.in_time_zone("America/Los_Angeles")
    month         = date.strftime "%B"
    day           = date.strftime "%d"
    suffixes      = ['th', 'st', 'nd', 'rd', 'th', 
                     'th', 'th', 'th', 'th', 'th'];
    suffix        = suffixes[day.last.to_i]
    if (day.to_i > 10 && day.to_i < 20)
      suffix = 'th'
    end

    date_str      = month + " " + day + suffix + ", " 
    date_str     += date.strftime "%Y %l:%M%P %Z"
    date_str
  end
end
