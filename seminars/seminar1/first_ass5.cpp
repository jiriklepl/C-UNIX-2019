#include <stdio.h>
#include <stdlib.h>
#include <iostream>

typedef struct entry_t {
	const char* e_arg;
	struct entry_t* e_next;
} entry_t;

entry_t* add(entry_t* head, const char* value) {
	entry_t* new_node;
	return (new_node = (entry_t*)malloc(sizeof(entry_t))) != nullptr
		? &(*new_node = entry_t{value, head})
		: head;
}

int main(int argc, const char* argv[]) {
	entry_t *head = nullptr;

	while (*++argv) {
		head = add(head, *argv);
	}

	for (entry_t* next; head; head = next) {
		std::cout << head->e_arg << ' ';
		next = head->e_next;
		free(head);
	}

	std::cout << std::endl;
	return 0;
}
