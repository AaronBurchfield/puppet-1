require 'puppet'

module Puppet
    # The transportable objects themselves.  Basically just a hash with some
    # metadata and a few extra methods.
    class TransObject < Hash
        attr_accessor :type, :name, :file, :line

        attr_writer :tags

        def initialize(name,type)
            self[:name] = name
            @type = type
            @name = name
            #self.class.add(self)
        end

        def longname
            return [self.type,self[:name]].join('--')
        end

        def tags
            return @tags
        end

        def to_s
            return "%s(%s) => %s" % [@type,self[:name],super]
        end

        def to_type(parent = nil)
            if parent
                self[:parent] = parent
            end
            retobj = nil
            if type = Puppet::Type.type(self.type)
                unless retobj = type.create(self)
                    return nil
                end
                retobj.file = @file
                retobj.line = @line
            else
                raise Puppet::Error.new("Could not find object type %s" % self.type)
            end

            if defined? @tags and @tags
                #Puppet.debug "%s(%s) tags: %s" % [@type, @name, @tags.join(" ")]
                retobj.tags = @tags
            end

            if parent
                parent.push retobj
            end

            return retobj
        end
    end
    #------------------------------------------------------------

    #------------------------------------------------------------
    # just a linear container for objects
    class TransBucket < Array
        attr_accessor :name, :type, :file, :line

        def push(*args)
            args.each { |arg|
                case arg
                when Puppet::TransBucket, Puppet::TransObject
                    # nada
                else
                    raise Puppet::DevError,
                        "TransBuckets cannot handle objects of type %s" %
                            arg.class
                end
            }
            super
        end

        def to_type(parent = nil)
            # this container will contain the equivalent of all objects at
            # this level
            #container = Puppet::Component.new(:name => @name, :type => @type)
            unless defined? @name
                raise Puppet::DevError, "TransBuckets must have names"
            end
            unless defined? @type
                Puppet.debug "TransBucket '%s' has no type" % @name
            end
            hash = {
                :name => @name,
                :type => @type
            }
            if defined? @parameters
                @parameters.each { |param,value|
                    Puppet.debug "Defining %s on %s of type %s" %
                        [param,@name,@type]
                    hash[param] = value
                }
            else
                Puppet.debug "%s[%s] has no parameters" % [@type, @name]
            end

            if parent
                hash[:parent] = parent
            end
            container = Puppet.type(:component).create(hash)

            if parent
                parent.push container
            end

            # unless we successfully created the container, return an error
            unless container
                Puppet.warning "Got no container back"
                return nil
            end

            self.each { |child|
                # the fact that we descend here means that we are
                # always going to execute depth-first
                # which is _probably_ a good thing, but one never knows...
                unless  child.is_a?(Puppet::TransBucket) or
                        child.is_a?(Puppet::TransObject)
                    raise Puppet::DevError,
                        "TransBucket#to_type cannot handle objects of type %s" %
                            child.class
                end

                # Now just call to_type on them with the container as a parent
                unless obj = child.to_type(container)
                    # nothing; we assume the method already warned
                    Puppet.warning "Could not create child %s" % child.name
                end
            }

            # at this point, no objects at are level are still Transportable
            # objects
            return container
        end

        def param(param,value)
            unless defined? @parameters
                @parameters = {}
            end
            @parameters[param] = value
        end

    end
    #------------------------------------------------------------
end

# $Id$
