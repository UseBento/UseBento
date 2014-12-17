class Question
  include Mongoid::Document
  
  field :name,       type: String
  field :label,      type: String
  field :type,       type: Symbol
  field :values,     type: Array
  field :required,   type: Boolean

  embedded_in :service

  def validate_answer(answer_obj) 
    answer          = answer_obj.answer
    valid           = true
    invalid_message = ""

    if !self.required && answer.strip.length == 0
      valid = true

    elsif (self.type == :email)
      valid = answer.email?
      invalid_message =  "Please enter a valid email"

    elsif [:full_name, :text, :keywords].member?(self.type)
      valid = answer.strip.length > 0
      invalid_message = "This field is required"

    elsif self.type == :integer
      int = answer.to_i
      if self.values
        valid = int >= self.values[0] && int <= self.values[1]
        invalid_message = ("Must be between " + self.values[0].to_s + " and " 
                           + self.values[1].to_s)
      else
        valid = answer.strip.match(/^[0-9]+$/)
        invalid_message = "This field is required"
      end

    elsif self.type == :enum
      valid = self.values.member?(answer)
      invalid_message = "Invalid entry"
    end

    if (valid)
      return {valid: true}
    else
      return {valid:    false,
              answer:   answer,
              question: self,
              message:  invalid_message}
    end
  end
end
