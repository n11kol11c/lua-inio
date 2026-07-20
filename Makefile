CC ?= cc

# --- Lua detection -----------------------------------------------------------
# Priority:
#   1) User overrides via LUA_PREFIX / LUA_CFLAGS / LUA_LIB
#   2) pkg-config
#   3) LuaRocks path detection
#   4) Platform-specific fallbacks (Homebrew, system)

ifdef LUA_PREFIX
    LUA_CFLAGS  ?= -I$(LUA_PREFIX)/include/lua
    LUA_LDFLAGS ?= -L$(LUA_PREFIX)/lib
    LUA_LIB     ?= -llua
else
    # Try pkg-config first (if available)
    _HAS_PKGCONFIG := $(shell command -v pkg-config 2>/dev/null)

    ifdef _HAS_PKGCONFIG
        LUA_CFLAGS  := $(shell pkg-config --cflags lua5.4 2>/dev/null || \
                            pkg-config --cflags lua5.3 2>/dev/null || \
                            pkg-config --cflags lua   2>/dev/null)
        LUA_LDFLAGS := $(shell pkg-config --libs-only-L lua5.4 2>/dev/null || \
                            pkg-config --libs-only-L lua5.3 2>/dev/null || \
                            pkg-config --libs-only-L lua   2>/dev/null)
        LUA_LIB     := $(shell pkg-config --libs lua5.4 2>/dev/null || \
                            pkg-config --libs lua5.3 2>/dev/null || \
                            pkg-config --libs lua   2>/dev/null)
    endif

    # If pkg-config didn't work, try LuaRocks
    ifeq ($(LUA_CFLAGS),)
        _LUAROCKS_LUA_INCDIR := $(shell luarocks include 2>/dev/null)
        _LUAROCKS_LUA_LIBDIR := $(shell luarocks libdir 2>/dev/null)
        ifneq ($(_LUAROCKS_LUA_INCDIR),)
            LUA_CFLAGS  := -I$(_LUAROCKS_LUA_INCDIR)
            LUA_LDFLAGS := -L$(_LUAROCKS_LUA_LIBDIR)
            LUA_LIB     := -llua
        endif
    endif

    # Final fallback: detect platform and try common paths
    ifeq ($(LUA_CFLAGS),)
        UNAME_S := $(shell uname -s)
        ifeq ($(UNAME_S),Darwin)
            # macOS Homebrew
            LUA_CFLAGS  := -I/opt/homebrew/opt/lua/include/lua
            LUA_LDFLAGS := -L/opt/homebrew/opt/lua/lib
            LUA_LIB     := -llua
        else
            # Linux: try common versioned names
            LUA_CFLAGS  := -I/usr/include/lua5.4
            LUA_LDFLAGS :=
            LUA_LIB     := -llua5.4
        endif
    endif
endif

CFLAGS  += -fPIC -Wall -Wextra -std=c17 $(LUA_CFLAGS)
LDFLAGS += $(LUA_LDFLAGS)
LDLIBS  += $(LUA_LIB)

# --- Build -------------------------------------------------------------------

TARGET  = inio_core.so
SRC     = inio.c modules/str.c

.PHONY: all clean install

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS) $(LDLIBS)

clean:
	rm -f $(TARGET)

install: $(TARGET)
	install -d "$(DESTDIR)/usr/local/lib/lua"
	install -m 755 $(TARGET) "$(DESTDIR)/usr/local/lib/lua/"
	install -d "$(DESTDIR)/usr/local/share/lua"
	install -m 644 inio.lua "$(DESTDIR)/usr/local/share/lua/"
