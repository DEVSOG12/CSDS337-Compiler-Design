%code requires {
 #include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <string>
#include <cstring>
#include <variant>
#include <iostream>
  //all of these includes are done as relative paths starting from the build/ directory, since that's where CMake places parser.tab.cc
#include "../src/ast.h"
#include "../src/expressions/call.h"
#include "../src/expressions/int.h"
#include "../src/expressions/float.h"
#include "../src/expressions/string.h"
#include "../src/expressions/variable.h"
#include "../src/expressions/addition.h"
#include "../src/expressions/subtraction.h"
#include "../src/expressions/multiplication.h"
#include "../src/expressions/division.h"
#include "../src/expressions/assignment.h"
#include "../src/expressions/comparison.h"
#include "../src/expressions/and.h"
#include "../src/expressions/or.h"
#include "../src/statements/block.h"
#include "../src/statements/while.h"
#include "../src/statements/if.h"
#include "../src/statements/return.h"
#include "../src/types/simple.h"
extern FILE *yyin;

}

%{
#include "parser.tab.hh"



  /* This is the main code which preceeds the parser definition.
     Most of this is function and variable declarations needed for generating the parse tree.
     You will need to call these functions inside your parser code actions to generate the parse tree. */



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

  AST ast("TestMod");

%}

%start program

//Print detailed syntax errors when possible
%define parse.error verbose


%union {
  bool boolval;
  int intval;
  double fltval;
  char *strval;
  struct node *nval;
  ASTFunctionParameter *var;
  std::vector<ASTFunctionParameter *> *vars;
  ASTStatement *stmt;
  std::vector<ASTStatement *> *stmtVec;
  ASTExpression *exp;
  std::vector<ASTExpression *> *exprVec;
  VarType *type;
  ASTExpressionComparisonType rel;
}

%token ID BOOL_TYPE INT_TYPE FLOAT_TYPE STRING_TYPE VOID_TYPE SEMICOLON LPAREN RPAREN COMMA LBRACE RBRACE IF ELSE WHILE BREAK RETURN EQUALS_SIGN LOGICAL_OR LOGICAL_AND LOGICAL_NOT RELOP_GT RELOP_LT RELOP_GE RELOP_LE RELOP_EQ RELOP_NE ARITH_PLUS ARITH_MINUS ARITH_MULT ARITH_DIV ARITH_MOD VARIADIC BOOL_LITERAL INT_LITERAL FLOAT_LITERAL STRING_LITERAL EOL

%type <boolval> BOOL_LITERAL
%type <strval> ID STRING_LITERAL
%type <intval> int_lit INT_LITERAL
%type <fltval> flt_lit FLOAT_LITERAL
%type <var> varDec
%type <vars> params paramList varDecs
%type <stmt> stmt exprStmt selStmt iterStmt jumpStmt
%type <stmtVec> stmts
%type <exp> expr orExpr andExpr unaryRelExpr relExpr term factor primary call constant
%type <exprVec> args
%type <type> type
%type <rel> relop

%expect 1 // Shift/reduce conflict when resolving the if/else production; okay


%%

program: | decList ;
decList: decList dec | dec ;
dec: funDef | funDec ;

type: BOOL_TYPE {
    $$ = new VarTypeSimple(VarTypeSimple::BoolType);
} | INT_TYPE {
    $$ = new VarTypeSimple(VarTypeSimple::IntType);
} | FLOAT_TYPE {
    $$ = new VarTypeSimple(VarTypeSimple::FloatType);
} | STRING_TYPE {
    $$ = new VarTypeSimple(VarTypeSimple::StringType);
} | VOID_TYPE {
    $$ = new VarTypeSimple(VarTypeSimple::VoidType);
};

varDec: type ID {
  //ASTFunctionParameter is just a tuple of a unique pointer to a type and a string (see definition in function.h)
  $$ = new ASTFunctionParameter(std::unique_ptr<VarType>($1), $2);
 };
varDecs: varDecs varDec SEMICOLON {
  $$ = $1; //We know that varDecs is always a pointer to vector of variables, so we can just copy it and push the next variable
  $$->push_back($2);
 } | {
  $$ = new std::vector<ASTFunctionParameter *>();
 };

funDec: type ID LPAREN params RPAREN SEMICOLON {
  //create the parameters
  auto parameters = ASTFunctionParameters();
  bool variadic = false;
  for(auto p : *$4) {
    /* The AST uses unique pointers for memory purposes, but bison doesn't work well with those, so the parser uses plain C-style pointers.
     * To account for this, make sure to dereference the pointers before using. */
    if (p) parameters.push_back(std::move(*p));
    else variadic = true;
  }
  //then make the function
  auto f = ast.AddFunction($2, std::unique_ptr<VarType>($1), std::move(parameters), variadic);
};

