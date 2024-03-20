build: compile run 

compile:
	javac lexer/*.java
	javac symbols/*.java
	javac inter/*.java
	javac parser/*.java
	javac main/*.java

	
run:
	@for i in `(cd input; ls *.t | sed -e 's/.t$$//')`;\
		do echo $$i.t;\
		java main.Main <input/$$i.t >output/$$i.i;\
	done

test:
	@for i in `(cd tests1; ls *.t | sed -e 's/.t$$//')`;\
		do echo $$i.t;\
		diff tests1/$$i.i output/$$i.i;\
	done

clean:
	(cd lexer; rm *.class)
	(cd symbols; rm *.class)
	(cd inter; rm *.class)
	(cd parser; rm *.class)
	(cd main; rm *.class)

yacc:
	/usr/ccs/bin/yacc -v doc/front.y
	rm y.tab.c
	mv y.output doc
