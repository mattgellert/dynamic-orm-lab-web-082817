require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    column_names = DB[:conn].execute("PRAGMA table_info(#{table_name})").map { |column_info|
      column_info["name"]
    }
    column_names.each { |column|
      attr_accessor column.to_sym
    }
  end

  # self.column_names.each { |column|
  #   attr_accessor column.to_sym
  # }

  def initialize(options={})
    options.each { |property, value|
      self.send("#{property}=", value)
    }
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|column| column == "id"}.join(", ")
  end

  def values_for_insert
    self.col_names_for_insert.split(", ").map {|column|
      "'#{send(column)}'"
    }.join(", ")
  end

  def save
    sql = <<-SQL
      INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})
    SQL

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = <<-SQL
      SELECT *
      FROM #{table_name}
      WHERE name = ?
    SQL

    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    sql = <<-SQL
      SELECT *
      FROM #{table_name}
      WHERE #{attribute.flatten[0]} = '#{attribute.flatten[1]}'
    SQL

    DB[:conn].execute(sql)
  end

end
