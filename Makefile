CC = clang

CFLAGS = -I/opt/homebrew/opt/lua/include/lua -fPIC -Wall -Wextra -std=c17
LDFLAGS = -L/opt/homebrew/opt/lua/lib
LDLIBS = -llua

TARGET = inio_core.so
SRC = inio.c

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -shared -o $(TARGET) $(SRC) $(LDFLAGS) $(LDLIBS)

clean:
	rm -f $(TARGET)
