# Pepss

SCSS with a simpler syntax.

## Features

* Programmer-friendly syntax.
* Media condition suffixes.
* Automatically detects and compiles dependencies.
* Watches file modifications for instant recompilation.
* Extracts CSS definitions from HTML templates.

## Syntax

The "test.pepss" file shows the available Pepss statements and how they are translated in SCSS.

```cpp
/*
    comment
*/

$variable_123 = 0;    // :

?func_123(    // @function
    $first_argument_1_2_3 
    )
{
    return $first_argument_1_2_3 + 1;    // @return
}

@rule_123(    // @mixin
    $first_argument_1_2_3 = $variable_123,    // :
    $second_argument_1_2_3 = $first_argument_1_2_3 * 2 + func_123( $variable_123 )    // :
    )
{
    $first_argument_1_2_3
    $second_argument_1_2_3
}

$a = 10;    // :
$b = ( ( $a + 1 ) * 2 - 2 ) / 2;    // :
$a = 10;    // :
$c = $b;    // :

$a $b $c
$(a)$(b)px    // #{$a}#{$b}px

$s = '$(a)$(b)px';    // #{$a}#{$b}px
import 'test_include.pepss';    // @import scss

.test
{
    $a
}

?test(    // @function
    $x, 
    $y 
    )
{
    return $x + $y;    // @return
}

%test
{
}

@test(    // @mixin
    $x, 
    $y, 
    $z 
    )
{
    :test;    // @include
    :%test;    // @include
    $w = test( $x, $y ) + $z;    // :
}

@test    // @mixin
{
    :test( 1, 2, 3 );    // @include
}

.test2
{
    >test;    // @extend
    :test( $a, $b, $c);    // @include
}

if $a < $b    // @if
{
    $a $b
}
else if $a > $b    // @else if
{
    $a $b
}
else    // @else
{
    $a $b
}

$a = 1 @ small_min;    // @include media( small_min ) { $a: 1; }
$b = 10 @ "( max-width: $(media_largest_max_em) )";    // @include media( "( max-width: #{$media_largest_max_em} )" )
$c = -1;    // :

$colors = a, b, c;    // :

foreach $color in $colors    // @each $color in $colors
{
}

for $index = 1 .. length( $colors )    // @for $index from 1 through length( $colors )
{
    $color = nth( $colors, $index );
    
    .test_$(color)    // #{$color}
    {
        color : $color;
    }
}

for $a = 1 .. $b    // @for $a from 1 through $b
{
    $a $b $c
}

for $a = 0 >> $b    // @for $a from 0 to $b
{
    $a $b $c
}

$i = 6;    // :

while $i > 0    // @while
{
    $i = $i - 2;    // :
}
```

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html).

Build the executable with the following command line :

```bash
dmd pepss.d
```

## Command line

pepss [options] file.pepss[.html]

### Options
``` 
    --replace PEPSS/ SCSS/ : folder paths to replace to get the SCSS file paths from the PEPSS file paths
    --pause 500 : time to wait before checking the Pepss files again
``` 
### Examples

```bash
pepss main.pepss 
```

This file and all its dependencies will automatically be converted into ".scss" files.

They will then be watched for modifications, and recompiled when needed.

```bash
pepss page.pepss.html
```

If you pass a ".pepss.html" file as an argument, it is automatically split into a ".html" file and a ".pepss" file.

The Pepss code is extracted from these special HTML comments :

* `<!--=` `=-->` : copied code. 
* `<!--#` `#-->` : id code.
* `<!--.` `.-->` : class code.

```html
...
<header class="slider_block">
    <!--=
        // .. SLIDER
    =-->
    <h1 class="slider_title">
        <!--.
            :display( none );
        .-->
        Sed do eiusmod tempor incididunt ut labore et dolore seed magna aliqua.
    </h1>
    ...
        <li class="slider_menu_button">
            <!--.
                :size( 40 * $px, 40 * $px );
                :margin_left( 1 * $px );
            .-->
            <!--.:hover
                :opacity( 0.8 );
            .-->
        </li>
        ...
        <li class="slider_menu_button">
            <a id="slider_middle_icon" class="slider_menu_link" href="#">
                <!--#
                    :background_position( -41px );
                #-->
            </a>
        </li>
        ...
```

The ".pepss.html" file can thus be viewed as normally in a web browser, once the generated ".scss" files have been converted into CSS by the SCSS compiler.
## Version

0.1

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
