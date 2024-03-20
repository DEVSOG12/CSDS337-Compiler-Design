{
   int[4] a; int i; int j; int temp;
    a[0] = 4;
    a[1] = 0;
    a[2] = 2;
    a[3] = 6;
    for i = 0; i < 4; i = i + 1 {
        for (j = 0; j < 4; j = j + 1) {
            if (a[j] > a[j + 1]) {
                temp = a[j];
                a[j] = a[j + 1];
                a[j + 1] = temp;
            }
        }
    }
}