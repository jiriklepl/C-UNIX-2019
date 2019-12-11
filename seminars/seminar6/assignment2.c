#include <poll.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#define BUF_SIZE 256

int main(void) {
    int rval;
    char* buf;
    buf = malloc(BUF_SIZE);

    int server_socket = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in server_address;
    server_address.sin_family = AF_INET;
    server_address.sin_addr.s_addr = INADDR_ANY;
    server_address.sin_port = htons(2222);

    int bind_status = bind(
        server_socket,
        (struct sockaddr *) &server_address,
        sizeof(server_address));
    int listen_status = listen(server_socket, 8);

    struct pollfd pfd = { fd: server_socket, events: POLLIN, 0 };

    if ((rval = poll(&pfd, 1, 5000)) > -1) {
        if (rval > 0) {
            write(1, "SUCCESS\n", 8);

            struct sockaddr_in client_address;
            socklen_t client_address_size = sizeof(client_address);
            int client_socket = accept(
                server_socket,
                (struct sockaddr *) &client_address,
                &client_address_size);

            int shutdown_status = shutdown(client_socket, SHUT_RDWR);
            int close_status = close(client_socket);
        } else {
            write(1, "timeout encountered\n", 20);
        }
    } else {
        write(1, "error\n", 6);
    }

    shutdown(server_socket, SHUT_RDWR);
    int close_status = close(server_socket);

    free(buf);
}
