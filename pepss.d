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

// == LOCAL

// -- IMPORTS

import core.thread;
import std.algorithm : max;
import std.conv : to;
import std.datetime : Clock, SysTime;
import std.file : exists, readText, timeLastModified, write;
import std.path : buildNormalizedPath, dirName;
import std.stdio : writeln;
import std.string : endsWith, indexOf, join, replace, split, startsWith, strip;
import std.regex : matchFirst, regex, replaceAll, replaceFirst, Captures, Regex;

// == GLOBAL

// -- TYPES

class WATCHED_FILE
{
    string
        Path;
    SysTime
        ModificationTime;
    bool
        ItIsCompiled;
        
    // ~~
    
    this(
        string file_path
        )
    {
        Path = file_path;
        ModificationTime = file_path.timeLastModified();
        ItIsCompiled = false;
    }
    
    // ~~
    
    bool HasChanged(
        )
    {
        SysTime
            modification_time;
            
        modification_time = Path.timeLastModified();
        
        if ( modification_time > ModificationTime )
        {
            ModificationTime = modification_time;
            
            return true;
        }
        else
        {
            return false;
        }
    }
}

// -- VARIABLES

int
    PauseDuration;
string
    InputFolderPath,
    OutputFolderPath,
    SpaceText;
WATCHED_FILE[]
    WatchedFileArray;

// -- FUNCTIONS

void PrintFileError( 
    string file_path, 
    int line_index, 
    string message 
    )
{
    writeln( file_path ~ "(" ~ ( line_index + 1 ).to!string() ~ ") : " ~ message );
}

// ~~

string GetSpaceText( 
    int space_count 
    )
{
    if ( space_count <= 0 )
    {
        return "";
    }
    else
    {
        while ( SpaceText.length < space_count )
        {
            SpaceText ~= SpaceText;
        }

        return SpaceText[ 0 .. space_count ];
    }
}

// ~~

string[] ReadLineArray( 
    string file_path 
    )
{
    string
        code;
    string[]
        line_array;
        
    writeln( "Reading file : " ~ file_path );

    code = file_path.readText().replace( "\r", "" ).replace( "\t", "    " );
    
    line_array = code.split( "\n" );

    return line_array;
}

// ~~

void WriteCode( 
    string file_path, 
    string code 
    )
{
    writeln( "Writing file : " ~ file_path ~ " (" ~ Clock.currTime().to!string() ~ ")" );

    file_path.write( code );
}

// ~~

void WriteLineArray( 
    string file_path, 
    string[] line_array 
    )
{
    string
        code;
        
    code = line_array.join( "\n" );
    
    WriteCode( file_path, code );
}

// ~~

