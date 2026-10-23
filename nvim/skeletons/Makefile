BIN = bin_name
SRC = source_files

make: $(SRC)
	gcc -Wall -Wextra -o $(BIN) $(SRC)

clean:
	rm $(BIN)

install:
	install -m 755 $(BIN) /usr/local/bin
