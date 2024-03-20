%{
#include <stdio.h>
int char_count = 0;
int word_count = 0;
int line_count = 0;
int single_line_comment_count = 0;
int multi_line_comment_count = 0;
int for_count = 0;
int do_count = 0;
int while_count = 0;

// Disable yywrap requirement
#define YY_NO_INPUT
%}

%x COMMENT

%%


"/*"            { multi_line_comment_count++; BEGIN(COMMENT); }
"//"            { single_line_comment_count++; }
<COMMENT>"*/"   { multi_line_comment_count++; BEGIN(INITIAL); }
<COMMENT>.|\n   { /* Ignoring characters inside multi-line comments */ }
[ \t]+          { /* Replace multiple spaces with a single space */ }
\n              { line_count++; }

for             { for_count++; }
do              { do_count++; }
while           { while_count++; }

[a-zA-Z]+       { word_count++;  char_count += yyleng;  }



%%

int yywrap() {
    return 1;
}

int main(int argc, char* argv[]) {
    FILE *input_file;
    int i;

    if (argc < 2) {
        printf("Usage: %s file1 file2 ... fileN\n", argv[0]);
        return 1;
    }

    FILE *output_file = fopen("problem4output", "w");
    if (output_file == NULL) {
        perror("Error opening output file");
        return 1;
    }

    for (i = 1; i < argc; ++i) {
        input_file = fopen(argv[i], "r");
        if (input_file == NULL) {
            perror("Error opening input file");
            return 1;
        }

        char_count = word_count = line_count = 0;
        single_line_comment_count = multi_line_comment_count = 0;
        for_count = do_count = while_count = 0;

        yyin = input_file;
        yylex();

        line_count++; // Count the last line

        fprintf(output_file, "File: %s\n", argv[i]);
        fprintf(output_file, "Number of characters: %d\n", char_count);
        fprintf(output_file, "Number of words: %d\n", word_count);
        fprintf(output_file, "Number of lines: %d\n", line_count);
        fprintf(output_file, "Number of single line C comments: %d\n", single_line_comment_count);
        fprintf(output_file, "Number of multiple line C comments: %d\n", multi_line_comment_count);
        fprintf(output_file, "Number of 'for' occurrences: %d\n", for_count);
        fprintf(output_file, "Number of 'do' occurrences: %d\n", do_count);
        fprintf(output_file, "Number of 'while' occurrences: %d\n", while_count);
        fprintf(output_file, "\n");

        fclose(input_file);
    }

    fclose(output_file);
    return 0;
}
