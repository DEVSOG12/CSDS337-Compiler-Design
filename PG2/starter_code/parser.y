%code requires {
  //This is a special block which places required dependency code inside the parser header file
  #include <stdio.h>
  #include <stdlib.h>
  #include <vector>
  #include <string>
  #include <cstring>
  #include <variant>
  #include <iostream>
  
  extern FILE *yyin;
}

%{
  /* This is the main code which preceeds the parser definition.
     Most of this is function and variable declarations needed for generating the parse tree.
     You will need to call these functions inside your parser code actions to generate the parse tree. */
  
  #include "parser.tab.hh"

  typedef struct node {
    union {
      const char *name;
      int intval;
      double fltval;
      bool boolval;
    } key;
    int type; //0 str, 1 int, 2 flt, 3 bool
    std::vector<node *> children;
    int counter;
  } node;

  node *make_node_str(std::string);
  node *make_node_int(int);
  node *make_node_flt(double);
  node *make_node_book(bool);
  void add_child(node *, node *);
  void free_tree(node *);

  extern "C" int yylex(void);
  void yyerror(const char *s);
  void save_to_dot(FILE *);
  int trav_and_write(FILE *, node *);

  node *root;
  int ncounter;
%}

//Define the "program" nonterminal to be the one which we are trying to match
%start program

//Print detailed syntax errors when possible
%define parse.error verbose

 /* This defines the union, which controls the possible types of semantic values for symbols.
    In the lexer, the variable yylval is of this type. This is where yylval.intval was defined, for example */
%union {
  int intval;
  double fltval;
  char *strval;
  bool boolval;
  struct node *nodeval;
}

/* This defines the tokens to be included in the enum. Any token returned by the lexer must be in this list.
   Therefore, any tokens you add to the lexer should also be added here (there will be a lot of them)
   Certain tokens have been added here, since they were used in the examples below. However, you will need to add more */
%token ID INT_TYPE SEMICOLON IF ELSE EQUALS_SIGN VARIADIC INT_LITERAL STRING_LITERAL FLOAT_LITERAL BOOL_LITERAL LPAREN RPAREN LBRACE RBRACE ARITH_MINUS

 /* This defines the types of the semantic values for each of the terminal and nonterminal symbols.
    Since the context-free grammar is provided for you, we've done this part for you, for your convenience.
    Note that most nonterminals (aside from literals) have a semantic value which is a node in the parse tree.
    If you change this section, it may break the built-in code which draws the parse tree, so avoid changing it if possible. */

%type <nodeval> decList dec type varDec varDecs funDec funDef params paramList stmt exprStmt stmts selStmt iterStmt jumpStmt expr orExpr andExpr unaryRelExpr relExpr relop term factor primary call args constant id

%type <strval> ID STRING_LITERAL
%type <intval> int_lit INT_LITERAL
%type <fltval> flt_lit FLOAT_LITERAL
%type <boolval> BOOL_LITERAL

 /* The grammar, as written, contains one shift-reduce conflict in the if/else statement
    Bison is capable of handling this on its own, but you will need to uncomment the following line so that it doesn't give you a warning.
    The %expect n directive tells Bison that there should be n shift-reduce conflicts. It gives a warning if the actual number is different.
    Note that, for LALR(1) parsers like this, reduce-reduce conflicts are harder to handle, so make sure you don't have any*/
 //%expect 2

%%
 //For the sake of example, the first few productions are done for you:

program: decList {
  //Since this is the start node, we set the global variable "root" so that we can access it later
  root = make_node_str("program");
  //Then, we add the first child symbol (the decList) as a child of this node.
  add_child(root, $1);
 } | /* epsilon */ { 
  root = make_node_str("program");
 };

decList: decList dec {
  /* This is a list of declarations. When we eventually compile this code,
     we will need to transform its semantic value into a more appropriate data structuce (like an std::vector).
     For now, it will be easier to generate the parse tree if all productions are node-valued. */
  $$ = make_node_str("decList");
  //Again, after making the current node, add the children:
  add_child($$, $1);
  add_child($$, $2);
 } | dec {
  $$ = make_node_str("decList");
  add_child($$, $1);
 };

dec: funDef {
  $$ = make_node_str("dec");
  add_child($$, $1);
 } | funDec {
  $$ = make_node_str("dec");
  add_child($$, $1);
 };


type: INT_TYPE {
  $$ = make_node_str("type_int");
 } /* fill in remaining data types (float, string, bool, void) */ ;

varDec: /* fill in */
varDecs: /* fill in */

funDec: type id LPAREN params RPAREN SEMICOLON {
  //This defines a production for a function declaration (not a definition).
  $$ = make_node_str("funDec");
  add_child($$, $1);
  add_child($$, $2);
  add_child($$, $4);
 };
funDef: /* fill in */
params: /* fill in */
paramList: /* fill in */