string[] CompilePepssLineArray( 
    string[] pepss_line_array, 
    string pepss_file_path 
    )
{
    int
        pepss_line_index,
        space_count,
        stripped_scss_line_count,
        stripped_scss_line_index;
    Regex!char
        else_if_expression,
        else_expression,
        error_expression,
        extend_expression,
        foreach_expression,
        for_to_expression,
        for_toward_expression,
        function_declaration_expression,
        if_expression,
        import_expression,
        include_expression,
        media_condition_expression,
        mixin_declaration_expression,
        mixin_function_declaration_expression,
        print_expression,
        return_expression,
        variable_assignment_expression,
        variable_interpolation_expression,
        variable_minus_assignment_expression,
        variable_plus_assignment_expression,
        variable_slash_assignment_expression,
        variable_star_assignment_expression,
        warn_expression,
        while_expression;
    string
        pepss_line,
        prior_stripped_scss_line,
        space_text,
        stripped_pepss_line,
        stripped_scss_line;
    string[]
        scss_line_array,
        stripped_scss_line_array;

    // ~~

    bool ReplacePepssExpression(
        Regex!char pepss_expression,
        string scss_translation,
        string delegate( string, string ) process_stripped_scss_line = null
        )
    {
        string
            stripped_scss_line;
        Captures!(string, ulong)
            pepss_match;

        if ( process_stripped_scss_line != null )
        {
            pepss_match = stripped_pepss_line.matchFirst( pepss_expression );
        }

        stripped_scss_line = stripped_pepss_line.replaceFirst( pepss_expression, scss_translation );

        if ( stripped_scss_line != stripped_pepss_line )
        {
            if ( process_stripped_scss_line != null )
            {
                stripped_scss_line = process_stripped_scss_line( stripped_scss_line, pepss_match[ 1 ] );

                if ( stripped_scss_line == "" )
                {
                    return false;
                }
            }

            stripped_pepss_line = stripped_scss_line;

            return true;
        }

        return false;
    }

    // ~~

    string WatchImportedFile(
        string stripped_scss_line,
        string imported_file_name
        )
    {
        string
            imported_directory_path,
            imported_file_path;

        imported_directory_path = pepss_file_path.dirName() ~ "/";

        if ( imported_directory_path == "./" )
        {
            imported_directory_path = "";
        }

        imported_file_path = imported_directory_path ~ imported_file_name ~ ".pepss";

        WatchFile( imported_file_path );

        return stripped_scss_line.replace( InputFolderPath, OutputFolderPath );
    }

    // ~~

    string IsMixinName(
        string stripped_scss_line,
        string mixin_name
        )
    {
        if ( mixin_name != "content"
             && mixin_name != "font-face"
             && mixin_name != "import"
             && mixin_name != "keyframes"
             && mixin_name != "-webkit-keyframes"
             && mixin_name != "media" )
        {
            return stripped_scss_line;
        }

        return "";
    }

    // ~~
    
    import_expression = regex( `^import +\'([^']+)\.pepss'(.*$)` );
    return_expression = regex( `^return +(.*$)` );
    if_expression = regex( `^if +(.*$)` );
    else_if_expression = regex( `^else +(.*$)` );
    else_expression = regex( `^else$` );
    while_expression = regex( `^while +(.*$)` );
    foreach_expression = regex( `^foreach +(.*$)` );
    for_to_expression = regex( `^for +(\$[A-Za-z_][A-Za-z0-9_]*) += +(.+) +\.\. +(.*$)` );
    for_toward_expression = regex( `^for +(\$[A-Za-z_][A-Za-z0-9_]*) += +(.+) +>> +(.*$)` );
    print_expression = regex( `^print +(.*$)` );
    warn_expression = regex( `^warn +(.*$)` );
    error_expression = regex( `^error +(.*$)` );
    variable_assignment_expression = regex( `^(\$[A-Za-z_][A-Za-z0-9_]*) +=(.*$)` );
    variable_plus_assignment_expression = regex( `^(\$[A-Za-z_][A-Za-z0-9_]*) +\+=(.*$)` );
    variable_minus_assignment_expression = regex( `^(\$[A-Za-z_][A-Za-z0-9_]*) +-=(.*$)` );
    variable_star_assignment_expression = regex( `^(\$[A-Za-z_][A-Za-z0-9_]*) +\*=(.*$)` );
    variable_slash_assignment_expression = regex( `^(\$[A-Za-z_][A-Za-z0-9_]*) +\/=(.*$)` );
    function_declaration_expression = regex( `^\?([^ ].*$)` );
    mixin_declaration_expression = regex( `^@([A-Za-z0-9_-]*)(.*$)` );
    mixin_function_declaration_expression = regex( `^@([A-Za-z0-9_-]*)(\(.*$)` );
    extend_expression = regex( `^>([^ ].*$)` );
    include_expression = regex( `^:([^ ].*$)` );
    variable_interpolation_expression = regex( `(^.*)\$\(([A-Za-z_][A-Za-z0-9_]*)\)(.*$)` );
    media_condition_expression = regex( `(^.*) @ ([^;]*);(.*$)` );

    for ( pepss_line_index = 0;
          pepss_line_index < pepss_line_array.length;
          ++pepss_line_index )
    {
        pepss_line = pepss_line_array[ pepss_line_index ];
        stripped_pepss_line = pepss_line.strip();
        space_count = pepss_line.indexOf( stripped_pepss_line ).to!int();

        if ( ReplacePepssExpression( import_expression, "@import '$1.scss'$2", &WatchImportedFile )
             || ReplacePepssExpression( return_expression, "@return $1" )
             || ReplacePepssExpression( if_expression, "@if $1" )
             || ReplacePepssExpression( else_if_expression, "@else $1" )
             || ReplacePepssExpression( else_expression, "@else" )
             || ReplacePepssExpression( while_expression, "@while $1" )
             || ReplacePepssExpression( foreach_expression, "@each $1" )
             || ReplacePepssExpression( for_to_expression, "@for $1 from $2 through $3" )
             || ReplacePepssExpression( for_toward_expression, "@for $1 from $2 to $3" )
             || ReplacePepssExpression( print_expression, "@debug $1" )
             || ReplacePepssExpression( warn_expression, "@warn $1" )
             || ReplacePepssExpression( error_expression, "@error $1" )
             || ReplacePepssExpression( variable_assignment_expression, "$1:$2" )
             || ReplacePepssExpression( variable_plus_assignment_expression, "$1: $1 +$2" )
             || ReplacePepssExpression( variable_minus_assignment_expression, "$1: $1 -$2" )
             || ReplacePepssExpression( variable_star_assignment_expression, "$1: $1 *$2" )
             || ReplacePepssExpression( variable_slash_assignment_expression, "$1: $1 /$2" )
             || ReplacePepssExpression( function_declaration_expression, "@function $1" )
             || ReplacePepssExpression( mixin_declaration_expression, "@mixin $1$2", &IsMixinName )
             || ReplacePepssExpression( mixin_function_declaration_expression, "@mixin $1$2" )
             || ReplacePepssExpression( extend_expression, "@extend $1" )
             || ReplacePepssExpression( include_expression, "@include $1" ) )
        {
        }

        while ( ReplacePepssExpression( variable_interpolation_expression, "$1#{$$$2}$3" ) )
        {
        }

        ReplacePepssExpression( media_condition_expression, "@include media( $2 )\n{\n    $1;$3\n}" );

        space_text = GetSpaceText( space_count );
        stripped_scss_line_array = stripped_pepss_line.split( "\n" );
        stripped_scss_line_count = stripped_scss_line_array.length.to!int();

        if ( stripped_pepss_line != ""
			 && stripped_pepss_line != "}"
             && ( prior_stripped_scss_line == "}"
                  || ( prior_stripped_scss_line != "{"
                       && stripped_scss_line_count > 1 ) ) )
        {
            scss_line_array ~= "";
        }

        for ( stripped_scss_line_index = 0;
              stripped_scss_line_index < stripped_scss_line_count;
              ++stripped_scss_line_index )
        {
            stripped_scss_line = stripped_scss_line_array[ stripped_scss_line_index ];

            if ( stripped_scss_line == "" )
            {
                scss_line_array ~= "";
            }
            else
            {
                scss_line_array ~= space_text ~ stripped_scss_line;
            }

            prior_stripped_scss_line = stripped_scss_line;
        }
    }

    return scss_line_array;
}

