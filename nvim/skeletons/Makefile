BIN = bin_name
SRC = main.c

make: $(SRC)
	gcc -Wall -Wextra -o $(BIN) $(SRC)

clean:
	rm $(BIN)

install:
	install -m 755 $(BIN) /usr/local/bin
