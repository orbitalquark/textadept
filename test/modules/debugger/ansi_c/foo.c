#include <stdio.h>

void foo(int i) {
	printf("foo %d\n", i);
}

int main() {
	printf("start\n");
	for (int i = 0; i < 4; i++)
		foo(i);
	printf("end\n");
	return 0;
}
