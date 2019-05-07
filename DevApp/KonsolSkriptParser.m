#import "KonsolSkriptParser.h"
#import <PEGKit/PEGKit.h>


@interface KonsolSkriptParser ()

@property (nonatomic, retain) NSMutableDictionary *program_memo;
@property (nonatomic, retain) NSMutableDictionary *element_memo;
@property (nonatomic, retain) NSMutableDictionary *identifier_memo;
@property (nonatomic, retain) NSMutableDictionary *string_memo;
@property (nonatomic, retain) NSMutableDictionary *number_memo;
@property (nonatomic, retain) NSMutableDictionary *specialSymbol_memo;
@property (nonatomic, retain) NSMutableDictionary *symbol_memo;
@property (nonatomic, retain) NSMutableDictionary *comment_memo;
@property (nonatomic, retain) NSMutableDictionary *openCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *closeCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *openBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *closeBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *openParen_memo;
@property (nonatomic, retain) NSMutableDictionary *closeParen_memo;
@property (nonatomic, retain) NSMutableDictionary *semi_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *dot_memo;
@property (nonatomic, retain) NSMutableDictionary *colon_memo;
@property (nonatomic, retain) NSMutableDictionary *reserved_memo;
@property (nonatomic, retain) NSMutableDictionary *builtin_memo;
@end

@implementation KonsolSkriptParser { }

