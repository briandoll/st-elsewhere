module StElsewhere
  
  def has_many_elsewhere(association_id, options = {}, &extension)
    association_class = association_id.to_s.classify.constantize
    collection_accessor_methods_elsewhere(association_id, association_class, options[:through])
  end
  
  def collection_accessor_methods_elsewhere(association_id, association_class, through)

    define_method("#{association_id.to_s.singularize}_ids") do
      self.send("#{association_id.to_s}").map{|a| a.id}
    end

    define_method("#{association_id.to_s}") do
      through_class = through.to_s.singularize.camelize.constantize
      through_association_ids = self.send("#{through.to_s.singularize}_ids")
      through_associations = through_class.find(through_association_ids)
      through_associations.collect{|through_association| through_association.send("#{association_id.to_s.singularize}")} || []
    end

    define_method("#{association_id.to_s}=") do |new_associations|
      association_class    = through.to_s.singularize.camelize.constantize
      current_associations = self.send("#{through.to_s.singularize}_ids")
      removed_associations = current_associations - new_associations
      new_associations     = new_associations - current_associations
      
      self.send("remove_#{association_id.to_s.singularize}_associations", association_class, removed_associations)
      self.send("add_#{association_id.to_s.singularize}_associations", association_class, association_id, new_associations)
    end

    define_method("#{association_id.to_s.singularize}_ids=") do |new_association_ids|
      self.send("#{association_id.to_s}=", new_association_ids)
    end

    define_method("remove_#{association_id.to_s.singularize}_associations") do |association_class, associations|
      associations.each do |association|
        association_class.delete(association)
      end
    end

    define_method("add_#{association_id.to_s.singularize}_associations") do |through_class, association_id, associations|
      myself = "#{self.class.to_s.downcase}_id"
      my_buddy = "#{association_id.to_s.singularize}_id"
      associations.each do |association|
        my_buddy_id = Fixnum.eql?(association.class) ? association : association.id
        new_association = through_class.new(myself => self.id, my_buddy => my_buddy_id)
        new_association.save
      end
    end

    private "remove_#{association_id.to_s.singularize}_associations".to_sym, "add_#{association_id.to_s.singularize}_associations".to_sym

  end

end