// ~~

void CompilePepssFile( 
    string pepss_file_path 
    )
{
    string
        scss_file_path;
    string[]
        pepss_line_array,
        scss_line_array;
    
    if ( pepss_file_path.endsWith( ".pepss" ) )
    {
        scss_file_path = ( pepss_file_path[ 0 .. $ - 6 ] ~ ".scss" ).replace( InputFolderPath, OutputFolderPath );
        
        pepss_line_array = ReadLineArray( pepss_file_path );
        scss_line_array = CompilePepssLineArray( pepss_line_array, pepss_file_path );
        
        WriteLineArray( scss_file_path, scss_line_array );
    }
    else
    {
        writeln( "*** ERROR : Invalid file extension : " ~ pepss_file_path );
    }
}

// ~~

void SplitFile( 
    string split_file_path, 
    string html_file_name, 
    string css_extension, 
    string html_extension 
    )
{
    int
        block_space_count,
        line_index,
        removed_space_count,
        space_count;
    string    
        class_attribute,
        class_comment_argument,
        css_code,
        css_file_path,
        html_code,
        html_file_path,
        id_attribute,
        id_comment_argument,
        line,
        stripped_line;
    string[]
        line_array;
    Captures!(string, ulong)
        class_attribute_match,
        class_comment_match,
        id_attribute_match,
        id_comment_match;
    Regex!char
        class_attribute_expression,
        class_comment_expression,
        id_attribute_expression,
        id_comment_expression;
        
    css_file_path = html_file_name ~ css_extension;
    html_file_path = html_file_name ~ html_extension;
    
    line_array = ReadLineArray( split_file_path );
    
    html_code = "";
    css_code = "";
    removed_space_count = -1;
    
    id_comment_expression = regex( `<!--#(.*)` );
    class_comment_expression = regex( `<!--\.(.*)` );
    id_attribute_expression = regex( `<[a-z]+.* id="([^"]+)"` );
    class_attribute_expression = regex( `<[a-z]+.* class="([^"]+)"` );

    for ( line_index = 0;
          line_index < line_array.length;
          ++line_index )
    {
        line = line_array[ line_index ];
        stripped_line = line.strip();
        space_count = line.indexOf( stripped_line ).to!int();

        id_comment_match = stripped_line.matchFirst( id_comment_expression );
        class_comment_match = stripped_line.matchFirst( class_comment_expression );

        if ( !id_comment_match.empty
             || !class_comment_match.empty
             || stripped_line == "<!--=" )
        {
            removed_space_count = space_count + 4;
            block_space_count = 0;

            id_comment_argument = "";
            class_comment_argument = "";

            if ( !id_comment_match.empty )
            {
                id_comment_argument = id_comment_match[ 1 ];

                if ( id_attribute == "" )
                {
                    PrintFileError( split_file_path, line_index, "missing id attribute" );
                }
            }
            else if ( !class_comment_match.empty )
            {
                class_comment_argument = class_comment_match[ 1 ];

                if ( class_attribute == "" )
                {
                    PrintFileError( split_file_path, line_index, "missing class attribute" );
                }
            }
        }
        else if ( stripped_line == "=-->"
                  || stripped_line == "#-->"
                  || stripped_line == ".-->" )
        {
            if ( stripped_line != "=-->"
                 && id_comment_argument == ""
                 && class_comment_argument == "" )
            {
                css_code ~= "}\n";
            }

            css_code ~= "\n";
            removed_space_count = -1;

            id_comment_argument = "";
            class_comment_argument = "";
        }
        else if ( removed_space_count >= 0 )
        {
            if ( ( id_comment_argument != ""
                   || class_comment_argument != "" )
                 && stripped_line != ""
                 && !stripped_line.startsWith( "//" ) )
            {
                if ( id_comment_argument != null )
                {
                    css_code ~= "#" ~ id_attribute ~ id_comment_argument ~ "\n{\n";
                    id_comment_argument = null;
                }
                else if ( class_comment_argument != null )
                {
                    css_code ~= "." ~ class_attribute ~ class_comment_argument ~ "\n{\n";
                    class_comment_argument = null;
                }

                block_space_count = 4;
            }

            css_code
                ~= GetSpaceText( max( space_count - removed_space_count, 0 ) + block_space_count )
                   ~ stripped_line
                   ~ "\n";
        }
        else
        {
            html_code ~= line ~ "\n";

            id_attribute_match = stripped_line.matchFirst( id_attribute_expression );

            if ( !id_attribute_match.empty )
            {
                id_attribute = id_attribute_match[ 1 ];
            }

            class_attribute_match = stripped_line.matchFirst( class_attribute_expression );

            if ( !class_attribute_match.empty )
            {
                class_attribute = class_attribute_match[ 1 ];
            }
        }
    }

    WriteCode( css_file_path, css_code );
    WriteCode( html_file_path, html_code );

    if ( css_extension == ".pepss" )
    {
        CompilePepssFile( css_file_path );
    }
}