- (instancetype)initWithDelegate:(id)d {
    self = [super initWithDelegate:d];
    if (self) {
        
        self.startRuleName = @"program";
        self.enableAutomaticErrorRecovery = YES;

        self.tokenKindTab[@"filter"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FILTER);
        self.tokenKindTab[@"sort"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SORT);
        self.tokenKindTab[@"if"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_IF);
        self.tokenKindTab[@"TWO_PI"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TWO_PI);
        self.tokenKindTab[@"cos"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_COS);
        self.tokenKindTab[@"repr"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_REPR);
        self.tokenKindTab[@"await"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_AWAIT);
        self.tokenKindTab[@"const"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CONST);
        self.tokenKindTab[@"CORNERS"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CORNERS);
        self.tokenKindTab[@"throw"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_THROW);
        self.tokenKindTab[@"assert"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ASSERT);
        self.tokenKindTab[@"max"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_MAX);
        self.tokenKindTab[@"loop"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_LOOP);
        self.tokenKindTab[@"atan2"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN2);
        self.tokenKindTab[@"replace"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_REPLACE);
        self.tokenKindTab[@"height"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_HEIGHT);
        self.tokenKindTab[@"acos"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ACOS);
        self.tokenKindTab[@"ellipse"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSE);
        self.tokenKindTab[@"finally"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FINALLY);
        self.tokenKindTab[@"contains"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CONTAINS);
        self.tokenKindTab[@"true"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TRUE);
        self.tokenKindTab[@"Object"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_OBJECT);
        self.tokenKindTab[@"["] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_OPENBRACKET);
        self.tokenKindTab[@"Dictionary"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DICTIONARY);
        self.tokenKindTab[@"HALF_PI"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_HALF_PI);
        self.tokenKindTab[@"in"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_IN);
        self.tokenKindTab[@"]"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEBRACKET);
        self.tokenKindTab[@"case"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CASE);
        self.tokenKindTab[@"type"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TYPE);
        self.tokenKindTab[@"class"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CLASS);
        self.tokenKindTab[@"false"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FALSE);
        self.tokenKindTab[@"sin"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SIN);
        self.tokenKindTab[@"log"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_LOG);
        self.tokenKindTab[@"new"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NEW);
        self.tokenKindTab[@"fill"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FILL);
        self.tokenKindTab[@"count"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_COUNT);
        self.tokenKindTab[@"synchronized"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SYNCHRONIZED);
        self.tokenKindTab[@"else"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ELSE);
        self.tokenKindTab[@"not"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NOT);
        self.tokenKindTab[@"is"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_IS);
        self.tokenKindTab[@"bezier"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_BEZIER);
        self.tokenKindTab[@"strokeCap"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_STROKECAP);
        self.tokenKindTab[@"switch"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SWITCH);
        self.tokenKindTab[@"line"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_LINE);
        self.tokenKindTab[@"floor"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FLOOR);
        self.tokenKindTab[@"ceil"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CEIL);
        self.tokenKindTab[@"width"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_WIDTH);
        self.tokenKindTab[@"rectMode"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RECTMODE);
        self.tokenKindTab[@"asin"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ASIN);
        self.tokenKindTab[@"Array"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ARRAY);
        self.tokenKindTab[@"sub"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SUB);
        self.tokenKindTab[@"continue"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CONTINUE);
        self.tokenKindTab[@"popStyle"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_POPSTYLE);
        self.tokenKindTab[@"import"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_IMPORT);
        self.tokenKindTab[@"lowercase"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_LOWERCASE);
        self.tokenKindTab[@"PI"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_PI);
        self.tokenKindTab[@"copy"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_COPY);
        self.tokenKindTab[@"ellipseMode"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSEMODE);
        self.tokenKindTab[@"rotate"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ROTATE);
        self.tokenKindTab[@"min"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_MIN);
        self.tokenKindTab[@"random"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RANDOM);
        self.tokenKindTab[@"exit"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_EXIT);
        self.tokenKindTab[@"globals"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_GLOBALS);
        self.tokenKindTab[@"chr"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CHR);
        self.tokenKindTab[@"#"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_POUND);
        self.tokenKindTab[@"throws"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_THROWS);
        self.tokenKindTab[@"$"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DOLLAR);
        self.tokenKindTab[@"null"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NULL);
        self.tokenKindTab[@"var"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_VAR);
        self.tokenKindTab[@"locals"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_LOCALS);
        self.tokenKindTab[@"noStroke"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NOSTROKE);
        self.tokenKindTab[@"scale"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SCALE);
        self.tokenKindTab[@"arc"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ARC);
        self.tokenKindTab[@"QUARTER_PI"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_QUARTER_PI);
        self.tokenKindTab[@"let"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_LET);
        self.tokenKindTab[@"translate"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TRANSLATE);
        self.tokenKindTab[@"matches"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_MATCHES);
        self.tokenKindTab[@"isNan"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ISNAN);
        self.tokenKindTab[@"atan"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN);
        self.tokenKindTab[@"("] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_OPENPAREN);
        self.tokenKindTab[@"{"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_OPENCURLY);
        self.tokenKindTab[@")"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEPAREN);
        self.tokenKindTab[@"}"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSECURLY);
        self.tokenKindTab[@"noFill"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NOFILL);
        self.tokenKindTab[@"private"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_PRIVATE);
        self.tokenKindTab[@"NaN"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NAN);
        self.tokenKindTab[@"String"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_STRING);
        self.tokenKindTab[@","] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_COMMA);
        self.tokenKindTab[@"do"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DO);
        self.tokenKindTab[@"size"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SIZE);
        self.tokenKindTab[@"radians"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RADIANS);
        self.tokenKindTab[@"Number"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_NUMBER_TITLE);
        self.tokenKindTab[@"."] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DOT);
        self.tokenKindTab[@"default"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DEFAULT);
        self.tokenKindTab[@"ord"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ORD);
        self.tokenKindTab[@"CORNER"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CORNER);
        self.tokenKindTab[@"abs"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ABS);
        self.tokenKindTab[@"CENTER"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CENTER);
        self.tokenKindTab[@"catch"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_CATCH);
        self.tokenKindTab[@"uppercase"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_UPPERCASE);
        self.tokenKindTab[@"and"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_AND);
        self.tokenKindTab[@"pushStyle"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_PUSHSTYLE);
        self.tokenKindTab[@"print"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT);
        self.tokenKindTab[@"strokeJoin"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEJOIN);
        self.tokenKindTab[@"extends"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_EXTENDS);
        self.tokenKindTab[@"sum"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SUM);
        self.tokenKindTab[@":"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_COLON);
        self.tokenKindTab[@"degrees"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DEGREES);
        self.tokenKindTab[@";"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SEMI);
        self.tokenKindTab[@"compare"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_COMPARE);
        self.tokenKindTab[@"description"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DESCRIPTION);
        self.tokenKindTab[@"tan"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TAN);
        self.tokenKindTab[@"abstract"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ABSTRACT);
        self.tokenKindTab[@"trim"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TRIM);
        self.tokenKindTab[@"map"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_MAP);
        self.tokenKindTab[@"try"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_TRY);
        self.tokenKindTab[@"this"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_THIS);
        self.tokenKindTab[@"public"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_PUBLIC);
        self.tokenKindTab[@"super"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SUPER);
        self.tokenKindTab[@"interface"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_INTERFACE);
        self.tokenKindTab[@"background"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_BACKGROUND);
        self.tokenKindTab[@"strokeWeight"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEWEIGHT);
        self.tokenKindTab[@"for"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FOR);
        self.tokenKindTab[@"position"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_POSITION);
        self.tokenKindTab[@"break"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_BREAK);
        self.tokenKindTab[@"sqrt"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SQRT);
        self.tokenKindTab[@"Boolean"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_BOOLEAN);
        self.tokenKindTab[@"range"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RANGE);
        self.tokenKindTab[@"rect"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RECT);
        self.tokenKindTab[@"frameRate"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_FRAMERATE);
        self.tokenKindTab[@"implements"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_IMPLEMENTS);
        self.tokenKindTab[@"while"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_WHILE);
        self.tokenKindTab[@"del"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_DEL);
        self.tokenKindTab[@"stroke"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_STROKE);
        self.tokenKindTab[@"redraw"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_REDRAW);
        self.tokenKindTab[@"sleep"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_SLEEP);
        self.tokenKindTab[@"return"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RETURN);
        self.tokenKindTab[@"or"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_OR);
        self.tokenKindTab[@"RADIUS"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_RADIUS);
        self.tokenKindTab[@"Infinity"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_INFINITY);
        self.tokenKindTab[@"static"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_STATIC);
        self.tokenKindTab[@"round"] = @(KONSOLSKRIPTPARSER_TOKEN_KIND_ROUND);

        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FILTER] = @"filter";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SORT] = @"sort";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_IF] = @"if";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TWO_PI] = @"TWO_PI";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_COS] = @"cos";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_REPR] = @"repr";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_AWAIT] = @"await";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CONST] = @"const";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CORNERS] = @"CORNERS";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_THROW] = @"throw";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ASSERT] = @"assert";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_MAX] = @"max";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_LOOP] = @"loop";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN2] = @"atan2";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_REPLACE] = @"replace";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_HEIGHT] = @"height";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ACOS] = @"acos";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSE] = @"ellipse";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FINALLY] = @"finally";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CONTAINS] = @"contains";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TRUE] = @"true";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_OBJECT] = @"Object";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_OPENBRACKET] = @"[";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DICTIONARY] = @"Dictionary";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_HALF_PI] = @"HALF_PI";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_IN] = @"in";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEBRACKET] = @"]";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CASE] = @"case";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TYPE] = @"type";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CLASS] = @"class";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FALSE] = @"false";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SIN] = @"sin";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_LOG] = @"log";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NEW] = @"new";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FILL] = @"fill";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_COUNT] = @"count";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SYNCHRONIZED] = @"synchronized";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ELSE] = @"else";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NOT] = @"not";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_IS] = @"is";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_BEZIER] = @"bezier";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_STROKECAP] = @"strokeCap";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SWITCH] = @"switch";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_LINE] = @"line";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FLOOR] = @"floor";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CEIL] = @"ceil";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_WIDTH] = @"width";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RECTMODE] = @"rectMode";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ASIN] = @"asin";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ARRAY] = @"Array";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SUB] = @"sub";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CONTINUE] = @"continue";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_POPSTYLE] = @"popStyle";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_IMPORT] = @"import";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_LOWERCASE] = @"lowercase";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_PI] = @"PI";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_COPY] = @"copy";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSEMODE] = @"ellipseMode";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ROTATE] = @"rotate";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_MIN] = @"min";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RANDOM] = @"random";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_EXIT] = @"exit";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_GLOBALS] = @"globals";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CHR] = @"chr";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_POUND] = @"#";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_THROWS] = @"throws";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DOLLAR] = @"$";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NULL] = @"null";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_VAR] = @"var";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_LOCALS] = @"locals";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NOSTROKE] = @"noStroke";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SCALE] = @"scale";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ARC] = @"arc";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_QUARTER_PI] = @"QUARTER_PI";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_LET] = @"let";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TRANSLATE] = @"translate";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_MATCHES] = @"matches";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ISNAN] = @"isNan";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN] = @"atan";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_OPENPAREN] = @"(";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_OPENCURLY] = @"{";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEPAREN] = @")";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSECURLY] = @"}";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NOFILL] = @"noFill";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_PRIVATE] = @"private";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NAN] = @"NaN";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_STRING] = @"String";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_COMMA] = @",";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DO] = @"do";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SIZE] = @"size";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RADIANS] = @"radians";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_NUMBER_TITLE] = @"Number";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DOT] = @".";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DEFAULT] = @"default";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ORD] = @"ord";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CORNER] = @"CORNER";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ABS] = @"abs";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CENTER] = @"CENTER";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_CATCH] = @"catch";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_UPPERCASE] = @"uppercase";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_AND] = @"and";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_PUSHSTYLE] = @"pushStyle";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT] = @"print";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEJOIN] = @"strokeJoin";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_EXTENDS] = @"extends";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SUM] = @"sum";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_COLON] = @":";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DEGREES] = @"degrees";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SEMI] = @";";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_COMPARE] = @"compare";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DESCRIPTION] = @"description";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TAN] = @"tan";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ABSTRACT] = @"abstract";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TRIM] = @"trim";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_MAP] = @"map";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_TRY] = @"try";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_THIS] = @"this";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_PUBLIC] = @"public";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SUPER] = @"super";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_INTERFACE] = @"interface";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_BACKGROUND] = @"background";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEWEIGHT] = @"strokeWeight";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FOR] = @"for";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_POSITION] = @"position";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_BREAK] = @"break";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SQRT] = @"sqrt";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_BOOLEAN] = @"Boolean";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RANGE] = @"range";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RECT] = @"rect";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_FRAMERATE] = @"frameRate";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_IMPLEMENTS] = @"implements";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_WHILE] = @"while";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_DEL] = @"del";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_STROKE] = @"stroke";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_REDRAW] = @"redraw";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_SLEEP] = @"sleep";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RETURN] = @"return";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_OR] = @"or";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_RADIUS] = @"RADIUS";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_INFINITY] = @"Infinity";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_STATIC] = @"static";
        self.tokenKindNameTab[KONSOLSKRIPTPARSER_TOKEN_KIND_ROUND] = @"round";

        self.program_memo = [NSMutableDictionary dictionary];
        self.element_memo = [NSMutableDictionary dictionary];
        self.identifier_memo = [NSMutableDictionary dictionary];
        self.string_memo = [NSMutableDictionary dictionary];
        self.number_memo = [NSMutableDictionary dictionary];
        self.specialSymbol_memo = [NSMutableDictionary dictionary];
        self.symbol_memo = [NSMutableDictionary dictionary];
        self.comment_memo = [NSMutableDictionary dictionary];
        self.openCurly_memo = [NSMutableDictionary dictionary];
        self.closeCurly_memo = [NSMutableDictionary dictionary];
        self.openBracket_memo = [NSMutableDictionary dictionary];
        self.closeBracket_memo = [NSMutableDictionary dictionary];
        self.openParen_memo = [NSMutableDictionary dictionary];
        self.closeParen_memo = [NSMutableDictionary dictionary];
        self.semi_memo = [NSMutableDictionary dictionary];
        self.comma_memo = [NSMutableDictionary dictionary];
        self.dot_memo = [NSMutableDictionary dictionary];
        self.colon_memo = [NSMutableDictionary dictionary];
        self.reserved_memo = [NSMutableDictionary dictionary];
        self.builtin_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    
    self.program_memo = nil;
    self.element_memo = nil;
    self.identifier_memo = nil;
    self.string_memo = nil;
    self.number_memo = nil;
    self.specialSymbol_memo = nil;
    self.symbol_memo = nil;
    self.comment_memo = nil;
    self.openCurly_memo = nil;
    self.closeCurly_memo = nil;
    self.openBracket_memo = nil;
    self.closeBracket_memo = nil;
    self.openParen_memo = nil;
    self.closeParen_memo = nil;
    self.semi_memo = nil;
    self.comma_memo = nil;
    self.dot_memo = nil;
    self.colon_memo = nil;
    self.reserved_memo = nil;
    self.builtin_memo = nil;

    [super dealloc];
}

