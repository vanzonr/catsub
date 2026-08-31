# catsub
Concatenation and substitution command

Catsub substitutes every value for each variable in each word of a
template file.

## Usage:

    catsub [--help] [-s] [-u] [-D|-dSTR] [TEMPLATEFILES] [%VARNAME VALUE1 VALUE2 ... ]*

Arguments:

     TEMPLATEFILES     Name(s) of file(s) containg the template with
                       variables of the from %VARNAME; If no file name
                       is given, or the name is '-', catsub will read
                       from standard input;
     %VARNAME          Variable name to substitute;
     VALUE1 VALUE2 ... Values to substitute for the variable. A value
                       may also be specified as @file:PATH, in which case
                       each line in PATH is treated as one substitution value;
     -s                Print statistics to stderr on resolved and unresolved variables.
     -u                Escaped percentage in template are returned unescaped;
     -D                Use newline to divide multiple substituted values
     -dSTR             Use STR to divide multiple substituted values
     --help            Show this help page.

## Prerequisites

  -  Python 2.4+

## Installation

Simply copy the script to a location in the PATH.

## Testing

The repository includes a small bash test suite in test.sh.
It exercises typical substitutions, error cases, and the @file: trust policy
so regressions are caught quickly.

## Notes


   - The names of the template files may not start with a percent sign.  

   - All variables must start with a percent sign and cannot contain
     whitespace.

   - Substituted values cannot start with a percent sign.

   - Values may be loaded from a file using @file:PATH; each line in the
     file becomes one substitution value.

   - @file: sources are restricted to the current working directory,
     one of the (sub) directories in which the template files reside,
     or a user-owned /tmp or /dev/shm file.

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
     template will be remain a '\%' unless the -u argument is used in
     the catsub command, in which case, they are replaced by '%'.

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

     $ printf '%s\n' red blue > values.txt
     $ echo %X | ./catsub %X @file:values.txt
     red blue
     
     $ echo %HELLO %UNIVERSE > example.tmpl
     $ ./catsub example.tmpl %HELLO Greetings %UNIVERSE universe!
     Greetings universe!
     $ ./catsub example.tmpl %HELLO Greetings %UNI Uni
     Greetings UniVERSE
     $ ./catsub example.tmpl %HELLO Greetings %UNI Uni %UNIVERSE world!
     Greetings world!

