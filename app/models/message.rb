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


  def self.forward_message_to_websocket(message, proj, is_private)
    sent_msg    = false
    token       = ""
    ws          = WebSocket::Client::Simple.connect 'ws://localhost:3002/websocket'
    pongs       = 0

    ws.on :message do |msg|
      p msg.to_yaml
      puts msg.data
      parsed = JSON.parse(msg.data)
      if (parsed && parsed[0].kind_of?(Array) && parsed[0][0] == 'websocket_rails.channel_token')
        token = parsed[0][1]['data']['token']
      end

      if (msg.data.slice(3,20) == 'websocket_rails.ping')
        m = '["websocket_rails.pong",{"id":' + (rand * 1000000).round.to_s + ',"data":{}}]'
        p m
        ws.send m
        pongs += 1
        if pongs > 10
          ws.close
          self.forward_message_to_websocket(message, proj, is_private)
        end
        if (sent_msg)
          ws.close
        else
          msg = ('["message_posted",{"id":' + (rand * 1000000).round.to_s + ',"channel":"project-' + 
                 proj.id.to_s  + '","data":{"message_id":"' + message.id.to_s + 
                 '","room":"group","project_id":"' + (proj.id.to_s) + '"},"token":"' + token + '"}]')
          p msg
          ws.send(msg)
          sent_msg = true
        end
      end
    end

    ws.on :open do
      m = '["websocket_rails.subscribe",{"id":' + (rand * 1000000).round.to_s + ',"data":{"channel":"project-' + proj.id.to_s + '"}}]'
      p m
      ws.send m
    end

    ws.on :close do |e|
      p 'error' + e.to_s
    end

    ws.on :error do |e|
      p 'error' + e.to_s
    end

    (1..10).map do |i|

    end

    p 'test'
    ws
  end


  def self.get_email_replies
    Mailman.config.imap = {
      server: 'imap.gmail.com',
      port: 993, 
      ssl: true,
      # Use starttls instead of ssl (do not specify both)
#      starttls: true,
      username: Rails.configuration.gmail_imap_username,
      password: Rails.configuration.gmail_imap_password}

    Mailman.config.poll_interval = 60
    
    Mailman::Application.run do
      default do
        begin
          if (message.body.parts)
            body = message.body.parts[0].decoded
          else
            body = message.body.decoded
          end
          print message.to_yaml
          print body + "\n\n"
          print body.match /bento-reply<([a-zA-Z0-9]+):([a-zA-Z0-9]+):(chat|private_chat)>/
          print "\n\n"
          
          matches = body.match /bento-reply<([a-zA-Z0-9]+):([a-zA-Z0-9]+):(chat|private_chat)>/
          if matches
            reply_id      = matches[1]
            user_id       = matches[2]
            room          = matches[3]
            project       = Project.find(reply_id)
            from          = message.from.first
            from_user     = User.find(user_id) || User.where(email: from).first

            messages      = room == 'chat' ? project.messages : project.get_private_chat.messages
            message       = messages.create({body: Message.remove_quote_from_email(body),
                                             posted_date: DateTime.now})
            message.user  = from_user
            message.save

            url           = "https://usebento.com/" + ('/projects/' + project.id +
                                        (@room == 'private_chat' ? '/private_chat' : ''))

            message.send_emails(from_user, url,
                                (room == 'prvate_chat' ? 'prvate' : 'chat'),
                                project, room == 'private_chat')
            
            project.updated_at = DateTime.now
            project.save!

            Message.forward_message_to_websocket(message, project, @room == 'private_chat')
            Message.forward_message_to_websocket(message, project, @room == 'private_chat')
          end
        rescue Exception => e
          Mailman.logger.error "Exception occurred while receiving message:n#{message}"
          Mailman.logger.error [e, *e.backtrace].join("n")
        end
      end
    end
  end

  def self.remove_quote_from_email(body)
    message = ""
    broken  = false
    
    split = body.split(/^On (.*?)wrote:/mi)
    if split
      body = split[0]
    end
    
    body.split(/[\r\n]/).each do |line|
      if !broken
        if (line.match(/^On [^\r\n]+wrote:/))
          broken = true
        elsif (!line.match(/^>/) && !line.match(/^--[0-9a-fA-F]{20,40}/) && !line.match(/^(Content-Type|Content-Transfer-Encoding):/i))
          message += line + "\r\n"
        end
      end
    end

    message
  end
  
  def send_emails(user, project_url, room, project, is_private)
    if room == 'private'
      participants = parent_project.private_chat.people.select {|p| p.accepted}
    else
      participants = parent_project.people.select {|p| p.accepted}
    end
    ## shouldn't these two blocks be combined? particpants.concat(parent_projects.designers.select {|p| p.accepted}).map do |participant|
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
                        participant.user.email,
                        project.email_code(participant.user, is_private)
                      ).deliver_later

                  end
                end
    participants = parent_project.designers.select {|p| p.accepted}
    
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
                        participant.user.email,
                        project.email_code(participant.user, is_private)
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
    end_time = Time.now
    start_time = self.posted_date
    time_difference = TimeDifference.between(start_time, end_time).in_each_component
    # date          = self.posted_date.in_time_zone("America/Los_Angeles")
    # month         = date.strftime "%B"
    # day           = date.strftime "%d"
    # suffixes      = ['th', 'st', 'nd', 'rd', 'th',
    #                  'th', 'th', 'th', 'th', 'th'];
    # suffix        = suffixes[day.last.to_i]
    # if (day.to_i > 10 && day.to_i < 20)
    #   suffix = 'th'
    # end

    # date_str      = month + " " + day + suffix + ", "
    # date_str     += date.strftime "%Y %l:%M%P %Z"
    # date_str

    if time_difference[:seconds].to_i < 5
      date_str = " just now"
    elsif time_difference[:seconds].to_i < 60
      date_str = time_difference[:seconds].to_i.to_s
      date_str += " seconds ago"
    elsif time_difference[:minutes].to_i < 60 
      date_str = time_difference[:minutes].to_i.to_s
      date_str += " minute(s) ago"
    elsif time_difference[:hours].to_i < 24
      date_str = time_difference[:hours].to_i.to_s
      date_str += " hour(s) ago"
    elsif time_difference[:days].to_i < 2
      date_str = time_difference[:days].to_i.to_s
      date_str += " day ago"
    else
      date          = start_time.in_time_zone("America/Los_Angeles")
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
    end
    date_str
  end
end