// ~~

void CompileFile( 
    ref WATCHED_FILE watched_file
    )
{
    string
        file_path;
    Captures!(string, ulong)
        file_path_match;
    Regex!char
        file_path_expression;
        
    if ( !watched_file.ItIsCompiled )
    {
        watched_file.ItIsCompiled = true;
        
        file_path = watched_file.Path;
        
        writeln( "Compiling file : " ~ file_path );

        file_path_expression = regex( `(.*)(\.[a-z]*)(\.[a-z]*)$` );
        
        file_path_match = file_path.matchFirst( file_path_expression );

        if ( !file_path_match.empty )
        {
            SplitFile( file_path, file_path_match[ 1 ], file_path_match[ 2 ], file_path_match[ 3 ] );
        }
        else
        {
            CompilePepssFile( file_path );
        }

        watched_file.ItIsCompiled = false;
    }
}

// ~~ 

bool IsWatchedFile(
    string watched_file_path
    )
{
    foreach( watched_file; WatchedFileArray )
    {
        if ( watched_file.Path == watched_file_path )
        {
            return true;
        }
    }
    
    return false;
}

// ~~

void WatchFile( 
    string file_path 
    )
{
    WATCHED_FILE
        watched_file;

    file_path = file_path.buildNormalizedPath().replace( "\\", "/" );

    if ( !IsWatchedFile( file_path ) )
    {
        writeln( "Watching file : " ~ file_path );
        
        if ( file_path.exists() )
        {
            watched_file = new WATCHED_FILE( file_path );
            
            WatchedFileArray ~= watched_file;
                    
            CompileFile( watched_file );
        }
        else
        {
            writeln( "*** ERROR : Invalid file path : " ~ file_path );
        }
    }
}

