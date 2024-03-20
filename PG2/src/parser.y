%code requires {
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string>
#include <cstring>
#include "parser.tab.hh"

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
  node *make_node_bool(bool);
  void add_child(node *, node *);
  void free_tree(node *);

  extern "C" int yylex(void);
  void yyerror(const char *s);
  void save_to_dot(FILE *);
  int trav_and_write(FILE *, node *);

  node *root;
  int ncounter;
%}

%start program

//Print detailed syntax errors when possible
%define parse.error verbose


%union {
    char *strval;
    int intval;
    double fltval;
    bool boolval;
    struct node *nval;
}

%token <strval> STRING_LITERAL ID STR_CONST
%token <intval> INT_LITERAL
%token <fltval> FLOAT_LITERAL
%token <boolval> BOOL_LITERAL
%token INT_TYPE FLOAT_TYPE STRING_TYPE BOOL_TYPE VOID_TYPE
%token SEMICOLON LPAREN RPAREN LBRACE RBRACE COMMA
%token IF ELSE WHILE BREAK RETURN
%token EQUALS_SIGN LOGICAL_OR LOGICAL_AND LOGICAL_NOT
%token GREATER_THAN LESS_THAN GREATER_EQUAL LESS_EQUAL EQUALS NOT_EQUAL
%token PLUS MINUS MULTIPLY DIVIDE MODULO

%type <nval> program type varDec varDecs stmts stmt expr
%type <nval> exprStmt compoundStmt selStmt iterStmt jumpStmt orExpr
%type <nval> andExpr unaryRelExpr relExpr term factor primary call args constant relop


%%

program: varDecs stmts {
    root = make_node_str("Program");
    add_child(root, $1);
    add_child(root, $2);
    $$ = root;
} | varDecs {
    root = make_node_str("Program");
    add_child(root, $1);
    $$ = root;
} | stmts {
    root = make_node_str("Program");
    add_child(root, $1);
    $$ = root;
}

varDecs: varDecs SEMICOLON varDec {
    node *varDecsNode = make_node_str("VarDecs");
    add_child(varDecsNode, $1);
    add_child(varDecsNode, $3);
    $$ = varDecsNode;
}
| varDec {
    $$ = $1;
}
| /* epsilon */ {
    $$ = NULL;
}

varDec: type ID {
    // Handle variable declaration and assignment
    node *varDecNode = make_node_str("VarDec");
    add_child(varDecNode, $1);
    add_child(varDecNode, make_node_str($2));
    $$ = varDecNode;

}| 
type ID EQUALS_SIGN expr {
    // Handle variable declaration and assignment
    node *varDecNode = make_node_str("VarDec");
    add_child(varDecNode, $1);
    add_child(varDecNode, make_node_str($2));
    add_child(varDecNode, $4);
    $$ = varDecNode;
}
stmt: exprStmt {
    $$ = $1;
}
| compoundStmt {
    $$ = $1;
}
| selStmt {
    $$ = $1;
}
| iterStmt {
    $$ = $1;
}
| jumpStmt {
    $$ = $1;
}
| varDec SEMICOLON {
    $$ = $1;
}

expr: ID EQUALS_SIGN expr {
    node *exprNode = make_node_str("AssignExpr");
    add_child(exprNode, make_node_str($1));
    add_child(exprNode, $3);

    $$ = exprNode;
}
| orExpr {
    $$ = $1;
}


type: INT_TYPE {
    $$ = make_node_str("int");
}
| FLOAT_TYPE {
    $$ = make_node_str("float");
}
| STRING_TYPE {
    $$ = make_node_str("string");
}
| BOOL_TYPE {
    $$ = make_node_str("bool");
}
| VOID_TYPE {
    $$ = make_node_str("void");
}

stmts: stmts stmt {
    node *stmtsNode = make_node_str("Stmts");
    add_child(stmtsNode, $1);
    add_child(stmtsNode, $2);
    $$ = stmtsNode;
}
| stmt {
    $$ = $1;
}
| /* epsilon */ {
    $$ = NULL;
}

exprStmt: expr SEMICOLON {
    node *exprStmtNode = make_node_str("ExprStmt");
    add_child(exprStmtNode, $1);
    $$ = exprStmtNode;
}
| SEMICOLON {
    $$ = make_node_str("EmptyStmt");
}


compoundStmt: LBRACE varDecs stmts RBRACE {
    node *compoundStmtNode = make_node_str("CompoundStmt");
    add_child(compoundStmtNode, $2);
    add_child(compoundStmtNode, $3);
    $$ = compoundStmtNode;
}

selStmt: IF LPAREN expr RPAREN stmt ELSE stmt {
    node *selStmtNode = make_node_str("SelStmt");
    add_child(selStmtNode, $3);
    add_child(selStmtNode, $5);
    add_child(selStmtNode, $7);
    $$ = selStmtNode;
}
| IF LPAREN expr RPAREN stmt {
    node *selStmtNode = make_node_str("SelStmt");
    add_child(selStmtNode, $3);
    add_child(selStmtNode, $5);
    $$ = selStmtNode;
}

iterStmt: WHILE LPAREN expr RPAREN stmt {
    node *iterStmtNode = make_node_str("IterStmt");
    add_child(iterStmtNode, $3);
    add_child(iterStmtNode, $5);
    $$ = iterStmtNode;
}

