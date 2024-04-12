%code requires {
  #include <stdio.h>
  #include <stdlib.h>
  #include <vector>
  #include <string>
  #include <cstring>
  #include <variant>
  #include <iostream>
  #include "ast.h"
  #include "expressions/call.h"
  #include "expressions/int.h"
  #include "expressions/float.h"
  #include "expressions/string.h"
  #include "expressions/variable.h"
  #include "expressions/addition.h"
  #include "expressions/subtraction.h"
  #include "expressions/multiplication.h"
  #include "expressions/division.h"
  #include "expressions/assignment.h"
  #include "expressions/comparison.h"
  #include "expressions/and.h"
  #include "expressions/or.h"
  #include "statements/block.h"
  #include "statements/for.h"
  #include "statements/while.h"
  #include "statements/if.h"
  #include "statements/return.h"
  #include "types/simple.h"
  extern FILE *yyin;
}

%{
#include "parser.tab.hh"

extern int yylex(void);
void yyerror(const char *s);
void save_to_dot(FILE *);
int trav_and_write(FILE *, node *);

AST ast("TestMod");

// Set-up printf ti be parserd

%}

%start program

%define parse.error verbose

%union {
  bool boolval;
  int intval;
  double fltval;
  char *strval;
  struct node *nodeval;
  ASTFunctionParameter *var;
  std::vector<ASTFunctionParameter *> *vars;
  ASTStatement *stmt;
  std::vector<ASTStatement *> *stmtVec;
  ASTExpression *exp;
  std::vector<ASTExpression *> *exprVec;
  VarType *type;
  ASTExpressionComparisonType rel;
  std::vector<ASTFunctionParameter*> *varDecsPtr;
}



%token ID BOOL_TYPE INT_TYPE FLOAT_TYPE STRING_TYPE VOID_TYPE SEMICOLON LPAREN RPAREN COMMA LBRACE RBRACE IF ELSE WHILE BREAK RETURN EQUALS_SIGN LOGICAL_OR LOGICAL_AND LOGICAL_NOT RELOP_GT RELOP_LT RELOP_GE RELOP_LE RELOP_EQ RELOP_NE ARITH_PLUS ARITH_MINUS ARITH_MULT ARITH_DIV ARITH_MOD VARIADIC BOOL_LITERAL INT_LITERAL FLOAT_LITERAL STRING_LITERAL EOL FOR ARITH_INC

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

type: BOOL_TYPE { $$ = new VarTypeSimple(VarTypeSimple::BoolType); }
    | INT_TYPE { $$ = new VarTypeSimple(VarTypeSimple::IntType); }
    | FLOAT_TYPE { $$ = new VarTypeSimple(VarTypeSimple::FloatType); }
    | STRING_TYPE { $$ = new VarTypeSimple(VarTypeSimple::StringType); }
    | VOID_TYPE { $$ = new VarTypeSimple(VarTypeSimple::VoidType); };

varDec: type ID {
  //ASTFunctionParameter is just a tuple of a unique pointer to a type and a string (see definition in function.h)
  $$ = new ASTFunctionParameter(std::unique_ptr<VarType>($1), $2); 

  // add to the function table if it's a function parameter
  ast.scopeTable.AddVariable($2, std::unique_ptr<VarType>($1));
 
} ;


varDecs: varDecs varDec SEMICOLON {
    $$ = $1;
    $$->push_back($2);
} | {
    $$ = new std::vector<ASTFunctionParameter *>();
};

funDec: type ID LPAREN params RPAREN SEMICOLON {
  auto parameters = ASTFunctionParameters();
  bool variadic = false;
  for(auto p : *$4) {
    if (p) parameters.push_back(std::move(*p));
    else variadic = true;
  }
  auto f = ast.AddFunction($2, std::unique_ptr<VarType>($1), std::move(parameters), variadic);
};

funDef: type ID LPAREN params RPAREN LBRACE varDecs stmts RBRACE {
  // Create an ASTStatementBlock for the function body
  auto stmtBlock = std::make_unique<ASTStatementBlock>();



  // Convert the vector of statements into an ASTStatementBlock
  for (auto s : *$8) {
    stmtBlock->statements.push_back(std::unique_ptr<ASTStatement>(s));
  }

  // Create the function
  auto parameters = ASTFunctionParameters();
  bool variadic = false;
  for(auto p : *$4) {
    if (p) parameters.push_back(std::move(*p));
    else variadic = true;
  }

  auto f = ast.AddFunction($2, std::unique_ptr<VarType>($1), std::move(parameters), variadic);

  // Add local variables to the function
  for (auto var : *$7) {
      f->AddStackVar(std::move(*var));
      // print stack variables
      std::cout << "Stack Var: " << var << std::endl;
    }

  // Define the function
  f->Define(std::move(stmtBlock));
  
};