// ~~

void WatchFiles(
    )
{
    int
        watched_file_index;
    WATCHED_FILE
        watched_file;

    writeln( "Watching files..." );

    for ( ; ; )
    {
        for ( watched_file_index = 0;
              watched_file_index < WatchedFileArray.length;
              ++watched_file_index )
        {
            watched_file = WatchedFileArray[ watched_file_index ];
            
            if ( watched_file.HasChanged() )
            {
                CompileFile( watched_file );
            }
        }
        
        Thread.sleep( dur!("msecs")( PauseDuration ) );
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        option;

    argument_array = argument_array[ 1 .. $ ];

    SpaceText = " ";

    InputFolderPath = "PEPSS/";
    OutputFolderPath = "SCSS/";
    PauseDuration = 500;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        if ( option == "--replace"
             && argument_array.length >= 3 )
        {
            InputFolderPath = argument_array[ 1 ];
            OutputFolderPath = argument_array[ 2 ];

            argument_array = argument_array[ 3 .. $ ];
        }
        else if ( option == "--pause"
             && argument_array.length >= 2 )
        {
            PauseDuration = argument_array[ 1 ].to!int();

            argument_array = argument_array[ 2 .. $ ];
        }
        else
        {
            writeln( "*** ERROR : Invalid option : " ~ option );

            argument_array = argument_array[ 1 .. $ ];
        }
    }

    if ( argument_array.length == 1 )
    {
        WatchFile( argument_array[ 0 ] );

        WatchFiles();
    }
    else
    {
        writeln( "*** ERROR : Invalid arguments" );
        writeln( "Usage :" );
        writeln( "    pepss [options] file.pepss" );
        writeln( "Options :" );
        writeln( "    --replace PEPSS/ SCSS/" );
        writeln( "    --pause 500" );
        writeln( "Sample :" );
        writeln( "    pepss file.pepss" );
    }
}