- (void)clearMemo {
    [_program_memo removeAllObjects];
    [_element_memo removeAllObjects];
    [_identifier_memo removeAllObjects];
    [_string_memo removeAllObjects];
    [_number_memo removeAllObjects];
    [_specialSymbol_memo removeAllObjects];
    [_symbol_memo removeAllObjects];
    [_comment_memo removeAllObjects];
    [_openCurly_memo removeAllObjects];
    [_closeCurly_memo removeAllObjects];
    [_openBracket_memo removeAllObjects];
    [_closeBracket_memo removeAllObjects];
    [_openParen_memo removeAllObjects];
    [_closeParen_memo removeAllObjects];
    [_semi_memo removeAllObjects];
    [_comma_memo removeAllObjects];
    [_dot_memo removeAllObjects];
    [_colon_memo removeAllObjects];
    [_reserved_memo removeAllObjects];
    [_builtin_memo removeAllObjects];
}

- (void)start {
    [self execute:^{
    
        self.statementTerminator = @";";
        self.singleLineCommentMarker = @"//";
		self.blockStartMarker = @"{";
		self.blockEndMarker = @"}";
        self.braces = @"( ) [ ]";

		PKTokenizer *t = self.tokenizer;
	
        [t.symbolState add:@"!="];
        [t.symbolState add:@"!=="];
        [t.symbolState add:@"=="];
        [t.symbolState add:@"==="];
        [t.symbolState add:@"<="];
        [t.symbolState add:@">="];
        [t.symbolState add:@"++"];
        [t.symbolState add:@"--"];
        [t.symbolState add:@"+="];
        [t.symbolState add:@"-="];
        [t.symbolState add:@"*="];
        [t.symbolState add:@"/="];
        [t.symbolState add:@"%="];
        [t.symbolState add:@"<<"];
        [t.symbolState add:@">>"];
        [t.symbolState add:@">>>"];
        [t.symbolState add:@"<<="];
        [t.symbolState add:@">>="];
        [t.symbolState add:@">>>="];
        [t.symbolState add:@"&="];
        [t.symbolState add:@"^="];
        [t.symbolState add:@"|="];

        // setup comments
        t.commentState.reportsCommentTokens = YES;
        [t setTokenizerState:t.commentState from:'/' to:'/'];
        [t.commentState addSingleLineStartMarker:@"//"];
        [t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];
        
        // comment state should fallback to symbol state to match divison op
        t.commentState.fallbackState = t.symbolState;
        
        // identifiers
        [t setTokenizerState:t.wordState from:'_' to:'_'];
        [t.wordState setWordChars:YES from:'_' to:'_'];
        [t.wordState setWordChars:NO from:'-' to:'-'];
        [t.wordState setWordChars:NO from:'.' to:'.'];
        
        [t setTokenizerState:t.numberState from:'#' to:'#'];
        [t setTokenizerState:t.numberState from:'$' to:'$'];
        [t.numberState addPrefix:@"#" forRadix:16];
        [t.numberState addPrefix:@"$" forRadix:2];
        [t.numberState addGroupingSeparator:'_' forRadix:16];
        [t.numberState addGroupingSeparator:'_' forRadix:10];
        [t.numberState addGroupingSeparator:'_' forRadix:2];
        t.numberState.allowsTrailingDecimalSeparator = YES;

    }];

    [self tryAndRecover:TOKEN_KIND_BUILTIN_EOF block:^{
        [self program_]; 
        [self matchEOF:YES]; 
    } completion:^{
        [self matchEOF:YES];
    }];

}