funDef: type ID LPAREN params RPAREN LBRACE varDecs stmts RBRACE {
    auto stmtBlock = new ASTStatementBlock();
    for(auto s : *$8) {
      stmtBlock->statements.push_back(std::unique_ptr<ASTStatement>(s));
    }
    //create the parameters
    auto parameters = ASTFunctionParameters();
    bool variadic = false;
    for(auto p : *$4) {
      if (p) parameters.push_back(std::move(*p));
      else variadic = true;
    }
    //then make the function
    auto function = ast.AddFunction($2, std::unique_ptr<VarType>($1), std::move(parameters), variadic);
    function->Define(std::unique_ptr<ASTStatementBlock>(stmtBlock));
    // ast.AddFunctionBody(function);
    
};


params: paramList | {$$ = new std::vector<ASTFunctionParameter *>();};
paramList: paramList COMMA type ID { // This works similarly to varDecs
  $$ = $1;
  $$->push_back(new ASTFunctionParameter(std::unique_ptr<VarType>($3), $4));
 } | type ID {
   $$ = new std::vector<ASTFunctionParameter *>();
   $$->push_back(new ASTFunctionParameter(std::unique_ptr<VarType>($1), $2));
 } | paramList COMMA VARIADIC {
  $$ = new std::vector<ASTFunctionParameter *>();
  $$->push_back(nullptr); // Using a null pointer to indicate a variadic function (see funDec)
 };

stmt: exprStmt {$$ = $1;} | LBRACE stmts RBRACE {
  //"stmts" is a vector of plain pointers to statements. We convert it to a statement block as follows:
  auto statements = new ASTStatementBlock();
  for(auto s : *$2) {
    statements->statements.push_back(std::unique_ptr<ASTStatement>(s));
  }
  $$ = statements;
 }| selStmt {$$ = $1;} | iterStmt {$$ = $1;} | jumpStmt {$$ = $1;} ; // Strictly speaking, these {$$ = $1}sare unnecessary (bison does it for you).
exprStmt: expr SEMICOLON {
  $$ = $1; //implicit cast expr -> stmt
 } | SEMICOLON {
  $$ = new ASTStatementBlock(); //empty statement = empty block
 };
stmts: stmts stmt {
  //Here, we just place the statements into a vector. They'll be added to the AST in a parent's code action.
  $$ = $1;
  $$->push_back($2);
 }| {
  $$ = new std::vector<ASTStatement *>();
 };
selStmt: IF LPAREN expr RPAREN stmt {
    $$ = new ASTStatementIf(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTStatement>($5), std::unique_ptr<ASTStatement>(nullptr));
} | IF LPAREN expr RPAREN stmt ELSE stmt {
    $$ = new ASTStatementIf(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTStatement>($5), std::unique_ptr<ASTStatement>($7));
};


iterStmt: WHILE LPAREN expr RPAREN stmt {
    $$ = new ASTStatementWhile(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTStatement>($5));
}

/* fill in grammar and code action for for-loops */

jumpStmt: RETURN SEMICOLON {
    auto retStmt = new ASTStatementReturn();
    retStmt->returnExpression = std::unique_ptr<ASTExpression>(nullptr);
    $$ = retStmt;
} | RETURN expr SEMICOLON {
    auto retStmt = new ASTStatementReturn();
    retStmt->returnExpression = std::unique_ptr<ASTExpression>($2);
    $$ = retStmt;
};


