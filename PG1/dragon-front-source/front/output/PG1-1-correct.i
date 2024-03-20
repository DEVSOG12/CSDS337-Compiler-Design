L1:	t1 = 0 * 4
	a [ t1 ] = 4
L3:	t2 = 1 * 4
	a [ t2 ] = 0
L4:	t3 = 2 * 4
	a [ t3 ] = 2
L5:	t4 = 3 * 4
	a [ t4 ] = 6
L6:	i = 0
L7:	iffalse i < 4 goto L2
L8:	j = 0
L10:	iffalse j < 4 goto L9
L11:	t5 = j * 4
	t6 = a [ t5 ]
	t7 = j + 1
	t8 = t7 * 4
	t9 = a [ t8 ]
	iffalse t6 > t9 goto L12
L13:	t10 = j * 4
	temp = a [ t10 ]
L14:	t11 = j * 4
	t12 = j + 1
	t13 = t12 * 4
	t14 = a [ t13 ]
	a [ t11 ] = t14
L15:	t15 = j + 1
	t16 = t15 * 4
	a [ t16 ] = temp
L12:	j = j + 1
	goto L10
L9:	i = i + 1
	goto L7
L2:
