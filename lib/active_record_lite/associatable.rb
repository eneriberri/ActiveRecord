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
  #returns hash with keys being the assoc name, and val being the assoc
  def assoc_params
    @assoc_params ||= {}
    @assoc_params
  end

  def belongs_to(name, params = {})
    
    assoc = BelongsToAssocParams.new(name, params)
    assoc_params[name] = assoc

    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(assoc.foreign_key))
      SELECT 
        *
      FROM
        #{assoc.other_table}
      WHERE 
        #{assoc.other_table}.#{assoc.primary_key} = ?
      SQL

      assoc.other_class.parse_all(results).first
    end
  end

  def has_many(name, params = {})
    assoc = HasManyAssocParams.new(name, params, )
    assoc_params[name] = assoc
    
    define_method(name) do
      results = DBConnection.execute(<<-SQL, self.send(assoc.primary_key))
      SELECT
      *
      FROM
        #{assoc.other_table}
      WHERE
        #{assoc.other_table}.#{assoc.foreign_key} = ?
    SQL
      
    assoc.other_class.parse_all(results)    
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