jumpStmt: BREAK SEMICOLON {
    $$ = make_node_str("BreakStmt");
}
| RETURN SEMICOLON {
    $$ = make_node_str("ReturnStmt");
}
| RETURN expr SEMICOLON {
    node *returnStmtNode = make_node_str("ReturnStmt");
    add_child(returnStmtNode, $2);
    $$ = returnStmtNode;
}




orExpr: andExpr LOGICAL_OR unaryRelExpr {
    node *orExprNode = make_node_str("LogicalOrExpr");
    add_child(orExprNode, $1);
    add_child(orExprNode, $3);
    $$ = orExprNode;
}
| andExpr {
    $$ = $1;
}

andExpr: unaryRelExpr LOGICAL_AND unaryRelExpr {
    node *andExprNode = make_node_str("LogicalAndExpr");
    add_child(andExprNode, $1);
    add_child(andExprNode, $3);
    $$ = andExprNode;
}
| unaryRelExpr {
    $$ = $1;
}

unaryRelExpr: LOGICAL_NOT unaryRelExpr {
    node *unaryRelExprNode = make_node_str("UnaryRelExpr");
    add_child(unaryRelExprNode, make_node_str("Not"));
    add_child(unaryRelExprNode, $2);
    $$ = unaryRelExprNode;
}
| relExpr {
    $$ = $1;
}

relExpr: term relop term {
    node *relExprNode = make_node_str("RelExpr");
    add_child(relExprNode, $1);
    add_child(relExprNode, $2);
    add_child(relExprNode, $3);
    $$ = relExprNode;
}
| term {
    $$ = $1;
}

relop: GREATER_THAN {
    $$ = make_node_str(">");
}
| LESS_THAN {
    $$ = make_node_str("<");
}
| GREATER_EQUAL {
    $$ = make_node_str(">=");
}
| LESS_EQUAL {
    $$ = make_node_str("<=");
}
| EQUALS {
    $$ = make_node_str("==");
}
| NOT_EQUAL {
    $$ = make_node_str("!=");
}


term: factor {
    $$ = $1;
}
| term PLUS factor {
    node *termNode = make_node_str("Term");
    add_child(termNode, $1);
    add_child(termNode, make_node_str("Plus"));
    add_child(termNode, $3);
    $$ = termNode;
}
| term MINUS factor {
    node *termNode = make_node_str("Term");
    add_child(termNode, $1);
    add_child(termNode, make_node_str("Minus"));
    add_child(termNode, $3);
    $$ = termNode;
}

factor: primary {
    $$ = $1;
}
| factor MULTIPLY primary {
    node *factorNode = make_node_str("Factor");
    add_child(factorNode, $1);
    add_child(factorNode, make_node_str("Multiply"));
    add_child(factorNode, $3);
    $$ = factorNode;
}
| factor DIVIDE primary {
    node *factorNode = make_node_str("Factor");
    add_child(factorNode, $1);
    add_child(factorNode, make_node_str("Divide"));
    add_child(factorNode, $3);
    $$ = factorNode;
}
| factor MODULO primary {
    node *factorNode = make_node_str("Factor");
    add_child(factorNode, $1);
    add_child(factorNode, make_node_str("Modulo"));
    add_child(factorNode, $3);
    $$ = factorNode;
}

primary: ID {
    $$ = make_node_str($1);
}
| LPAREN expr RPAREN {
    $$ = $2;
}
| call {
    $$ = $1;
}
| constant {
    $$ = $1;
}

call: ID LPAREN args RPAREN {
    node *callNode = make_node_str("Call");
    add_child(callNode, make_node_str($1));
    add_child(callNode, $3);
    $$ = callNode;
}
| ID LPAREN RPAREN {
    $$ = make_node_str("Call");
    add_child($$, make_node_str($1));
}

args: args COMMA expr {
    node *argsNode = make_node_str("Args");
    add_child(argsNode, $1);
    add_child(argsNode, $3);
    $$ = argsNode;
}
| expr {
    $$ = make_node_str("Args");
    add_child($$, $1);
}
| /* epsilon */ {
    $$ = NULL;
}

constant: INT_LITERAL {
    $$ = make_node_str("IntConst");
}
| FLOAT_LITERAL {
    $$ = make_node_str("FloatConst");
}
| STRING_LITERAL {
    $$ = make_node_str("StringConst");
}
| BOOL_LITERAL {
    $$ = make_node_str("BoolConst");
}
| STR_CONST {
    $$ = make_node_str("StrConst");
}

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error: %s\n", s);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        printf("Could not open input file\n");
        return 1;
    }

    yyparse();
    
    
    


    FILE *f = fopen("parsetree.dot", "w");
    if (!f) {
        printf("Could not open file to write parse tree\n");
        fclose(yyin);
        return 1;
    }

    save_to_dot(f);
    fclose(f);

    fclose(yyin);

    // Free the parse tree memory
    free_tree(root);

    return 0;
}



node *make_node_str(std::string name) {
  node *n = (node *) malloc(sizeof(node));
  n->key.name = strdup(name.c_str());
  if (!n->key.name) {
      printf("Memory allocation failed\n");
      exit(1);
  }
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
