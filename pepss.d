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

class FILE
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

bool
    FilesAreWatched;
int
    PauseDuration;
string
    InputFolderPath,
    OutputFolderPath,
    SpaceText;
FILE[]
    FileArray;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
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
    
    line_array = code.split( '\n' );

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
        
    code = line_array.join( '\n' );
    
    WriteCode( file_path, code );
}

// ~~

string[] CompilePepssLineArray( 
    string[] pepss_line_array, 
    string pepss_file_path 
    )
{
    int
        space_count,
        split_scss_line_count;
    string
        prior_scss_line,
        space_text,
        stripped_scss_line;
    string[]
        scss_line_array,
        split_scss_line_array;
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

    // ~~

    bool ReplaceExpression(
        Regex!char expression,
        string translation,
        string delegate( string, string ) process_stripped_scss_line = null
        )
    {
        string
            processed_stripped_scss_line;
        Captures!(string, ulong)
            match;

        match = stripped_scss_line.matchFirst( expression );

        if ( !match.empty )
        {
            processed_stripped_scss_line = stripped_scss_line.replaceFirst( expression, translation );

            if ( process_stripped_scss_line != null )
            {
                processed_stripped_scss_line = process_stripped_scss_line( processed_stripped_scss_line, match[ 1 ] );

                if ( processed_stripped_scss_line == "" )
                {
                    return false;
                }
            }

            stripped_scss_line = processed_stripped_scss_line;

            return true;
        }

        return false;
    }

    // ~~

    string AddImportedFile(
        string processed_stripped_scss_line,
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

        AddFile( imported_file_path );

        return processed_stripped_scss_line.replace( InputFolderPath, OutputFolderPath );
    }

    // ~~

    string IsMixinName(
        string processed_stripped_scss_line,
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
            return processed_stripped_scss_line;
        }
        else
        {
            return "";
        }
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

    prior_scss_line = "";

    foreach ( pepss_line; pepss_line_array )
    {
        stripped_scss_line = pepss_line.strip();
        space_count = pepss_line.indexOf( stripped_scss_line ).to!int();

        if ( ReplaceExpression( import_expression, "@import '$1.scss'$2", &AddImportedFile )
             || ReplaceExpression( return_expression, "@return $1" )
             || ReplaceExpression( if_expression, "@if $1" )
             || ReplaceExpression( else_if_expression, "@else $1" )
             || ReplaceExpression( else_expression, "@else" )
             || ReplaceExpression( while_expression, "@while $1" )
             || ReplaceExpression( foreach_expression, "@each $1" )
             || ReplaceExpression( for_to_expression, "@for $1 from $2 through $3" )
             || ReplaceExpression( for_toward_expression, "@for $1 from $2 to $3" )
             || ReplaceExpression( print_expression, "@debug $1" )
             || ReplaceExpression( warn_expression, "@warn $1" )
             || ReplaceExpression( error_expression, "@error $1" )
             || ReplaceExpression( variable_assignment_expression, "$1:$2" )
             || ReplaceExpression( variable_plus_assignment_expression, "$1: $1 +$2" )
             || ReplaceExpression( variable_minus_assignment_expression, "$1: $1 -$2" )
             || ReplaceExpression( variable_star_assignment_expression, "$1: $1 *$2" )
             || ReplaceExpression( variable_slash_assignment_expression, "$1: $1 /$2" )
             || ReplaceExpression( function_declaration_expression, "@function $1" )
             || ReplaceExpression( mixin_declaration_expression, "@mixin $1$2", &IsMixinName )
             || ReplaceExpression( mixin_function_declaration_expression, "@mixin $1$2" )
             || ReplaceExpression( extend_expression, "@extend $1" )
             || ReplaceExpression( include_expression, "@include $1" ) )
        {
        }

        while ( ReplaceExpression( variable_interpolation_expression, "$1#{$$$2}$3" ) )
        {
        }

        ReplaceExpression( media_condition_expression, "@include media( $2 )\n{\n    $1;$3\n}" );

        space_text = GetSpaceText( space_count );

        split_scss_line_array = stripped_scss_line.split( '\n' );
        split_scss_line_count = split_scss_line_array.length.to!int();

        if ( split_scss_line_count == 0 )
        {
            split_scss_line_array ~= "";
        }

        if ( stripped_scss_line != ""
			 && stripped_scss_line != "}"
             && ( prior_scss_line == "}"
                  || ( prior_scss_line != "{"
                       && split_scss_line_count > 1 ) ) )
        {
            scss_line_array ~= "";
        }

        foreach ( split_scss_line; split_scss_line_array )
        {
            if ( split_scss_line == "" )
            {
                scss_line_array ~= "";
            }
            else
            {
                scss_line_array ~= space_text ~ split_scss_line;
            }

            prior_scss_line = split_scss_line;
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
        PrintError( "Invalid file extension : " ~ pepss_file_path );
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
    bool
        class_attribute_is_set,
        class_comment_is_set,
        id_attribute_is_set,
        id_comment_is_set;
    int
        block_space_count,
        removed_space_count,
        space_count;
    string    
        class_attribute,
        class_comment,
        css_code,
        css_file_path,
        html_code,
        html_file_path,
        id_attribute,
        id_comment,
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
    
    id_attribute_expression = regex( `<[a-z]+.* id="([^"]+)"` );
    class_attribute_expression = regex( `<[a-z]+.* class="([^"]+)"` );
    id_comment_expression = regex( `<!--#(.*)` );
    class_comment_expression = regex( `<!--\.(.*)` );
    
    id_attribute_is_set = false;
    class_attribute_is_set = false;
    id_comment_is_set = false;
    class_comment_is_set = false;

    foreach ( line; line_array )
    {
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

            id_comment_is_set = false;
            class_comment_is_set = false;

            if ( !id_comment_match.empty )
            {
                id_comment = id_comment_match[ 1 ];
                id_comment_is_set = true;
            }
            else if ( !class_comment_match.empty )
            {
                class_comment = class_comment_match[ 1 ];
                class_comment_is_set = true;
            }
        }
        else if ( stripped_line == "=-->"
                  || stripped_line == "#-->"
                  || stripped_line == ".-->" )
        {
            if ( stripped_line != "=-->"
                 && !id_comment_is_set
                 && !class_comment_is_set )
            {
                css_code ~= "}\n";
            }

            css_code ~= "\n";
            removed_space_count = -1;

            id_comment_is_set = false;
            class_comment_is_set = false;
        }
        else if ( removed_space_count >= 0 )
        {
            if ( ( id_comment_is_set
                   || class_comment_is_set )
                 && stripped_line != ""
                 && !stripped_line.startsWith( "//" ) )
            {
                if ( id_comment_is_set )
                {
                    css_code ~= "#" ~ id_attribute ~ id_comment ~ "\n{\n";
                    id_comment_is_set = false;
                }
                else if ( class_comment_is_set )
                {
                    css_code ~= "." ~ class_attribute ~ class_comment ~ "\n{\n";
                    class_comment_is_set = false;
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
                id_attribute_is_set = true;
            }

            class_attribute_match = stripped_line.matchFirst( class_attribute_expression );

            if ( !class_attribute_match.empty )
            {
                class_attribute = class_attribute_match[ 1 ];
                class_attribute_is_set = true;
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
    ref FILE file
    )
{
    string
        file_path;
    Captures!(string, ulong)
        file_path_match;
    Regex!char
        file_path_expression;
        
    if ( !file.ItIsCompiled )
    {
        file.ItIsCompiled = true;
        
        file_path = file.Path;        
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

        file.ItIsCompiled = false;
    }
}

// ~~ 

bool IsFile(
    string file_path
    )
{
    foreach( file; FileArray )
    {
        if ( file.Path == file_path )
        {
            return true;
        }
    }
    
    return false;
}

// ~~

void AddFile( 
    string file_path 
    )
{
    FILE
        file;

    file_path = file_path.buildNormalizedPath().replace( "\\", "/" );

    if ( !IsFile( file_path ) )
    {
        if ( file_path.exists() )
        {
            file = new FILE( file_path );
            
            FileArray ~= file;
                    
            CompileFile( file );
        }
        else
        {
            PrintError( "Invalid file path : " ~ file_path );
        }
    }
}

// ~~

void WatchFiles(
    )
{
    int
        file_index;
    FILE
        file;

    writeln( "Watching files..." );

    for ( ; ; )
    {
        for ( file_index = 0;
              file_index < FileArray.length;
              ++file_index )
        {
            file = FileArray[ file_index ];
            
            if ( file.HasChanged() )
            {
                CompileFile( file );
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
    FilesAreWatched = false;
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
        else if ( option == "--watch" )
        {
            FilesAreWatched = true;

            argument_array = argument_array[ 1 .. $ ];
        }
        else if ( option == "--pause"
             && argument_array.length >= 2 )
        {
            PauseDuration = argument_array[ 1 ].to!int();

            argument_array = argument_array[ 2 .. $ ];
        }
        else
        {
            PrintError( "Invalid option : " ~ option );

            argument_array = argument_array[ 1 .. $ ];
        }
    }

    if ( argument_array.length == 1 )
    {
        AddFile( argument_array[ 0 ] );

        if ( FilesAreWatched )
        {
            WatchFiles();
        }
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    pepss [options] file.pepss[.html]" );
        writeln( "Options :" );
        writeln( "    --replace PEPSS/ SCSS/" );
        writeln( "    --pause 500" );
        writeln( "Examples :" );
        writeln( "    pepss file.pepss" );
        writeln( "    pepss file.pepss.html" );
        
        PrintError( "Invalid arguments" );
    }
}
