# This is primitive.rb, a small code snippet that let's you define a class
# that is only intended to hold certain attributes with one line of code.
#
# Author::      Fabian Streitel (karottenreibe)
# Copyright::   Copyright (c) 2009 Fabian Streitel
# License::     Boost Software License 1.0
#               For further information regarding this license, you can go to
#               http://www.boost.org/LICENSE_1_0.txt
#               or read the file LICENSE distributed with this software.
# Homepage::    none - at the moment
# Git repo::    none
#

##
# Defines a class called +name+ with the specified read- and writable
# +attributes+ in the module +mod+, which by default is the module
# you called the function from.
# Also defines an initialize function that initializes all the attributes.
# Furthermore it will execute any given block as if it were executed during
# class creation, thus allowing you to add additional methods to the created
# class.
#
# So, calling
#   primitive :Foo, [:bar, :loop] do
#       def inspect
#           "fu!"
#       end
#   end
#
# is the same as
#   class Foo
#       attr_accessor :bar
#       attr_accessor :loop
#
#       def initialize bar, loop
#           @bar, @loop = bar, loop
#       end
#
#       def inspect
#           "fu!"
#       end
#   end
#
# and
#   module Bacon
#       primitive :Foo, [:bar, :loop]
#   end
#
# is the same as
#   primitive :Foo, [:bar, :loop], Bacon
#
# is the same as
#   module Bacon
#       class Foo
#           attr_accessor :bar
#           attr_accessor :loop
#
#           def initialize bar, loop
#               @bar, @loop = bar, loop
#           end
#       end
#   end
#
def primitive name, attributes = [], mod = self, &block
    mod = Object if mod.class == Object

    # class statement
    str = "class #{name}\n"

    # if no attributes are given, we only create the class
    unless attributes.empty?
        # the accumulators
        acc = []
        instance = []
        vars = []

        # for each given attribute
        attributes.each { |k|
            # create an accessor
            acc << "attr_accessor :#{k}"
            # an instance variable
            instance << "@#{k}"
            # and a variable
            vars << "#{k}"
        }

        # add the accessors
        str << acc.join("\n")
        # start initialize method
        str << "\ndef initialize "
        # parameters of initialize
        str << vars.join(", ") + "\n"
        # assign @foo, @bar = foo, bar
        str << instance.join(", ") + " = " + vars.join(", ")
        # end of initialize
        str << "\nend"
    end

    # end of class statement
    str << "\nend"

    # evaluate in module
    mod.class_eval str

    # evaluate any given block on the created class
    (eval "#{mod}::#{name}").class_eval &block if block_given?
end