/* The default behavior in bison is for a symbol's semantic value to take the same value as its first child
   This happens whenever you don't specify a code action to tell it to do otherwise.
   We can save some space by making use of this: */
stmt: exprStmt | LBRACE stmts RBRACE {$$ = $2;} | selStmt | iterStmt | jumpStmt ;
exprStmt: /* fill in */
stmts: /* fill in */
selStmt: IF LPAREN expr RPAREN stmt {
  $$ = make_node_str("selStmt");
  add_child($$, $3);
  add_child($$, $5);
 } | IF LPAREN expr RPAREN stmt ELSE stmt {
  /* fill in */
 };

iterStmt: /* fill in */
jumpStmt: /* fill in */

expr: orExpr | id EQUALS_SIGN expr {
  $$ = make_node_str("assignment");
  add_child($$, $1);
  add_child($$, $3);
 };
orExpr: /* fill in */
andExpr: /* fill in */
unaryRelExpr: /* fill in */
relExpr: /* fill in */
relop: /* fill in */
term: /* fill in */
factor: /* fill in */
primary: /* fill in */

call: id LPAREN args RPAREN {
  $$ = make_node_str("call");
  add_child($$, $1);
  add_child($$, $3);
 } | id LPAREN RPAREN {
  /* fill in */
 };
args: /* fill in */
constant: int_lit {
  $$ = make_node_int($1);
 } /* fill in constants for remaining types (float, string, bool) */ ;

//For integer literals, we handle the minus sign at the parser level as follows:
int_lit: INT_LITERAL | ARITH_MINUS INT_LITERAL {$$ = -1 * $2;};
flt_lit: /* fill in */

//This is just a convenience - this nonterminal doesn't really serve a purpose:
id: ID {$$ = make_node_str($1);};

%%
int main(int argc, char **argv) {
  //yyparse() calls the parser which Bison writes for us. It parses the input, then returns 1 if there was an error
  if(yyparse() == 1) {
    printf("Irrecoverable error state, aborting\n");
    return 1;
  }

  /* By calling yyparse(), we've generated our entire parse tree, starting at the global variable "root"
     We can now use that information to draw the tree.
     This part has been done for you. */

  FILE *f = fopen("parsetree.dot", "w");
  fprintf(f, "/* This file was generated by the parser. */\n");
  save_to_dot(f);
  fclose(f);

  free_tree(root);
  return 0;
}

node *make_node_str(std::string name) {
  node *n = (node *) malloc(sizeof(node));
  n->key.name = strdup(name.c_str());
  std::vector<node *> v;
  n->children = v;
  n->type = 0;
  return n;
}

node *make_node_int(int val) {
  node *n = (node *) malloc(sizeof(node));
  n->key.intval = val;
  std::vector<node *> v;
  n->children = v;
  n->type = 1;
  return n;
}

node *make_node_flt(double val) {
  node *n = (node *) malloc(sizeof(node));
  n->key.fltval = val;
  std::vector<node *> v;
  n->children = v;
  n->type = 2;
  return n;
}

node *make_node_bool(bool val) {
  node *n = (node *) malloc(sizeof(node));
  n->key.boolval = val;
  std::vector<node *> v;
  n->children = v;
  n->type = 3;
  return n;
}

void add_child(node *n, node *child) {
  n->children.push_back(child);
}

void free_tree(node *n) {
  for(int i = 0; i < n->children.size(); i++) {
    node *c = n->children[i];
    if(!c) continue;
    free(c);
  }
  free(n);
}

void save_to_dot(FILE *f) {
  fprintf(f, "graph g {\n");
  root->counter = 0;
  trav_and_write(f, root);
  fprintf(f, "}\n");
}

int trav_and_write(FILE *f, node *n) {
  switch(n->type) {
  case 0:
    if(n->key.name[0] == '"') //hacky fix for string literals
      fprintf(f, "n%d [label=%s] ;\n", n->counter, n->key.name);
    else
      fprintf(f, "n%d [label=\"%s\"] ;\n", n->counter, n->key.name);
    break;
  case 1:
    fprintf(f, "n%d [label=\"%d\"] ;\n", n->counter, n->key.intval);
    break;
  case 2:
    fprintf(f, "n%d [label=\"%03.f\"] ;\n", n->counter, n->key.fltval);
    break;
  case 3:
    fprintf(f, "n%d [label=%s] ;\n", n->counter, n->key.boolval ? "true" : "false");
    break;
  default:
    break;
  }
  if(n->children.empty()) return n->counter;
  int prev_counter = n->counter;
  for(int i = 0; i < n->children.size(); i++) {
    node *c = n->children[i];
    if(!c) continue; //some nodes are null, e.g. empty lists
    c->counter = prev_counter + 1;
    fprintf(f, "n%d -- n%d\n", n->counter, c->counter);
    prev_counter = trav_and_write(f, c);
  }
  return prev_counter;
}

void yyerror(const char *s) {
  fprintf(stderr, "error: %s\n", s);
}
