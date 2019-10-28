#include <stdio.h>
#include <stdlib.h>

typedef struct entry_t {
	const char* e_arg;
	struct entry_t* e_next;
} entry_t;

entry_t* add(entry_t* head, const char* value) {
	entry_t* new_node;
	if (new_node = malloc(sizeof(entry_t))) {
		new_node->e_arg = value;
		new_node->e_next = head;

		return new_node;
	} else {
		return head;
	}
}

int main(int argc, const char* argv[]) {
	entry_t *head = NULL;

	while (*++argv) {
		head = add(head, *argv);
	}

	for (entry_t* next; head; head = next) {
		printf("%s ", head->e_arg);

		next = head->e_next;
		free(head);
	}

	printf("\n");
	return 0;
}
