# This is Dome, a pure Ruby HTML DOM parser with very simple XPath support.
#
# If you want to find out more or need a tutorial, go to
# http://dome.rubyforge.org/
# You'll find a nice wiki there!
#
# Author::      Fabian Streitel (karottenreibe)
# Copyright::   Copyright (c) 2008 Fabian Streitel
# License::     Boost Software License 1.0
#               For further information regarding this license, you can go to
#               http://www.boost.org/LICENSE_1_0.txt
# Homepage::    http://dome.rubyforge.org/
# Git repo::    http://rubyforge.org/scm/?group_id=7589
#
# This file contains the CSS Selector related classes and functions.
# It also extends the Document class to provide CSS Selector functionality.
#

module Dome

    ##
    # Enhances the Tree class with Hpricot-like functionality for using XPath.
    #
    class Tree
        def / path
        end

        def % path
        end

        def each path
        end
    end

    ##
    # Stores a CSS3 Selector over a Document.
    # Can be used to iterate over all the Elements identified by the Selector
    # and to extract all of them or only the first one.
    #
    class Selector
    end

end
                        
