%{
#include "parser.tab.hh"
#include <sstream>
#define YY_DECL extern "C" int yylex()
std::stringstream ss;
%}

%option noyywrap

%x strlit

%%

"int"                     { return INT_TYPE; }
"float"                   { return FLOAT_TYPE; }
"str"                  { return STRING_TYPE; }
"bool"                    { return BOOL_TYPE; }
"("                       { return LPAREN; }
")"                       { return RPAREN; }
"{"                       { return LBRACE; }
"}"                       { return RBRACE; }
","                       { return COMMA; }
"def"                     { return DEF; }
"if"                      { return IF; }
"else"                    { return ELSE; }
"elif"                    { return ELIF; }
"for"                     { return FOR; }
"while"                   { return WHILE; }
"break"                   { return BREAK; }
"return"                  { return RETURN; }
"="                       { return EQUALS_SIGN; }
"||"                      { return LOGICAL_OR; }
"&&"                      { return LOGICAL_AND; }
"!"                       { return LOGICAL_NOT; }
">"                       { return GREATER_THAN; }
"<"                       { return LESS_THAN; }
">="                      { return GREATER_EQUAL; }
"<="                      { return LESS_EQUAL; }
"=="                      { return EQUALS; }
"!="                      { return NOT_EQUAL; }
"+"                       { return PLUS; }
"-"                       { return MINUS; }
"*"                       { return MULTIPLY; }
"/"                       { return DIVIDE; }
"%"                       { return MODULO; }
"False" | "True" {yylval.boolval = strcmp(yytext, "True") == 0; return BOOL_LITERAL;}
[0-9]+                    { yylval.intval = atoi(yytext); return INT_LITERAL; }
[0-9]+"."[0-9]*           { yylval.fltval = atof(yytext); return FLOAT_LITERAL; }
\"                        { BEGIN strlit; ss.str(std::string()); }
<strlit>[^\\"\n]*         { ss << yytext; }
<strlit>\\n               { ss << '\n'; }
<strlit>\\t               { ss << '\t'; }
<strlit>\\[\\"]           { ss << yytext[1]; }
<strlit>\"                { yylval.strval = strdup((char *) ss.str().c_str()); BEGIN 0; return STRING_LITERAL; }
<strlit>\\.               { printf("Lexing error: invalid escape character '%s'\n", yytext); }
<strlit>\n                { printf("Lexing error: found newline in string\n"); }
"true"                    { yylval.boolval = true; return BOOL_LITERAL; }
"false"                   { yylval.boolval = false; return BOOL_LITERAL; }
[a-zA-Z_][a-zA-Z_0-9]*    { yylval.strval = strdup(yytext); return ID; }
[ \t]                     {}
.                         { printf("Unrecognized character %c\n", *yytext); }

%%

