class Attachment
  include Mongoid::Document

  field :uploaded_date,    type: DateTime
  field :name,             type: String
  field :is_amazon_s3,     type: Boolean, default: false

  attr_accessor   :attachment
  embedded_in     :message
  embedded_in     :project
  mount_uploader  :attachment, AttachmentUploader, mount_on: :attachment_filename

  def url
    if message
      "/attachment/" +
        self.message.parent_project.id + "/" +
        self.message.id + "/" + self.id + "/" +
        (self.name.gsub(/[^-_A-Za-z0-9.]/, '_')  || "")
    elsif project
      "/attachment/" +
        self.project.id + "/" +
        self.id + "/" +
        (self.name.gsub(/[^-_A-Za-z0-9.]/, '_')  || "")
    end
  end

  def mime
    MIME::Types.type_for(self.name)[0] || MIME::Type.new("file/" + (self.name || ""))
  end

  def is_image?
    ['image/jpeg', 'image/gif', 'image/png'].member? self.mime.content_type
  end

  def filesize
    my_size = self.attachment.size
    if (my_size == 0 || !my_size)
      return "0b"
    else
      sizes = {b:  1,
               kb: 1024,
               mb: 1024 * 1024,
               gb: 1024 * 1024 * 1024}
      sizes.each do |label, size|
             if (my_size > size && my_size < (size * 1024))
               return (my_size.to_f / size.to_f).round(2).to_s + label.to_s
             end
           end
    end
  end

  def shortname
    if name.length < 20
      name
    else
      name.slice(0,20) + "..."
    end
  end
end
