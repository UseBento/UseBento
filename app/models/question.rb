class Question
  include Mongoid::Document
  
  field :name,       type: String
  field :label,      type: String
  field :type,       type: Symbol
  field :values,     type: Array
  field :required,   type: Boolean

  has_many :answer
  embedded_in :service

  def validate_answer(answer_obj) 
    answer = answer_obj.answer

    if !self.required && answer.strip.length == 0
      return true

    elsif (self.type == :email)
      return answer.email?

    elsif [:full_name, :text, :keywords].member?(self.type)
      return answer.strip.length > 0

    elsif self.type == :integer
      int = answer.to_i
      if self.values
        return int >= self.values[0] && int <= self.values[1]
      end
      return answer.strip.match(/^[0-9]+$/)

    elsif self.type == :enum
      return self.values.member?(answer)
    end

    true
  end
      
    
end