- (void)__program {
    
    do {
        [self element_]; 
    } while ([self predicts:TOKEN_KIND_BUILTIN_ANY, 0]);

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"program"];
}

- (void)program_ {
    [self parseRule:@selector(__program) withMemo:_program_memo];
}

- (void)__element {
    
    if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_ABSTRACT, KONSOLSKRIPTPARSER_TOKEN_KIND_AND, KONSOLSKRIPTPARSER_TOKEN_KIND_AWAIT, KONSOLSKRIPTPARSER_TOKEN_KIND_BREAK, KONSOLSKRIPTPARSER_TOKEN_KIND_CASE, KONSOLSKRIPTPARSER_TOKEN_KIND_CATCH, KONSOLSKRIPTPARSER_TOKEN_KIND_CLASS, KONSOLSKRIPTPARSER_TOKEN_KIND_CONST, KONSOLSKRIPTPARSER_TOKEN_KIND_CONTINUE, KONSOLSKRIPTPARSER_TOKEN_KIND_DEFAULT, KONSOLSKRIPTPARSER_TOKEN_KIND_DEL, KONSOLSKRIPTPARSER_TOKEN_KIND_DO, KONSOLSKRIPTPARSER_TOKEN_KIND_ELSE, KONSOLSKRIPTPARSER_TOKEN_KIND_EXTENDS, KONSOLSKRIPTPARSER_TOKEN_KIND_FINALLY, KONSOLSKRIPTPARSER_TOKEN_KIND_FOR, KONSOLSKRIPTPARSER_TOKEN_KIND_IF, KONSOLSKRIPTPARSER_TOKEN_KIND_IMPLEMENTS, KONSOLSKRIPTPARSER_TOKEN_KIND_IMPORT, KONSOLSKRIPTPARSER_TOKEN_KIND_IN, KONSOLSKRIPTPARSER_TOKEN_KIND_INTERFACE, KONSOLSKRIPTPARSER_TOKEN_KIND_IS, KONSOLSKRIPTPARSER_TOKEN_KIND_LET, KONSOLSKRIPTPARSER_TOKEN_KIND_NEW, KONSOLSKRIPTPARSER_TOKEN_KIND_NOT, KONSOLSKRIPTPARSER_TOKEN_KIND_OR, KONSOLSKRIPTPARSER_TOKEN_KIND_PRIVATE, KONSOLSKRIPTPARSER_TOKEN_KIND_PUBLIC, KONSOLSKRIPTPARSER_TOKEN_KIND_RETURN, KONSOLSKRIPTPARSER_TOKEN_KIND_STATIC, KONSOLSKRIPTPARSER_TOKEN_KIND_SUB, KONSOLSKRIPTPARSER_TOKEN_KIND_SUPER, KONSOLSKRIPTPARSER_TOKEN_KIND_SWITCH, KONSOLSKRIPTPARSER_TOKEN_KIND_SYNCHRONIZED, KONSOLSKRIPTPARSER_TOKEN_KIND_THIS, KONSOLSKRIPTPARSER_TOKEN_KIND_THROW, KONSOLSKRIPTPARSER_TOKEN_KIND_THROWS, KONSOLSKRIPTPARSER_TOKEN_KIND_TRY, KONSOLSKRIPTPARSER_TOKEN_KIND_VAR, KONSOLSKRIPTPARSER_TOKEN_KIND_WHILE, 0]) {
        [self reserved_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_ABS, KONSOLSKRIPTPARSER_TOKEN_KIND_ACOS, KONSOLSKRIPTPARSER_TOKEN_KIND_ARC, KONSOLSKRIPTPARSER_TOKEN_KIND_ARRAY, KONSOLSKRIPTPARSER_TOKEN_KIND_ASIN, KONSOLSKRIPTPARSER_TOKEN_KIND_ASSERT, KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN, KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN2, KONSOLSKRIPTPARSER_TOKEN_KIND_BACKGROUND, KONSOLSKRIPTPARSER_TOKEN_KIND_BEZIER, KONSOLSKRIPTPARSER_TOKEN_KIND_BOOLEAN, KONSOLSKRIPTPARSER_TOKEN_KIND_CEIL, KONSOLSKRIPTPARSER_TOKEN_KIND_CENTER, KONSOLSKRIPTPARSER_TOKEN_KIND_CHR, KONSOLSKRIPTPARSER_TOKEN_KIND_COMPARE, KONSOLSKRIPTPARSER_TOKEN_KIND_CONTAINS, KONSOLSKRIPTPARSER_TOKEN_KIND_COPY, KONSOLSKRIPTPARSER_TOKEN_KIND_CORNER, KONSOLSKRIPTPARSER_TOKEN_KIND_CORNERS, KONSOLSKRIPTPARSER_TOKEN_KIND_COS, KONSOLSKRIPTPARSER_TOKEN_KIND_COUNT, KONSOLSKRIPTPARSER_TOKEN_KIND_DEGREES, KONSOLSKRIPTPARSER_TOKEN_KIND_DESCRIPTION, KONSOLSKRIPTPARSER_TOKEN_KIND_DICTIONARY, KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSE, KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSEMODE, KONSOLSKRIPTPARSER_TOKEN_KIND_EXIT, KONSOLSKRIPTPARSER_TOKEN_KIND_FALSE, KONSOLSKRIPTPARSER_TOKEN_KIND_FILL, KONSOLSKRIPTPARSER_TOKEN_KIND_FILTER, KONSOLSKRIPTPARSER_TOKEN_KIND_FLOOR, KONSOLSKRIPTPARSER_TOKEN_KIND_FRAMERATE, KONSOLSKRIPTPARSER_TOKEN_KIND_GLOBALS, KONSOLSKRIPTPARSER_TOKEN_KIND_HALF_PI, KONSOLSKRIPTPARSER_TOKEN_KIND_HEIGHT, KONSOLSKRIPTPARSER_TOKEN_KIND_INFINITY, KONSOLSKRIPTPARSER_TOKEN_KIND_ISNAN, KONSOLSKRIPTPARSER_TOKEN_KIND_LINE, KONSOLSKRIPTPARSER_TOKEN_KIND_LOCALS, KONSOLSKRIPTPARSER_TOKEN_KIND_LOG, KONSOLSKRIPTPARSER_TOKEN_KIND_LOOP, KONSOLSKRIPTPARSER_TOKEN_KIND_LOWERCASE, KONSOLSKRIPTPARSER_TOKEN_KIND_MAP, KONSOLSKRIPTPARSER_TOKEN_KIND_MATCHES, KONSOLSKRIPTPARSER_TOKEN_KIND_MAX, KONSOLSKRIPTPARSER_TOKEN_KIND_MIN, KONSOLSKRIPTPARSER_TOKEN_KIND_NAN, KONSOLSKRIPTPARSER_TOKEN_KIND_NOFILL, KONSOLSKRIPTPARSER_TOKEN_KIND_NOSTROKE, KONSOLSKRIPTPARSER_TOKEN_KIND_NULL, KONSOLSKRIPTPARSER_TOKEN_KIND_NUMBER_TITLE, KONSOLSKRIPTPARSER_TOKEN_KIND_OBJECT, KONSOLSKRIPTPARSER_TOKEN_KIND_ORD, KONSOLSKRIPTPARSER_TOKEN_KIND_PI, KONSOLSKRIPTPARSER_TOKEN_KIND_POPSTYLE, KONSOLSKRIPTPARSER_TOKEN_KIND_POSITION, KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT, KONSOLSKRIPTPARSER_TOKEN_KIND_PUSHSTYLE, KONSOLSKRIPTPARSER_TOKEN_KIND_QUARTER_PI, KONSOLSKRIPTPARSER_TOKEN_KIND_RADIANS, KONSOLSKRIPTPARSER_TOKEN_KIND_RADIUS, KONSOLSKRIPTPARSER_TOKEN_KIND_RANDOM, KONSOLSKRIPTPARSER_TOKEN_KIND_RANGE, KONSOLSKRIPTPARSER_TOKEN_KIND_RECT, KONSOLSKRIPTPARSER_TOKEN_KIND_RECTMODE, KONSOLSKRIPTPARSER_TOKEN_KIND_REDRAW, KONSOLSKRIPTPARSER_TOKEN_KIND_REPLACE, KONSOLSKRIPTPARSER_TOKEN_KIND_REPR, KONSOLSKRIPTPARSER_TOKEN_KIND_ROTATE, KONSOLSKRIPTPARSER_TOKEN_KIND_ROUND, KONSOLSKRIPTPARSER_TOKEN_KIND_SCALE, KONSOLSKRIPTPARSER_TOKEN_KIND_SIN, KONSOLSKRIPTPARSER_TOKEN_KIND_SIZE, KONSOLSKRIPTPARSER_TOKEN_KIND_SLEEP, KONSOLSKRIPTPARSER_TOKEN_KIND_SORT, KONSOLSKRIPTPARSER_TOKEN_KIND_SQRT, KONSOLSKRIPTPARSER_TOKEN_KIND_STRING, KONSOLSKRIPTPARSER_TOKEN_KIND_STROKE, KONSOLSKRIPTPARSER_TOKEN_KIND_STROKECAP, KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEJOIN, KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEWEIGHT, KONSOLSKRIPTPARSER_TOKEN_KIND_SUM, KONSOLSKRIPTPARSER_TOKEN_KIND_TAN, KONSOLSKRIPTPARSER_TOKEN_KIND_TRANSLATE, KONSOLSKRIPTPARSER_TOKEN_KIND_TRIM, KONSOLSKRIPTPARSER_TOKEN_KIND_TRUE, KONSOLSKRIPTPARSER_TOKEN_KIND_TWO_PI, KONSOLSKRIPTPARSER_TOKEN_KIND_TYPE, KONSOLSKRIPTPARSER_TOKEN_KIND_UPPERCASE, KONSOLSKRIPTPARSER_TOKEN_KIND_WIDTH, 0]) {
        [self builtin_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self identifier_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self string_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_DOLLAR, KONSOLSKRIPTPARSER_TOKEN_KIND_POUND, TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self number_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEBRACKET, KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSECURLY, KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEPAREN, KONSOLSKRIPTPARSER_TOKEN_KIND_COLON, KONSOLSKRIPTPARSER_TOKEN_KIND_COMMA, KONSOLSKRIPTPARSER_TOKEN_KIND_DOT, KONSOLSKRIPTPARSER_TOKEN_KIND_OPENBRACKET, KONSOLSKRIPTPARSER_TOKEN_KIND_OPENCURLY, KONSOLSKRIPTPARSER_TOKEN_KIND_OPENPAREN, KONSOLSKRIPTPARSER_TOKEN_KIND_SEMI, 0]) {
        [self specialSymbol_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_SYMBOL, 0]) {
        [self symbol_]; 
    } else {
        [self raise:@"No viable alternative found in rule 'element'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"element"];
}

- (void)element_ {
    [self parseRule:@selector(__element) withMemo:_element_memo];
}

- (void)__identifier {
    
    [self matchWord:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"identifier"];
}

- (void)identifier_ {
    [self parseRule:@selector(__identifier) withMemo:_identifier_memo];
}

- (void)__string {
    
    [self matchQuotedString:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"string"];
}

- (void)string_ {
    [self parseRule:@selector(__string) withMemo:_string_memo];
}

- (void)__number {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self matchNumber:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_DOLLAR, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DOLLAR discard:NO]; 
        [self matchNumber:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_POUND, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_POUND discard:NO]; 
        [self matchNumber:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'number'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"number"];
}

