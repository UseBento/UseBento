class Message
  include Mongoid::Document
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::SanitizeHelper

  field :body,           type: String
  field :posted_date,    type: DateTime
  field :read_by,        type: Array

  belongs_to :user
  embedded_in :project
  embedded_in :private_chat
  embeds_many :attachments

  def send_emails(user, project_url, room)
    if room == 'private'
      participants = parent_project.private_chat.people.select {|p| p.accepted}
    else
      participants = parent_project.people.select {|p| p.accepted}
    end
    participants.map do |participant|
                  if participant.user != user
                    # If there was an attachement we need add extra copy
                    body = ""
                    attachment_message = ""

                    if self.attachments.count > 0
                      attachment_message = user.first_name + ' has added a file to ' + parent_project.name
                    end

                    if !self.body.blank?
                      body = body_as_html(false, true)
                    end
                    body += " " + attachment_message

                    ProjectMailer.new_user_message_mail(
                        participant.user.first_name,
                        user.full_name,
                        body,
                        project_url,
                        participant.user.email
                      ).deliver_later
                  end
                end
  end

  def serialize_message(request, rendered)
    {avatar:       self.user.avatar(request.host_with_port),
     user_name:    self.user.full_name,
     user_id:      self.user.id.to_s,
     id:           self.id.to_s,
     body:         rendered,
     posted:       self.format_date}
  end

  def valid_attachments
    attachments.select {|a| a.name}
  end

  def parent_project
    self.project || self.private_chat.project
  end

  def read(user)
    self.read_by = [] if !self.read_by
    self.read_by.push(user.id.to_s)
    save!
  end

  def attachments_as_html
    html = ""
    attachments.each do |attachment|
                 return if !attachment.name
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
                                   "<a href='\\0' target=\"_blank\">\\0</a>")
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
