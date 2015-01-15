class Attachment
  include Mongoid::Document
  
  field :uploaded_date,    type: DateTime
  field :name,             type: String
  field :data,             type: BSON::Binary

  embedded_in :message

  def url
    "/attachment/" + self.message.project.id + "/" + self.message.id + "/" + self.id
  end

  def mime
    MIME::Types.type_for(self.name)[0]
  end

  def is_image?
    ['image/jpeg', 'image/gif', 'image/png'].member? self.mime.content_type
  end
end
