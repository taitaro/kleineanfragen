module NkSyncable
  extend ActiveSupport::Concern

  def nomenklatura_sync!
    if has_attribute?(:body) || has_attribute?(:body_id)
      state = body.state
    elsif self.class.method_defined? :bodies
      fail 'This entity appears in multiple bodies' if bodies.size > 1
      state = bodies.first.state
    else
      fail 'No body attribute found'
    end

    model_name = self.class.name.underscore.pluralize

    dataset = Nomenklatura::Dataset.new("ka-#{model_name}-#{state.downcase}")
    entity = dataset.entity_by_name(name).dereference
    if entity.invalid?
      # invalid: remove self
      papers.clear
      destroy
    elsif entity.name != name
      new_name = entity.name
      if self.class.exists?(name: new_name)
        # new name and person exists? reassign papers, remove self
        other = self.class.find_by_name(new_name)
        other.papers << papers
        other.save!
        papers.clear
        destroy
      else
        # new name and person doesn't exist? rename self
        self.name = new_name
        save!
      end
    else
      self
    end
  end
end