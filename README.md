# Pepss

Lightweight SCSS preprocessor.

## Features

* Less verbose syntax than standard SCSS.
* Media condition suffixes.
* Automatically detects and compiles dependencies.
* Watches file modifications for instant recompilation.
* Extracts CSS definitions from HTML templates.

## Sample

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

Install the [SCSS compiler](http://sass-lang.com/install).

## Command line

``` 
pepss [options] file.pepss[.html]
``` 

### Options

``` 
--replace PEPSS/ SCSS/ : folder paths to replace to get the SCSS file paths from the PEPSS file paths
--pause 500 : time to wait before checking the Pepss files again
``` 

### Examples

```bash
pepss main.pepss 
```

Converts "main.pepss" and its dependencies into ".scss" files.

```bash
pepss --watch main.pepss 
```

Converts "main.pepss" and its dependencies into ".scss" files, and watches them for modifications.

```bash
pepss --watch main.pepss.html
```

Splits "main.pepss.html" into "main.html" and "main.pepss", converts "main.pepss" and its dependencies into ".scss" files, and watches them for modifications.

```bash
sass --watch main.scss:main.css
```

Converts "main.scss" and its dependencies into "main.css".

## Pepss code extraction

The Pepss code is extracted from special HTML comments :

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

Once the generated ".scss" files have been processed by the SCSS compiler, you can immediately refresh the ".pepss.html" file in your web browser to see the result.

## Version

0.1

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
