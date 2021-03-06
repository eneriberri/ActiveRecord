require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :foreign_key, :other_class_name, :primary_key

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] || name.to_s.camelcase
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
    @primary_key = params[:primary_key] || :id
  end

end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] || name.to_s.singularize.camelcase
    @foreign_key = params[:foreign_key] || "#{self_class.name.underscore}_id".to_sym
    @primary_key = params[:primary_key] || :id
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    assoc = BelongsToAssocParams.new(name, params)
    assoc_params[name] = assoc

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(assoc.foreign_key))
        SELECT *
          FROM #{assoc.other_table}
         WHERE #{assoc.other_table}.#{assoc.primary_key} = ?
      SQL

      assoc.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    assoc = HasManyAssocParams.new(name, params, self)
    assoc_params[name] = assoc

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(assoc.primary_key))
        SELECT *
          FROM #{assoc.other_table}
         WHERE #{assoc.other_table}.#{assoc.foreign_key} = ?
      SQL

      assoc.other_class.parse_all(results)
    end
  end
  
  
  #for example:
  # class Cat < SQLObject
  #   belongs_to :human
  #   has_one_through :house, :human, :house
  # end
  # 
  # class Human < SQLObject
  #   belongs_to :house
  # end
  # 
  # class House < SQLObject
  # end
  
  # SELECT
  # houses.*
  # FROM
  # humans JOIN houses
  # ON
  # humans.house_id = houses.id
  # WHERE
  # humans.id = pk1
  
  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      #grabbing the association we created in belongs_to
      params1 = self.class.assoc_params[assoc1] #Cat.assoc_params[:human]
      
      #house
      params2 = params1.other_class.assoc_params[assoc2] #Human.assoc_params[:house]

      primary_key1 = self.send(params1.foreign_key)
      results = DBConnection.execute(<<-SQL, primary_key1)
        SELECT 
          #{params2.other_table}.*
        FROM 
          #{params2.other_table}
        JOIN 
          #{params1.other_table}
        ON 
          #{params1.other_table}.#{params2.foreign_key}
               = #{params2.other_table}.#{params2.primary_key}
        WHERE 
         #{params1.other_table}.#{params1.primary_key}
               = ?
      SQL

      params2.other_class.parse_all(results).first
    end
  end
end
