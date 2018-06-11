// -- STATEMENTS

// .. MENU MANAGEMENT

// Find the header container

var header_container = $( '.header_container' );

// Manage the click on the header menu button

$( '.header_menu_icon' ).click(
    function( event )
    {
        event.preventDefault();

        // Check if the menu is open

        if ( !header_container.hasClass( 'header_menu_open' ) )
        {
            // Open the menu

            header_container.addClass( 'header_menu_open' );
        }
        else
        {
            // Close the menu

            header_container.removeClass( 'header_menu_open' );
        }
    }
    );
