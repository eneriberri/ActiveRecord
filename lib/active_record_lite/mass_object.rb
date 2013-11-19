class MassObject
  # takes a list of attributes.
  # creates getters and setters.
  # adds attributes to whitelist.
  
  def self.my_attr_accessor(*attr_names)
    attr_names.each do |attr_name|
      define_method("#{attr_name}") do
        instance_variable_get("@#{attr_name}")
      end
    
      define_method("#{attr_name}=") do |val|
        instance_variable_set("@#{attr_name}", val)
      end
    end
  end
  
  def self.my_attr_accessible(*attributes)
    @attributes = [].tap do |arr|
      attributes.each do |attr_name|
        arr << attr_name.to_sym
      end
    end
    
    @attributes.each do |name|
      self.my_attr_accessor(name)
    end
  end
  
  # returns list of attributes that have been whitelisted.
  def self.attributes
    @attributes
  end

  # takes an array of hashes.
  # returns array of objects.
  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  # takes a hash of { attr_name => attr_val }.
  # checks the whitelist.
  # if the key (attr_name) is in the whitelist, the value (attr_val)
  # is assigned to the instance variable.
  def initialize(params = {})
    params.each do |attr_name, val|
      if(self.class.attributes.include? attr_name.to_sym)
        self.send("#{attr_name}=", val)
      else
        raise "mass assignment to unregistered attribute #{attr_name}"
      end      
    end
  end
end