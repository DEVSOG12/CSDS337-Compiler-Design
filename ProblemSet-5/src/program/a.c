#include <stdio.h>
#include <stdlib.h>

// Matrix multiplication
void matrix_multiplication(int size, int **a, int **b, int **c, int m, int n, int p) {
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < p; j++) {
            c[i][j] = 0;
            for (int k = 0; k < n; k++) {
                c[i][j] += a[i][k] * b[k][j];
            }
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Usage: %s <size>\n", argv[0]);
        return 1;
    }

    int size = atoi(argv[1]);

    int **a = malloc(size * sizeof(int *));
    int **b = malloc(size * sizeof(int *));
    int **c = malloc(size * sizeof(int *));
    for (int i = 0; i < size; i++) {
        a[i] = malloc(size * sizeof(int));
        b[i] = malloc(size * sizeof(int));
        c[i] = malloc(size * sizeof(int));
    }

    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            a[i][j] = i + j;
            b[i][j] = i - j;
        }
    }

    matrix_multiplication(size, a, b, c, size, size, size);

    // Print the result
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            printf("%d ", c[i][j]);
        }
        printf("\n");
    }

    // Free allocated memory
    for (int i = 0; i < size; i++) {
        free(a[i]);
        free(b[i]);
        free(c[i]);
    }
    free(a);
    free(b);
    free(c);

    return 0;
}
