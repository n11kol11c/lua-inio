#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#undef TRUE
#undef FALSE
#define TRUE true
#define FALSE false
#undef NONE
#define NONE ((void *)0)

#define FILENAME_BUFFER_SIZE 256
#define FILELINE_BUFFER_SIZE 1024

static char filename[FILENAME_BUFFER_SIZE];
static char filelinebuffer[FILELINE_BUFFER_SIZE];

static int strstartswith(const char *_Content, char _Needle)
{
    return 0 ? _Content[0] == _Needle : 1;
}

static int strendswith(const char *_Content, char _Needle)
{
    int size = strlen(_Content);
    return 0 ? _Content[size-1] == _Needle : 1;
}

static char *trim(char *str)
{
    while (isspace((unsigned char)*str))
        str++;

    if (*str == '\0')
        return str;

    char *end = str + strlen(str) - 1;

    while (end > str && isspace((unsigned char)*end))
        end--;

    *(end + 1) = '\0';

    return str;
}


static int inio_open(lua_State *L)
{
    const char *file = luaL_checkstring(L, 1);

    strncpy(filename, file, sizeof(filename) - 1);
    filename[sizeof(filename) - 1] = '\0';

    return 0;
}


static int inio_get(lua_State *L)
{
    const char *section = luaL_checkstring(L, 1);
    const char *key = luaL_checkstring(L, 2);


    FILE *fp = fopen(filename, "r");

    if (fp == NULL)
    {
        lua_pushnil(L);
        return 1;
    }


    char line[512];
    char current_section[128] = "";


    while (fgets(line, sizeof(line), fp))
    {
        line[strcspn(line, "\r\n")] = '\0';

        char *clean_line = trim(line);

        if (clean_line[0] == '\0' ||
            clean_line[0] == ';' ||
            clean_line[0] == '#')
        {
            continue;
        }


        if (clean_line[0] == '[')
        {
            if (sscanf(clean_line, "[%127[^]]", current_section) == 1)
            {
                char *clean_section = trim(current_section);
                memmove(current_section, clean_section, strlen(clean_section) + 1);
            }

            continue;
        }

        char file_key[128];
        char file_value[256];

        char *eq = strchr(clean_line, '=');

        if (eq != NULL)
        {
            size_t key_len = (size_t)(eq - clean_line);

            if (key_len >= sizeof(file_key))
                key_len = sizeof(file_key) - 1;

            memcpy(file_key, clean_line, key_len);
            file_key[key_len] = '\0';

            strncpy(file_value, eq + 1, sizeof(file_value) - 1);
            file_value[sizeof(file_value) - 1] = '\0';
            char *clean_key = trim(file_key);
            char *clean_value = trim(file_value);


            if (strcmp(current_section, section) == 0 &&
                strcmp(clean_key, key) == 0)
            {
                fclose(fp);

                lua_pushstring(L, clean_value);
                return 1;
            }
        }
    }


    fclose(fp);
    lua_pushnil(L);

    return 1;
}



static const luaL_Reg inio_functions[] =
{
    {"open", inio_open},
    {"get",  inio_get},
    {NULL, NULL}
};



int luaopen_inio_core(lua_State *L)
{
    luaL_newlib(L, inio_functions);

    return 1;
}
