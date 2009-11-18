module StElsewhere
  
  # Specifies a one-to-many association across database connections.
  # This is currently an incomplete implementation and does not yet use all of the options supported by has_many
  #
  # The following methods for retrieval and query of collections of associated objects will be added:
  #
  # [collection<<(object, ...)]
  #   TODO: Adds one or more objects to the collection by setting their foreign keys to the collection's primary key.
  # [collection=objects]
  #   Replaces the collections content by deleting and adding objects as appropriate.
  # [collection_singular_ids]
  #   Returns an array of the associated objects' ids
  # [collection_singular_ids=ids]
  #   Replace the collection with the objects identified by the primary keys in +ids+
  # [collection.empty?]
  #   Returns +true+ if there are no associated objects.
  # [collection.size]
  #   Returns the number of associated objects.
  #
  # (*Note*: +collection+ is replaced with the symbol passed as the first argument, so
  # <tt>has_many :clients</tt> would add among others <tt>clients.empty?</tt>.)
  #
  # === Example
  #
  # Example: A Firm class declares <tt>has_many_elsewhere :clients</tt>, which will add:
  # * <tt>Firm#clients</tt> (similar to <tt>Clients.find :all, :conditions => ["firm_id = ?", id]</tt>)
  # * <tt>Firm#clients=</tt>
  # * <tt>Firm#client_ids</tt>
  # * <tt>Firm#client_ids=</tt>
  # * <tt>Firm#clients.empty?</tt> (similar to <tt>firm.clients.size == 0</tt>)
  # * <tt>Firm#clients.size</tt> (similar to <tt>Client.count "firm_id = #{id}"</tt>)
  #
  # === Supported options
  # [:through]
  #   Specifies a Join Model through which to perform the query. You can only use a <tt>:through</tt> query through a 
  #   <tt>belongs_to</tt> <tt>has_one</tt> or <tt>has_many</tt> association on the join model.
  #
  # Option examples:
  #   has_many_elsewhere :subscribers, :through => :subscriptions
  def has_many_elsewhere(association_id, options = {}, &extension)
    association_class = association_id.to_s.classify.constantize
    through = options[:through]
    raise ArgumentError.new("You must include :through => association for has_many_elsewhere") if not through
    collection_accessor_methods_elsewhere(association_id, association_class, through)
  end
  
  # Dynamically adds all accessor methods for the has_many_elsewhere association
  def collection_accessor_methods_elsewhere(association_id, association_class, through)
    association_singular = association_id.to_s.singularize
    association_plural   = association_id.to_s
    through_association_singular = through.to_s.singularize
    my_class       = self
    my_foreign_key = self.to_s.foreign_key
    target_association_class = association_singular.classify.constantize
    target_association_foreign_key = association_singular.foreign_key
    
    # Hospital#doctor_ids
    define_method("#{association_singular}_ids") do
      self.send("#{association_plural}").map{|a| a.id}
    end

    # Hospital#doctors
    define_method("#{association_plural}") do
      through_class = through.to_s.singularize.camelize.constantize
      through_association_ids = self.send("#{through.to_s.singularize}_ids")
      through_associations = through_class.find(through_association_ids)
      through_associations.collect{|through_association| through_association.send("#{association_singular}")} || []
    end

    # Hospital#doctors=
    define_method("#{association_plural}=") do |new_associations|
      through_class        = through.to_s.singularize.camelize.constantize
      current_associations = self.send("#{association_singular}_ids")
      desired_associations = self.class.associations_to_association_ids(new_associations)
      
      removed_target_associations = current_associations - desired_associations
      new_target_associations     = desired_associations - current_associations
      
      self.send("remove_#{association_singular}_associations", through_class, removed_target_associations)
      self.send("add_#{association_singular}_associations", through_class, association_id, new_target_associations)
    end

    # Hospital#doctor_ids=
    define_method("#{association_singular}_ids=") do |new_association_ids|
      self.send("#{association_plural}=", new_association_ids)
    end

    # Hospital#remove_doctor_associations (private)
    define_method("remove_#{association_singular}_associations") do |through_class, removed_target_associations|
      association_instances_to_remove = 
        through_class.send("find_all_by_#{my_foreign_key}_and_#{target_association_foreign_key}", self.id, removed_target_associations)
      through_class.delete(association_instances_to_remove)
    end

    # Hospital#add_doctor_associations (private)
    define_method("add_#{association_singular}_associations") do |through_class, association_id, target_association_ids|
      targets_to_add = target_association_class.find(target_association_ids)
      targets_to_add.each do |target_association|
        new_association = through_class.new(my_foreign_key => self.id, target_association_foreign_key => target_association.id)
        new_association.save
      end
    end

    private "remove_#{association_singular}_associations".to_sym, "add_#{association_singular}_associations".to_sym

  end

  def associations_to_association_ids(associations)
    ids = []
    if associations && !associations.empty?
      associations.reject!{|a| a.to_s.empty? }
      association_class = associations.first.class.to_s
      ids = case association_class
            when "String"
              associations
            when "Fixnum"
              associations.map{|a| a.to_i }
            else
              associations.map{|a| a.id}
      end
    end
    ids
  end

  private :collection_accessor_methods_elsewhere

end

ActiveRecord::Base.extend StElsewhere