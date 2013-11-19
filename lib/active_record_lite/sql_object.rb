require_relative './associatable'
require_relative './db_connection' # use DBConnection.execute freely here.
require_relative './mass_object'
require_relative './searchable'

class SQLObject < MassObject
  extend Searchable
  extend Associatable
  
  # sets the table_name
  def self.set_table_name(table_name)
    @table_name = table_name
  end

  # gets the table_name
  def self.table_name
    @table_name
  end

  # querys database for all records for this type. (result is array of hashes)
  # converts resulting array of hashes to an array of objects by calling ::new
  # for each row in the result. (might want to call #to_sym on keys)
  def self.all
    results = DBConnection.execute(<<-SQL)
    
    SELECT
      * 
    FROM
      "#{table_name}"      
    SQL
    
    parse_all(results) 
  end

  # querys database for record of this type with id passed.
  # returns either a single object or nil.
  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      "#{table_name}"
    WHERE
      id = ?
    SQL
    parse_all(results).first
  end

  # executes query that creates record in db with objects attribute values.
  # after, update the id attribute with the helper method from db_connection
  def create
    attr_names = self.class.attributes.join(", ")
    num_questions = ("?, " * self.class.attributes.length)[0...-2] #trim last comma and whitespace
    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO 
      #{self.class.table_name} (#{attr_names})
    VALUES 
      (#{num_questions})  
    SQL
    
    self.id = DBConnection.last_insert_row_id
  end

  # executes query that updates the row in the db corresponding to this instance
  # of the class. use "#{attr_name} = ?" and join with ', ' for set string.
  def update
    set_attrs = self.class.attributes.map { |attr| "#{attr} = ?" }.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE 
      #{self.class.table_name}
    SET 
      #{set_attrs}
    WHERE 
      id = ?
    SQL
  end

  # call either create or update depending if id is nil.
  def save
    if self.id
      update
    else
      create
    end
  end

  # helper method to return values of the attributes.
  # takes the attribute names and uses send to map them 
  #to the instance's values for those attributes.
  def attribute_values
    self.class.attributes.map { |attr_name| self.send(attr_name) }
  end
  
end
