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
    along with Pepss.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- STATEMENTS

// .. LIGHTBOX MANAGEMENT

// Manage the click on the lightbox button

$( '.lightbox_button' ).click(
    function( event )
    {
        event.preventDefault();

        // Get the image file path

        var image_file_path = $( this ).attr( "href" );

        // Check if the lightbox screen exists

        if ( $( '#lightbox_screen' ).length > 0 )
        {
            // Update the lightbox container

            $( '#lightbox_container' ).html( '<img id="lightbox_image" src="' + image_file_path + '" />' );

            // Show the lightbox screen

            $( '#lightbox_screen' ).show();
        }
        else
        {
            // Append the lightbox screen to the body

            var lightbox_screen_code =
                '<div id="lightbox_screen">'
                + '<div id="lightbox_container">'
                + '<img id="lightbox_image" src="' + image_file_path + '" />'
                + '</div>'
                + '</div>';

            $( 'body' ).append( lightbox_screen_code );
        }
    }
    );

// Manage the click on the lightbox screen

$( 'body' ).on(
    'click',
    '#lightbox_screen',
    function()
    {
        // Hide the lightbox screen

        $( '#lightbox_screen' ).fadeOut( 400 );
    }
    );
