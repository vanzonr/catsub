# catsub
Concatenation and substitution command

Catsub substitutes every value for each variable in each word of a
template file.

## Usage:

    catsub [-h] [-e] [TEMPLATEFILE] [%VARNAME VALUE1 VALUE2 ... ]*

Arguments:

     TEMPLATEFILE      Name of a file containg the template with
                       variables of the from %VARNAME; If no file name
                       is given, or the name is '-', catsub will read
                       from standard input;
     %VARNAME          Variable name to substitute;
     VALUE1 VALUE2 ... Values to substitute for the variable;
     -e, --escape      Escaped percentage in template are returned escaped;
     -h, --help        Show this help page.

## Prerequisites

  -  Python 2.5+

## Installation

Simply copy the script to a location in the PATH.

## Notes

   - The name of the TEMPLATEFILE may not start with a percent sign.  

   - All variables must start with a percent sign and cannot contain
     whitespace.

   - Substituted values cannot start with a percent sign.

   - Substitution happens only once per variable, i.e., substituted
     values do not undergo subsequent substitutions.

   - When a variable has been given several values to substitute ad
     the variable occurs in a substring of a word in the template,
     that word get repeated. E.g. "echo un%X | catsub %X kind tidy"
     gives "unkind untidy"

   - Substitution happens combinatorically within a word. E.g. a word
     "%X,%Y" in the template, when processed with "catsub %X a b %Y c d"
     becomes "a,c a,d b,c b,d". Combinatorics can be circumvented by
     quoting the replacement values, i.e.  "catsub %X 'a b' %Y 'c d'"
     gives "a b,c d".

   - Substitution uses the longest possible variable name. E.g. in
     "%HELLOWORLD", both %HELLO and %HELLOWORLD could be substituted
     if values for both are specified on the catsub command, but it is
     the longer %HELLOWORLD that gets used.
   
   - Percentage signs in the template can escape substitution by
     prepeding them with a slash, i.e., '\%'.  Every '\%' in the
     template will be replaced by '%' unless the -e or --escape
     argument is used in the catsub command.

   - The template cannot use the unicode character '％'.

## Examples

The following examples work when called from a Linux shell (e.g. bash).

     $ echo %HELLO %UNIVERSE | ./catsub %HELLO Hi %UNIVERSE world
     Hi world

     $ echo un%X | catsub %X kind tidy
     unkind untidy
     
     $ echo %X,%Y | catsub %X a b %Y c d
     a,c a,d b,c b,d

     $ echo %X,%Y | catsub %X 'a b' %Y 'c d'
     a b,c d
     
     $ echo %HELLO %UNIVERSE > example.tmpl
     $ ./catsub example.tmpl %HELLO Greetings %UNIVERSE universe!
     Greetings universe!
     $ ./catsub example.tmpl %HELLO Greetings %UNI Uni
     Greetings UniVERSE
     $ ./catsub example.tmpl %HELLO Greetings %UNI Uni %UNIVERSE world!
     Greetings world!

