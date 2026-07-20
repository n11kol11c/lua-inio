#include "str.h"
#include <ctype.h>
#include <string.h>

int startswith(const char *str, char ch)
{
    return str[0] == ch;
}

int endswith(const char *str, char ch)
{
    int size = strlen(str);
    return size > 0 && str[size - 1] == ch;
}

char *trim(char *str)
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

int contains(const char *str, const char *target)
{
    return strstr(str, target) != NULL;
}