params: paramList | {$$ = new std::vector<ASTFunctionParameter *>();};
paramList: paramList COMMA type ID {
  $$ = $1;
  $$->push_back(new ASTFunctionParameter(std::unique_ptr<VarType>($3), $4));
} | type ID {
  $$ = new std::vector<ASTFunctionParameter *>();
  $$->push_back(new ASTFunctionParameter(std::unique_ptr<VarType>($1), $2));
} | paramList COMMA VARIADIC {
  // set variadic to true
  $$ = $1;
  $$->push_back(nullptr);

};

stmt: exprStmt {$$ = $1;} | LBRACE stmts RBRACE {
  auto statements = new ASTStatementBlock();
  for(auto s : *$2) {
    statements->statements.push_back(std::unique_ptr<ASTStatement>(s));
  }
  $$ = statements;
 }| selStmt {$$ = $1;} | iterStmt {$$ = $1;} | jumpStmt {$$ = $1;} ;


/* hand */
exprStmt: expr SEMICOLON {
  $$ = $1;
} | SEMICOLON {
  $$ = new ASTStatementBlock();
};

stmts: stmts stmt {
  $$ = $1;
  $$->push_back($2);
} | {
  $$ = new std::vector<ASTStatement *>();
};

selStmt: IF LPAREN expr RPAREN stmt {
  $$ = new ASTStatementIf(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTStatement>($5), std::unique_ptr<ASTStatement>(nullptr));
} | IF LPAREN expr RPAREN stmt ELSE stmt {

  $$ = new ASTStatementIf(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTStatement>($5), std::unique_ptr<ASTStatement>($7));
} ;

iterStmt: WHILE LPAREN expr RPAREN stmt {
  $$ = new ASTStatementWhile(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTStatement>($5));

}  | FOR LPAREN expr SEMICOLON expr SEMICOLON expr RPAREN stmt {
  $$ = new ASTStatementFor(std::unique_ptr<ASTExpression>($3), std::unique_ptr<ASTExpression>($5), std::unique_ptr<ASTExpression>($7), std::unique_ptr<ASTStatement>($9));

};

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
  $$ = new ASTExpressionAssignment(std::unique_ptr<ASTExpression>(new ASTExpressionVariable($1)), std::unique_ptr<ASTExpression>($3));
};

orExpr: andExpr {$$ = $1;} | orExpr LOGICAL_OR andExpr {
  $$ = new ASTExpressionOr(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
};

andExpr: unaryRelExpr {$$ = $1;} | andExpr LOGICAL_AND unaryRelExpr {
  $$ = new ASTExpressionAnd(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
};

unaryRelExpr: LOGICAL_NOT unaryRelExpr {
  $$ = $2;
} | relExpr {$$ = $1;};

relExpr: term relop term {
  $$ = new ASTExpressionComparison($2, std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3));
} | term {$$ = $1;};

relop: RELOP_GT { $$ = ASTExpressionComparisonType::GreaterThan; }
    | RELOP_LT { $$ = ASTExpressionComparisonType::LessThan; }
    | RELOP_GE { $$ = ASTExpressionComparisonType::GreaterThanOrEqual; }
    | RELOP_LE { $$ = ASTExpressionComparisonType::LessThanOrEqual; }
    | RELOP_EQ { $$ = ASTExpressionComparisonType::Equal; }
    | RELOP_NE { $$ = ASTExpressionComparisonType::NotEqual; };

term: factor {$$ = $1;}
    | term ARITH_PLUS factor { $$ = new ASTExpressionAddition(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3)); }
    | term ARITH_MINUS factor { $$ = new ASTExpressionSubtraction(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3)); };
    | term ARITH_INC { $$ = new ASTExpressionAddition(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>(new ASTExpressionInt(1))); };

factor: primary {$$ = $1;}
      | factor ARITH_MULT primary { $$ = new ASTExpressionMultiplication(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3)); }
      | factor ARITH_DIV primary { $$ = new ASTExpressionDivision(std::unique_ptr<ASTExpression>($1), std::unique_ptr<ASTExpression>($3)); }
      | factor ARITH_MOD primary { $$ = $1; };

primary: ID { $$ = new ASTExpressionVariable($1); }
        | LPAREN expr RPAREN { $$ = $2; }
        | call { $$ = $1; }
        | constant { $$ = $1; };

call: ID LPAREN args RPAREN {
  auto argVec = std::vector<std::unique_ptr<ASTExpression>>();
  for(auto a : *$3) {
    argVec.push_back(std::unique_ptr<ASTExpression>(a));
  }
  $$ = new ASTExpressionCall(ASTExpressionVariable::Create($1), std::move(argVec));
} | ID LPAREN RPAREN {
  $$ = new ASTExpressionCall(ASTExpressionVariable::Create($1), std::vector<std::unique_ptr<ASTExpression>>());
};

args: args COMMA expr {
  $$ = $1;
  $$->push_back($3);
} | expr {
  $$ = new std::vector<ASTExpression *>();
  $$->push_back($1);
};

constant: int_lit {$$ = new ASTExpressionInt($1);}
        | flt_lit {$$ = new ASTExpressionFloat($1);}
        | STRING_LITERAL {$$ = new ASTExpressionString(std::string($1));};

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

