if __FILE__ == $0
    $:.unshift '..'
    $:.unshift '../../lib'
    $puppetbase = "../../../../language/trunk"
end

require 'puppet'
#require 'puppet/type/typegen/filetype'
#require 'puppet/type/typegen/filerecord'
require 'test/unit'

#class TestFileType < Test::Unit::TestCase
class TestFileType
    def disabled_setup
        Puppet[:loglevel] = :debug if __FILE__ == $0

        @passwdtype = Puppet.type(:filetype)["passwd"]
        if @passwdtype.nil?
            assert_nothing_raised() {
                @passwdtype = Puppet.type(:filetype).createtype(
                    :name => "passwd"
                )
                @passwdtype.addrecord(
                    :name => "user",
                    :splitchar => ":",
                    :fields => %w{name password uid gid gcos home shell}
                )
            }
        end

        @syslogtype = Puppet.type(:filetype)["syslog"]
        if @syslogtype.nil?
            assert_nothing_raised() {
                @syslogtype = Puppet.type(:filetype).createtype(
                    :escapednewlines => true,
                    :name => "syslog"
                )
                @syslogtype.addrecord(
                    :name => "data",
                    :regex => %r{^([^#\s]+)\s+(\S+)$},
                    :joinchar => "\t",
                    :fields => %w{logs dest}
                )
                @syslogtype.addrecord(
                    :name => "comment",
                    :regex => %r{^(#.*)$},
                    :joinchar => "", # not really necessary...
                    :fields => %w{comment}
                )
                @syslogtype.addrecord(
                    :name => "blank",
                    :regex => %r{^(\s*)$},
                    :joinchar => "", # not really necessary...
                    :fields => %w{blank}
                )
            }
        end

    end

    def disabled_test_passwd1_nochange
        file = nil
        type = nil
        assert_nothing_raised() {
            file = @passwdtype.new("/etc/passwd")
        }
        assert_nothing_raised() {
            file.retrieve
        }

        assert(file.insync?)

        contents = ""
        ::File.open("/etc/passwd") { |ofile|
            ofile.each { |line|
                contents += line
            }
        }

        assert_equal(
            contents,
            file.to_s
        )

    end

    def disabled_test_passwd2_change
        file = nil
        type = nil
        newfile = tempfile()
        Kernel.system("cp /etc/passwd #{newfile}")
        assert_nothing_raised() {
            file = @passwdtype.new(newfile)
        }
        assert_nothing_raised() {
            file.retrieve
        }

        assert(file.insync?)

        assert_nothing_raised() {
            file.add("user") { |obj|
                obj["name"] = "yaytest"
                obj["password"] = "x"
                obj["uid"] = "10000"
                obj["gid"] = "10000"
                obj["home"] = "/home/yaytest"
                obj["gcos"] = "The Yaytest"
                obj["shell"] = "/bin/sh"
            }
        }

        assert(!file.insync?)

        assert_nothing_raised() {
            file.evaluate
        }

        assert(file.insync?)

        assert_nothing_raised() {
            file.delete("bin")
        }

        assert(!file.insync?)

        assert_nothing_raised() {
            file.evaluate
        }

        assert(file.insync?)
    end

    def disabled_test_syslog_nochange
        file = nil
        type = nil
        syslog = File.join($puppetbase, "examples/root/etc/debian-syslog.conf")
        assert_nothing_raised() {
            file = @syslogtype.new(syslog)
        }
        assert_nothing_raised() {
            file.retrieve
        }

        assert(file.insync?)

        contents = ""
        ::File.open(syslog) { |ofile|
            ofile.each { |line|
                contents += line
            }
        }
        #assert_equal(
        #    contents,
        #    file.to_s
        #)

    end
end

# $Id$
