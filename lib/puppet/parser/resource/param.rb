 # The parameters we stick in Resources.
class Puppet::Parser::Resource::Param
    attr_accessor :name, :value, :source, :line, :file
    include Puppet::Util
    include Puppet::Util::Errors
    include Puppet::Util::MethodHelper

    def initialize(hash)
        set_options(hash)
        requiredopts(:name, :value, :source)
        @name = symbolize(@name)
    end

    def inspect
        "#<#{self.class} @name => #{self.name}, @value => #{self.value}, @source => #{self.source.type}>"
    end

    def line_to_i
        return line ? Integer(line) : nil
    end
    
    # Store a new parameter in a Rails db.
    def to_rails(db_resource)
        values = value.is_a?(Array) ? value : [value]
        values = values.map { |v| v.to_s }

        param_name = Puppet::Rails::ParamName.find_or_create_by_name(self.name.to_s)
        line_number = line_to_i()

        return values.collect do |v|
            db_resource.param_values.create(:value => v.to_s,
                                           :line => line_number,
                                           :param_name => param_name)
        end
    end

    def modify_rails_values(db_values)
        #dev_warn if db_values.nil? || db_values.empty? 

        values_to_remove(db_values).each { |remove_me|
            Puppet::Rails::ParamValue.delete(remove_me)
        }
        line_number = line_to_i()
        values_to_add(db_values).each { |add_me| 
            db_resource = db_values[0].resource
            db_param_name = db_values[0].param_name
            db_resource.param_values.create(:value => add_me.to_s,
                                           :line => line_number,
                                           :param_name => db_param_name)
        }
    end
    
    def to_s
        "%s => %s" % [self.name, self.value]
    end
    
    def values_to_remove(db_values)
        values = value.is_a?(Array) ? value : [value]
        values = values.map { |v| v.to_s }
        line_number = line_to_i()
        db_values.collect do |db|
            db unless (db.line == line_number && 
                       values.find { |v| 
                         v == db.value 
                       } )
        end.compact
    end

    def values_to_add(db_values)
        values = value.is_a?(Array) ? value : [value]
        values = values.map { |v| v.to_s }
        line_number = line_to_i()
        values.collect do |v|
            v unless db_values.find { |db| (v == db.value && 
                                         line_number == db.line) }
        end.compact
    end
end

# $Id$