- (void)number_ {
    [self parseRule:@selector(__number) withMemo:_number_memo];
}

- (void)__specialSymbol {
    
    if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_OPENCURLY, 0]) {
        [self openCurly_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSECURLY, 0]) {
        [self closeCurly_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_OPENPAREN, 0]) {
        [self openParen_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEPAREN, 0]) {
        [self closeParen_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_OPENBRACKET, 0]) {
        [self openBracket_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEBRACKET, 0]) {
        [self closeBracket_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_SEMI, 0]) {
        [self semi_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_COMMA, 0]) {
        [self comma_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_DOT, 0]) {
        [self dot_]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_COLON, 0]) {
        [self colon_]; 
    } else {
        [self raise:@"No viable alternative found in rule 'specialSymbol'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"specialSymbol"];
}

- (void)specialSymbol_ {
    [self parseRule:@selector(__specialSymbol) withMemo:_specialSymbol_memo];
}

- (void)__symbol {
    
    [self matchSymbol:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"symbol"];
}

- (void)symbol_ {
    [self parseRule:@selector(__symbol) withMemo:_symbol_memo];
}

- (void)__comment {
    
    [self matchComment:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"comment"];
}

- (void)comment_ {
    [self parseRule:@selector(__comment) withMemo:_comment_memo];
}

- (void)__openCurly {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_OPENCURLY discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openCurly"];
}

- (void)openCurly_ {
    [self parseRule:@selector(__openCurly) withMemo:_openCurly_memo];
}

- (void)__closeCurly {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSECURLY discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeCurly"];
}

- (void)closeCurly_ {
    [self parseRule:@selector(__closeCurly) withMemo:_closeCurly_memo];
}

- (void)__openBracket {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_OPENBRACKET discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openBracket"];
}

- (void)openBracket_ {
    [self parseRule:@selector(__openBracket) withMemo:_openBracket_memo];
}

- (void)__closeBracket {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEBRACKET discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeBracket"];
}

- (void)closeBracket_ {
    [self parseRule:@selector(__closeBracket) withMemo:_closeBracket_memo];
}

- (void)__openParen {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_OPENPAREN discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openParen"];
}

- (void)openParen_ {
    [self parseRule:@selector(__openParen) withMemo:_openParen_memo];
}

- (void)__closeParen {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CLOSEPAREN discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeParen"];
}

- (void)closeParen_ {
    [self parseRule:@selector(__closeParen) withMemo:_closeParen_memo];
}

- (void)__semi {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SEMI discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"semi"];
}

