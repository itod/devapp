#import <PEGKit/PKParser.h>

enum {
    KONSOLSKRIPTPARSER_TOKEN_KIND_FILTER = 14,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SORT = 15,
    KONSOLSKRIPTPARSER_TOKEN_KIND_IF = 16,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TWO_PI = 17,
    KONSOLSKRIPTPARSER_TOKEN_KIND_COS = 18,
    KONSOLSKRIPTPARSER_TOKEN_KIND_REPR = 19,
    KONSOLSKRIPTPARSER_TOKEN_KIND_AWAIT = 20,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CONST = 21,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CORNERS = 22,
    KONSOLSKRIPTPARSER_TOKEN_KIND_THROW = 23,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ASSERT = 24,
    KONSOLSKRIPTPARSER_TOKEN_KIND_MAX = 25,
    KONSOLSKRIPTPARSER_TOKEN_KIND_LOOP = 26,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN2 = 27,
    KONSOLSKRIPTPARSER_TOKEN_KIND_REPLACE = 28,
    KONSOLSKRIPTPARSER_TOKEN_KIND_HEIGHT = 29,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ACOS = 30,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSE = 31,
    KONSOLSKRIPTPARSER_TOKEN_KIND_FINALLY = 32,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CONTAINS = 33,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TRUE = 34,
    KONSOLSKRIPTPARSER_TOKEN_KIND_OBJECT = 35,
    KONSOLSKRIPTPARSER_TOKEN_KIND_OPENBRACKET = 36,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DICTIONARY = 37,
    KONSOLSKRIPTPARSER_TOKEN_KIND_HALF_PI = 38,
    KONSOLSKRIPTPARSER_TOKEN_KIND_IN = 39,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEBRACKET = 40,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CASE = 41,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TYPE = 42,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CLASS = 43,
    KONSOLSKRIPTPARSER_TOKEN_KIND_FALSE = 44,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SIN = 45,
    KONSOLSKRIPTPARSER_TOKEN_KIND_LOG = 46,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NEW = 47,
    KONSOLSKRIPTPARSER_TOKEN_KIND_FILL = 48,
    KONSOLSKRIPTPARSER_TOKEN_KIND_COUNT = 49,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SYNCHRONIZED = 50,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ELSE = 51,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NOT = 52,
    KONSOLSKRIPTPARSER_TOKEN_KIND_IS = 53,
    KONSOLSKRIPTPARSER_TOKEN_KIND_BEZIER = 54,
    KONSOLSKRIPTPARSER_TOKEN_KIND_STROKECAP = 55,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SWITCH = 56,
    KONSOLSKRIPTPARSER_TOKEN_KIND_LINE = 57,
    KONSOLSKRIPTPARSER_TOKEN_KIND_FLOOR = 58,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CEIL = 59,
    KONSOLSKRIPTPARSER_TOKEN_KIND_WIDTH = 60,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RECTMODE = 61,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ASIN = 62,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ARRAY = 63,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SUB = 64,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CONTINUE = 65,
    KONSOLSKRIPTPARSER_TOKEN_KIND_POPSTYLE = 66,
    KONSOLSKRIPTPARSER_TOKEN_KIND_IMPORT = 67,
    KONSOLSKRIPTPARSER_TOKEN_KIND_LOWERCASE = 68,
    KONSOLSKRIPTPARSER_TOKEN_KIND_PI = 69,
    KONSOLSKRIPTPARSER_TOKEN_KIND_COPY = 70,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSEMODE = 71,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ROTATE = 72,
    KONSOLSKRIPTPARSER_TOKEN_KIND_MIN = 73,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RANDOM = 74,
    KONSOLSKRIPTPARSER_TOKEN_KIND_EXIT = 75,
    KONSOLSKRIPTPARSER_TOKEN_KIND_GLOBALS = 76,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CHR = 77,
    KONSOLSKRIPTPARSER_TOKEN_KIND_POUND = 78,
    KONSOLSKRIPTPARSER_TOKEN_KIND_THROWS = 79,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DOLLAR = 80,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NULL = 81,
    KONSOLSKRIPTPARSER_TOKEN_KIND_VAR = 82,
    KONSOLSKRIPTPARSER_TOKEN_KIND_LOCALS = 83,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NOSTROKE = 84,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SCALE = 85,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ARC = 86,
    KONSOLSKRIPTPARSER_TOKEN_KIND_QUARTER_PI = 87,
    KONSOLSKRIPTPARSER_TOKEN_KIND_LET = 88,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TRANSLATE = 89,
    KONSOLSKRIPTPARSER_TOKEN_KIND_MATCHES = 90,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ISNAN = 91,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN = 92,
    KONSOLSKRIPTPARSER_TOKEN_KIND_OPENPAREN = 93,
    KONSOLSKRIPTPARSER_TOKEN_KIND_OPENCURLY = 94,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEPAREN = 95,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSECURLY = 96,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NOFILL = 97,
    KONSOLSKRIPTPARSER_TOKEN_KIND_PRIVATE = 98,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NAN = 99,
    KONSOLSKRIPTPARSER_TOKEN_KIND_STRING = 100,
    KONSOLSKRIPTPARSER_TOKEN_KIND_COMMA = 101,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DO = 102,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SIZE = 103,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RADIANS = 104,
    KONSOLSKRIPTPARSER_TOKEN_KIND_NUMBER_TITLE = 105,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DOT = 106,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DEFAULT = 107,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ORD = 108,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CORNER = 109,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ABS = 110,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CENTER = 111,
    KONSOLSKRIPTPARSER_TOKEN_KIND_CATCH = 112,
    KONSOLSKRIPTPARSER_TOKEN_KIND_UPPERCASE = 113,
    KONSOLSKRIPTPARSER_TOKEN_KIND_AND = 114,
    KONSOLSKRIPTPARSER_TOKEN_KIND_PUSHSTYLE = 115,
    KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT = 116,
    KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEJOIN = 117,
    KONSOLSKRIPTPARSER_TOKEN_KIND_EXTENDS = 118,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SUM = 119,
    KONSOLSKRIPTPARSER_TOKEN_KIND_COLON = 120,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DEGREES = 121,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SEMI = 122,
    KONSOLSKRIPTPARSER_TOKEN_KIND_COMPARE = 123,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DESCRIPTION = 124,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TAN = 125,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ABSTRACT = 126,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TRIM = 127,
    KONSOLSKRIPTPARSER_TOKEN_KIND_MAP = 128,
    KONSOLSKRIPTPARSER_TOKEN_KIND_TRY = 129,
    KONSOLSKRIPTPARSER_TOKEN_KIND_THIS = 130,
    KONSOLSKRIPTPARSER_TOKEN_KIND_PUBLIC = 131,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SUPER = 132,
    KONSOLSKRIPTPARSER_TOKEN_KIND_INTERFACE = 133,
    KONSOLSKRIPTPARSER_TOKEN_KIND_BACKGROUND = 134,
    KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEWEIGHT = 135,
    KONSOLSKRIPTPARSER_TOKEN_KIND_FOR = 136,
    KONSOLSKRIPTPARSER_TOKEN_KIND_POSITION = 137,
    KONSOLSKRIPTPARSER_TOKEN_KIND_BREAK = 138,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SQRT = 139,
    KONSOLSKRIPTPARSER_TOKEN_KIND_BOOLEAN = 140,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RANGE = 141,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RECT = 142,
    KONSOLSKRIPTPARSER_TOKEN_KIND_FRAMERATE = 143,
    KONSOLSKRIPTPARSER_TOKEN_KIND_IMPLEMENTS = 144,
    KONSOLSKRIPTPARSER_TOKEN_KIND_WHILE = 145,
    KONSOLSKRIPTPARSER_TOKEN_KIND_DEL = 146,
    KONSOLSKRIPTPARSER_TOKEN_KIND_STROKE = 147,
    KONSOLSKRIPTPARSER_TOKEN_KIND_REDRAW = 148,
    KONSOLSKRIPTPARSER_TOKEN_KIND_SLEEP = 149,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RETURN = 150,
    KONSOLSKRIPTPARSER_TOKEN_KIND_OR = 151,
    KONSOLSKRIPTPARSER_TOKEN_KIND_RADIUS = 152,
    KONSOLSKRIPTPARSER_TOKEN_KIND_INFINITY = 153,
    KONSOLSKRIPTPARSER_TOKEN_KIND_STATIC = 154,
    KONSOLSKRIPTPARSER_TOKEN_KIND_ROUND = 155,
};

@interface KonsolSkriptParser : PKParser

@end

