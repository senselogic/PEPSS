/*
    This file is part of the Pepss distribution.

    https://github.com/senselogic/PEPSS

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Pepss is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Pepss is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
*/

// == GLOBAL

// -- STATEMENTS

// .. INLINE SPACE REMOVAL

// Find container nodes

var container_node_table = document.querySelectorAll( '*[class*="container"]' );

for ( var container_node_index = container_node_table.length - 1;
      container_node_index >= 0;
      --container_node_index )
{
    var container_node = container_node_table[ container_node_index ];

    // Find their child nodes

    var child_node_table = container_node.childNodes;

    for ( var child_node_index = child_node_table.length - 1;
          child_node_index >= 0;
          --child_node_index )
    {
        var child_node = child_node_table[ child_node_index ];

        // Check if it's a blank node

        if ( child_node.nodeType == 3
             && child_node.nodeValue.match( /\s*/ ) )
        {
            // Remove it

            container_node.removeChild( child_node );
        }
    }
}