- (void)semi_ {
    [self parseRule:@selector(__semi) withMemo:_semi_memo];
}

- (void)__comma {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COMMA discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"comma"];
}

- (void)comma_ {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__dot {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DOT discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"dot"];
}

- (void)dot_ {
    [self parseRule:@selector(__dot) withMemo:_dot_memo];
}

- (void)__colon {
    
    [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COLON discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"colon"];
}

- (void)colon_ {
    [self parseRule:@selector(__colon) withMemo:_colon_memo];
}

- (void)__reserved {
    
    if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_SYNCHRONIZED, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SYNCHRONIZED discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_AWAIT, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_AWAIT discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_IMPORT, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_IMPORT discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_SWITCH, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SWITCH discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CASE, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CASE discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_DEFAULT, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DEFAULT discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_FOR, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FOR discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_IN, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_IN discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_IS, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_IS discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_WHILE, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_WHILE discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_DO, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DO discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_IF, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_IF discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_ELSE, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ELSE discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_BREAK, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BREAK discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CONTINUE, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CONTINUE discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_RETURN, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RETURN discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_AND, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_AND discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_OR, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_OR discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_NOT, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NOT discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_SUB, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SUB discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_VAR, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_VAR discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_LET, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LET discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CONST, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CONST discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_DEL, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DEL discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_NEW, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NEW discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CLASS, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CLASS discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_EXTENDS, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_EXTENDS discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_IMPLEMENTS, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_IMPLEMENTS discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_STATIC, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STATIC discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_INTERFACE, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_INTERFACE discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_PUBLIC, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PUBLIC discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_PRIVATE, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PRIVATE discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_ABSTRACT, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ABSTRACT discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_THIS, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_THIS discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_SUPER, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SUPER discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_THROWS, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_THROWS discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_THROW, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_THROW discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_TRY, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRY discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_CATCH, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CATCH discard:NO]; 
    } else if ([self predicts:KONSOLSKRIPTPARSER_TOKEN_KIND_FINALLY, 0]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FINALLY discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'reserved'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"reserved"];
}

