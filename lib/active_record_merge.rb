module ActiveRecordMerge
  # merges the other record into this one.
  # whenever possible, prefers the attributes and associated objects on this record
  def merge!(other_record)
    raise 'Records must be of the same class' unless self.class == other_record.class

    # first, merge all regular attributes (this record's attributes get priority)
    self.attributes.keys.each do |attr|
      next if attr =~ /_id$/ or attr == self.class.primary_key
      self.send("#{attr}=", other_record.send(attr)) if self.send(attr).nil?
    end

    # then, iterate through all associations and fix any keys referring to the other_record
    self.class.reflect_on_all_associations.each do |association|
      next if association.options[:through]

      other_associated = other_record.send(association.name)
      case association.macro
        when :has_one, :belongs_to
        # prefer this record's associated object
        self.send("#{association.name}=", other_associated) if self.send(association.name).nil?

        when :has_many, :has_and_belongs_to_many
        other_associated.each {|a| self.send(association.name) << a}
      end
    end

    # save this record and delete the other, in a transaction
    transaction {self.save! && other_record.destroy}
  end
end