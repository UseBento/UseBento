class Field
  include Mongoid::Document
  
  field :name,       type: String
  field :label,      type: String
  field :type,       type: Symbol
  field :values,     type: Array
  field :required,   type: Boolean

  embedded_in :service
end