- (void)reserved_ {
    [self parseRule:@selector(__reserved) withMemo:_reserved_memo];
}

- (void)__builtin {
    
    if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRUE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRUE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FALSE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FALSE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NULL discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NULL discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NAN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NAN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_INFINITY discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_INFINITY discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_OBJECT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_OBJECT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BOOLEAN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BOOLEAN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NUMBER_TITLE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NUMBER_TITLE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STRING discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STRING discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ARRAY discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ARRAY discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DICTIONARY discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DICTIONARY discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TYPE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TYPE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_REPR discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_REPR discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PRINT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ASSERT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ASSERT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COPY discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COPY discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DESCRIPTION discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DESCRIPTION discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SLEEP discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SLEEP discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_EXIT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_EXIT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOCALS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOCALS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_GLOBALS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_GLOBALS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COUNT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COUNT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_POSITION discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_POSITION discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RANGE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RANGE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SUM discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SUM discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SORT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SORT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MAP discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MAP discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FILTER discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FILTER discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ORD discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ORD discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CHR discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CHR discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRIM discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRIM discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOWERCASE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOWERCASE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_UPPERCASE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_UPPERCASE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MATCHES discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MATCHES discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_REPLACE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_REPLACE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COMPARE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COMPARE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ISNAN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ISNAN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RANDOM discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RANDOM discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ABS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ABS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ROUND discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ROUND discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FLOOR discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FLOOR discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CEIL discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CEIL discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MAX discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MAX discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MIN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_MIN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SQRT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SQRT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOG discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOG discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ACOS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ACOS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ASIN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ASIN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN2 discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ATAN2 discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_COS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DEGREES discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_DEGREES discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RADIANS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RADIANS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SIN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SIN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TAN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TAN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PI discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PI discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_HALF_PI discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_HALF_PI discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_QUARTER_PI discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_QUARTER_PI discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TWO_PI discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TWO_PI discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CORNER discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CORNER discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CORNERS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CORNERS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CENTER discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CENTER discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RADIUS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RADIUS discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_WIDTH discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_WIDTH discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_HEIGHT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_HEIGHT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FRAMERATE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FRAMERATE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_REDRAW discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_REDRAW discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOOP discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LOOP discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RECTMODE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RECTMODE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSEMODE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSEMODE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NOSTROKE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NOSTROKE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NOFILL discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_NOFILL discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SIZE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SIZE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PUSHSTYLE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_PUSHSTYLE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_POPSTYLE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_POPSTYLE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRANSLATE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_TRANSLATE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SCALE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_SCALE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ROTATE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ROTATE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BACKGROUND discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BACKGROUND discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEWEIGHT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEWEIGHT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKECAP discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKECAP discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEJOIN discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_STROKEJOIN discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FILL discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_FILL discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RECT discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_RECT discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ELLIPSE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ARC discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_ARC discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LINE discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_LINE discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BEZIER discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_BEZIER discard:NO]; 
    } else if ([self speculate:^{ [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CONTAINS discard:NO]; }]) {
        [self match:KONSOLSKRIPTPARSER_TOKEN_KIND_CONTAINS discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'builtin'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"builtin"];
}

- (void)builtin_ {
    [self parseRule:@selector(__builtin) withMemo:_builtin_memo];
}

@end
