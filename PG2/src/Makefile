parser: lexer.l parser.y
	bison -d parser.y -o parser.tab.cc
	clang++ -o parser.o -c parser.tab.cc
	flex -o lex.yy.cc lexer.l
	clang++ -o lexer.o -c lex.yy.cc
	clang++ -o $@ lexer.o parser.o -ll -ly

test: parser
	./parser < test.c



clean:
	rm parser lex.yy.cc parser.tab.cc parser.tab.hh lexer.o parser.o