expr: orExpr { $$ = $1;} | ID EQUALS_SIGN expr {
    $$ = new ASTExpressionAssignment(std::make_unique<ASTExpressionVariable>($1), std::unique_ptr<ASTExpression>($3));
};
orExpr: andExpr {$$ = $1;} | orExpr LOGICAL_OR andExpr {
  $$ = new ASTExpressionOr(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
 };
andExpr: unaryRelExpr {$$ = $1;} | andExpr LOGICAL_AND unaryRelExpr {
    $$ = new ASTExpressionAnd(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
};
unaryRelExpr: LOGICAL_NOT unaryRelExpr {
  //logical not isn't implmented in ast, so we just don't do anything
  $$ = $2;
 } | relExpr {$$ = $1;};
relExpr: term relop term {
  $$ = new ASTExpressionComparison($2, std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
 } | term {$$ = $1;};
relop: RELOP_GT {
  $$ = ASTExpressionComparisonType::GreaterThan;
 }| RELOP_LT {
  $$ = ASTExpressionComparisonType::LessThan;
 }| RELOP_GE {
  $$ = ASTExpressionComparisonType::GreaterThanOrEqual;
 }| RELOP_LE {
  $$ = ASTExpressionComparisonType::LessThanOrEqual;
 }| RELOP_EQ {
  $$ = ASTExpressionComparisonType::Equal;
 }| RELOP_NE {
  $$ = ASTExpressionComparisonType::NotEqual;
 };
term: factor {$$ = $1;}| term ARITH_PLUS factor {
  $$ = new ASTExpressionAddition(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
 }| term ARITH_MINUS factor {
  $$ = new ASTExpressionSubtraction(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
 };
factor: primary {$$ = $1;} | factor ARITH_MULT primary {
  $$ = new ASTExpressionMultiplication(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
 }| factor ARITH_DIV primary {
  $$ = new ASTExpressionDivision(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
 }| factor ARITH_MOD primary {
  //not implemented in AST
  $$ = $1;
 };
primary: ID {
  $$ = new ASTExpressionVariable($1);
 }| LPAREN expr RPAREN {
  $$ = $2;
 } | call {
  $$ = $1;
 }| constant {
  $$ = $1;
 };
call: ID LPAREN args RPAREN {
  //convert args to a vector of unique ptrs:
  auto argVec = std::vector<std::unique_ptr<ASTExpression>>();
  for(auto a : *$3) {
    argVec.push_back(std::unique_ptr<ASTExpression>(a));
  }
  $$ = new ASTExpressionCall(ASTExpressionVariable::Create($1), std::move(argVec));
 } | ID LPAREN RPAREN {
  //if there are no args, then just give it an empty vector
  $$ = new ASTExpressionCall(ASTExpressionVariable::Create($1), std::vector<std::unique_ptr<ASTExpression>>());
   };
 args: args COMMA expr {
   $$ = $1;
   $$->push_back($3);
 } | expr {
   $$ = new std::vector<ASTExpression *>();
   $$->push_back($1);
 } ;
constant: int_lit {$$ = new ASTExpressionInt($1);} | flt_lit {$$ = new ASTExpressionFloat($1);} | STRING_LITERAL {$$ = new ASTExpressionString(std::string($1));};
int_lit: INT_LITERAL | ARITH_MINUS INT_LITERAL {$$ = -1 * $2;};
flt_lit: FLOAT_LITERAL | ARITH_MINUS FLOAT_LITERAL {$$ = -1 * $2;};

%%

int main(int argc, char **argv) {

  // Arg flags:
  bool showHelp = false; // Show the help and exit.
  std::string openFile = ""; // File to open. Nothing for standard in.
  std::string outFile = ""; // File to write to. Nothing for standard out.
  int outputFormat = 3; // 0 - LLVM Assembly. 1 - LLVM Bitcode. 2 - Object (TODO). 3 - AST tree.
  bool printAST = true; // If to print the AST to console.

  // Read the arguments. Don't count the first which is the executable name.
  for (int i = 1; i < argc; i++)
  {
    bool hasNextArg = i + 1 < argc;
    std::string arg(argv[i]);
    if (arg == "-i" && hasNextArg)
    {
      i++;
      openFile = argv[i];
    }
    else if (arg == "-o" && hasNextArg)
    {
      i++;
      outFile = argv[i];
    }
    else if (arg == "-nPrint")
    {
      printAST = false;
    }
    else if (arg == "-fAsm")
    {
      outputFormat = 0;
    }
    else if (arg == "-fBc")
    {
      outputFormat = 1;
    }
    else if (arg == "-fObj")
    {
      outputFormat = 2;
    }
    else if (arg == "-fAst")
    {
      outputFormat = 3;
    }
    else
    {
      showHelp = true;
    }
  }
  printAST &= outputFormat != 3 && outFile != ""; // Always print AST by default in addition to whatever is being output.

  // Show help if needed.
  if (showHelp)
  {
    printf("Usage: LLVM-Lab [options]\n");
    printf("\nOptions:\n\n");
    printf("-h              Show this help screen.\n");
    printf("-i [input]      Read from an input file (reads from console by default).\n");
    printf("-o [output]     Write to an output file (writes to console by default).\n");
    printf("-nPrint         If to not print the AST to the console.\n");
    printf("-fAsm           Output format is in LLVM assembly.\n");
    printf("-fAst           Output format is an abstract syntax tree.\n");
    printf("-fBc            Output format is in LLVM bitcode.\n");
    printf("-fObj           Output format is an object file.\n");
    return 1;
  }

  // Fetch input.
  if (openFile != "")
  {
    yyin = fopen(openFile.c_str(), "r");
  }

  if (yyparse() == 1)
  {
    printf("Irrecoverable error state, aborting\n");
    return 1;
  }

  // Close input if needed.
  if (openFile != "")
  {
    fclose(yyin);
  }

  // Do the compilation.
  ast.Compile();

  // Print AST if needed.
  if (printAST) std::cout << ast.ToString() << std::endl;

  // Export data.
  if (outputFormat == 0)
  {
    ast.WriteLLVMAssemblyToFile(outFile);
  }
  else if (outputFormat == 1)
  {
    ast.WriteLLVMBitcodeToFile(outFile);
  }
  else if (outputFormat == 2)
  {
    std::cout << "OBJ exporting not supported yet." << std::endl;
  }
  else
  {
    std::cout << ast.ToString() << std::endl;
  }
  return 0;
}

void yyerror(const char *s)
{
  fprintf(stderr, "error: %s\n", s);
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
