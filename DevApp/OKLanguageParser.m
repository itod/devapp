#import "OKLanguageParser.h"
#import <PEGKit/PEGKit.h>


@interface OKLanguageParser ()

@property (nonatomic, retain) NSMutableDictionary *program_memo;
@property (nonatomic, retain) NSMutableDictionary *element_memo;
@property (nonatomic, retain) NSMutableDictionary *identifier_memo;
@property (nonatomic, retain) NSMutableDictionary *string_memo;
@property (nonatomic, retain) NSMutableDictionary *number_memo;
@property (nonatomic, retain) NSMutableDictionary *specialSymbol_memo;
@property (nonatomic, retain) NSMutableDictionary *symbol_memo;
@property (nonatomic, retain) NSMutableDictionary *comment_memo;
@property (nonatomic, retain) NSMutableDictionary *regex_memo;
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

@implementation OKLanguageParser { }

- (instancetype)initWithDelegate:(id)d {
    self = [super initWithDelegate:d];
    if (self) {
        
        self.startRuleName = @"program";
        self.enableAutomaticErrorRecovery = YES;

        self.tokenKindTab[@"("] = @(OKJAVASCRIPT_TOKEN_KIND_OPENPAREN);
        self.tokenKindTab[@"}"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY);
        self.tokenKindTab[@"catch"] = @(OKJAVASCRIPT_TOKEN_KIND_CATCH);
        self.tokenKindTab[@"return"] = @(OKJAVASCRIPT_TOKEN_KIND_RETURN);
        self.tokenKindTab[@")"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN);
        self.tokenKindTab[@"TypeError"] = @(OKJAVASCRIPT_TOKEN_KIND_TYPEERROR);
        self.tokenKindTab[@"delete"] = @(OKJAVASCRIPT_TOKEN_KIND_DELETE);
        self.tokenKindTab[@"Boolean"] = @(OKJAVASCRIPT_TOKEN_KIND_BOOLEAN);
        self.tokenKindTab[@"URIError"] = @(OKJAVASCRIPT_TOKEN_KIND_URIERROR);
        self.tokenKindTab[@"instanceof"] = @(OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF);
        self.tokenKindTab[@","] = @(OKJAVASCRIPT_TOKEN_KIND_COMMA);
        self.tokenKindTab[@"NumberFormat"] = @(OKJAVASCRIPT_TOKEN_KIND_NUMBERFORMAT);
        self.tokenKindTab[@"if"] = @(OKJAVASCRIPT_TOKEN_KIND_IF);
        self.tokenKindTab[@"finally"] = @(OKJAVASCRIPT_TOKEN_KIND_FINALLY);
        self.tokenKindTab[@"false"] = @(OKJAVASCRIPT_TOKEN_KIND_FALSE);
        self.tokenKindTab[@"."] = @(OKJAVASCRIPT_TOKEN_KIND_DOT);
        self.tokenKindTab[@"case"] = @(OKJAVASCRIPT_TOKEN_KIND_CASE);
        self.tokenKindTab[@"null"] = @(OKJAVASCRIPT_TOKEN_KIND_NULL);
        self.tokenKindTab[@"parseInt"] = @(OKJAVASCRIPT_TOKEN_KIND_PARSEINT);
        self.tokenKindTab[@"RangeError"] = @(OKJAVASCRIPT_TOKEN_KIND_RANGEERROR);
        self.tokenKindTab[@"document"] = @(OKJAVASCRIPT_TOKEN_KIND_DOCUMENT);
        self.tokenKindTab[@"["] = @(OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET);
        self.tokenKindTab[@"undefined"] = @(OKJAVASCRIPT_TOKEN_KIND_UNDEFINED);
        self.tokenKindTab[@"typeof"] = @(OKJAVASCRIPT_TOKEN_KIND_TYPEOF);
        self.tokenKindTab[@"sub"] = @(OKJAVASCRIPT_TOKEN_KIND_FUNCTION);
        self.tokenKindTab[@"isFinite"] = @(OKJAVASCRIPT_TOKEN_KIND_ISFINITE);
        self.tokenKindTab[@"debugger"] = @(OKJAVASCRIPT_TOKEN_KIND_DEBUGGER);
        self.tokenKindTab[@"]"] = @(OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET);
        self.tokenKindTab[@"fluid"] = @(OKJAVASCRIPT_TOKEN_KIND_FLUID);
        self.tokenKindTab[@"continue"] = @(OKJAVASCRIPT_TOKEN_KIND_CONTINUE);
        self.tokenKindTab[@"break"] = @(OKJAVASCRIPT_TOKEN_KIND_BREAK);
        self.tokenKindTab[@"setInterval"] = @(OKJAVASCRIPT_TOKEN_KIND_SETINTERVAL);
        self.tokenKindTab[@"/,/"] = @(OKJAVASCRIPT_TOKEN_KIND____);
        self.tokenKindTab[@"JSON"] = @(OKJAVASCRIPT_TOKEN_KIND_JSON);
        self.tokenKindTab[@"isNaN"] = @(OKJAVASCRIPT_TOKEN_KIND_ISNAN);
        self.tokenKindTab[@"eval"] = @(OKJAVASCRIPT_TOKEN_KIND_EVAL);
        self.tokenKindTab[@"console"] = @(OKJAVASCRIPT_TOKEN_KIND_CONSOLE);
        self.tokenKindTab[@":"] = @(OKJAVASCRIPT_TOKEN_KIND_COLON);
        self.tokenKindTab[@"in"] = @(OKJAVASCRIPT_TOKEN_KIND_IN);
        self.tokenKindTab[@"Infinity"] = @(OKJAVASCRIPT_TOKEN_KIND_INFINITY);
        self.tokenKindTab[@";"] = @(OKJAVASCRIPT_TOKEN_KIND_SEMI);
        self.tokenKindTab[@"for"] = @(OKJAVASCRIPT_TOKEN_KIND_FOR);
        self.tokenKindTab[@"Math"] = @(OKJAVASCRIPT_TOKEN_KIND_MATH);
        self.tokenKindTab[@"ReferenceError"] = @(OKJAVASCRIPT_TOKEN_KIND_REFERENCEERROR);
        self.tokenKindTab[@"StopIteration"] = @(OKJAVASCRIPT_TOKEN_KIND_STOPITERATION);
        self.tokenKindTab[@"uneval"] = @(OKJAVASCRIPT_TOKEN_KIND_UNEVAL);
        self.tokenKindTab[@"throw"] = @(OKJAVASCRIPT_TOKEN_KIND_THROW);
        self.tokenKindTab[@"window"] = @(OKJAVASCRIPT_TOKEN_KIND_WINDOW);
        self.tokenKindTab[@"Date"] = @(OKJAVASCRIPT_TOKEN_KIND_DATE);
        self.tokenKindTab[@"try"] = @(OKJAVASCRIPT_TOKEN_KIND_TRY);
        self.tokenKindTab[@"void"] = @(OKJAVASCRIPT_TOKEN_KIND_VOID);
        self.tokenKindTab[@"while"] = @(OKJAVASCRIPT_TOKEN_KIND_WHILE);
        self.tokenKindTab[@"encodeURIComponent"] = @(OKJAVASCRIPT_TOKEN_KIND_ENCODEURICOMPONENT);
        self.tokenKindTab[@"NaN"] = @(OKJAVASCRIPT_TOKEN_KIND_NAN);
        self.tokenKindTab[@"else"] = @(OKJAVASCRIPT_TOKEN_KIND_ELSE);
        self.tokenKindTab[@"RegExp"] = @(OKJAVASCRIPT_TOKEN_KIND_REGEXP);
        self.tokenKindTab[@"decodeURI"] = @(OKJAVASCRIPT_TOKEN_KIND_DECODEURI);
        self.tokenKindTab[@"encodeURI"] = @(OKJAVASCRIPT_TOKEN_KIND_ENCODEURI);
        self.tokenKindTab[@"var"] = @(OKJAVASCRIPT_TOKEN_KIND_VAR);
        self.tokenKindTab[@"setTimeout"] = @(OKJAVASCRIPT_TOKEN_KIND_SETTIMEOUT);
        self.tokenKindTab[@"SyntaxError"] = @(OKJAVASCRIPT_TOKEN_KIND_SYNTAXERROR);
        self.tokenKindTab[@"decodeURIComponent"] = @(OKJAVASCRIPT_TOKEN_KIND_DECODEURICOMPONENT);
        self.tokenKindTab[@"String"] = @(OKJAVASCRIPT_TOKEN_KIND_STRING);
        self.tokenKindTab[@"fake"] = @(OKJAVASCRIPT_TOKEN_KIND_FAKE);
        self.tokenKindTab[@"new"] = @(OKJAVASCRIPT_TOKEN_KIND_NEW);
        self.tokenKindTab[@"parseFloat"] = @(OKJAVASCRIPT_TOKEN_KIND_PARSEFLOAT);
        self.tokenKindTab[@"alert"] = @(OKJAVASCRIPT_TOKEN_KIND_ALERT);
        self.tokenKindTab[@"Number"] = @(OKJAVASCRIPT_TOKEN_KIND_NUMBER_TITLE);
        self.tokenKindTab[@"Array"] = @(OKJAVASCRIPT_TOKEN_KIND_ARRAY);
        self.tokenKindTab[@"default"] = @(OKJAVASCRIPT_TOKEN_KIND_DEFAULT);
        self.tokenKindTab[@"Object"] = @(OKJAVASCRIPT_TOKEN_KIND_OBJECT);
        self.tokenKindTab[@"do"] = @(OKJAVASCRIPT_TOKEN_KIND_DO);
        self.tokenKindTab[@"this"] = @(OKJAVASCRIPT_TOKEN_KIND_THIS);
        self.tokenKindTab[@"with"] = @(OKJAVASCRIPT_TOKEN_KIND_WITH);
        self.tokenKindTab[@"switch"] = @(OKJAVASCRIPT_TOKEN_KIND_SWITCH);
        self.tokenKindTab[@"true"] = @(OKJAVASCRIPT_TOKEN_KIND_TRUE);
        self.tokenKindTab[@"{"] = @(OKJAVASCRIPT_TOKEN_KIND_OPENCURLY);

        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_OPENPAREN] = @"(";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY] = @"}";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CATCH] = @"catch";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_RETURN] = @"return";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN] = @")";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_TYPEERROR] = @"TypeError";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DELETE] = @"delete";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_BOOLEAN] = @"Boolean";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_URIERROR] = @"URIError";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF] = @"instanceof";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_COMMA] = @",";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_NUMBERFORMAT] = @"NumberFormat";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_IF] = @"if";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_FINALLY] = @"finally";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_FALSE] = @"false";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DOT] = @".";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CASE] = @"case";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_NULL] = @"null";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_PARSEINT] = @"parseInt";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_RANGEERROR] = @"RangeError";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DOCUMENT] = @"document";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET] = @"[";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_UNDEFINED] = @"undefined";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_TYPEOF] = @"typeof";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_FUNCTION] = @"sub";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ISFINITE] = @"isFinite";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DEBUGGER] = @"debugger";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET] = @"]";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_FLUID] = @"fluid";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CONTINUE] = @"continue";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_BREAK] = @"break";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_SETINTERVAL] = @"setInterval";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND____] = @"/,/";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_JSON] = @"JSON";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ISNAN] = @"isNaN";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_EVAL] = @"eval";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_CONSOLE] = @"console";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_COLON] = @":";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_IN] = @"in";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_INFINITY] = @"Infinity";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_SEMI] = @";";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_FOR] = @"for";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_MATH] = @"Math";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_REFERENCEERROR] = @"ReferenceError";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_STOPITERATION] = @"StopIteration";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_UNEVAL] = @"uneval";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_THROW] = @"throw";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_WINDOW] = @"window";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DATE] = @"Date";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_TRY] = @"try";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_VOID] = @"void";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_WHILE] = @"while";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ENCODEURICOMPONENT] = @"encodeURIComponent";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_NAN] = @"NaN";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ELSE] = @"else";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_REGEXP] = @"RegExp";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DECODEURI] = @"decodeURI";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ENCODEURI] = @"encodeURI";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_VAR] = @"var";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_SETTIMEOUT] = @"setTimeout";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_SYNTAXERROR] = @"SyntaxError";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DECODEURICOMPONENT] = @"decodeURIComponent";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_STRING] = @"String";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_FAKE] = @"fake";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_NEW] = @"new";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_PARSEFLOAT] = @"parseFloat";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ALERT] = @"alert";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_NUMBER_TITLE] = @"Number";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_ARRAY] = @"Array";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DEFAULT] = @"default";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_OBJECT] = @"Object";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_DO] = @"do";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_THIS] = @"this";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_WITH] = @"with";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_SWITCH] = @"switch";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_TRUE] = @"true";
        self.tokenKindNameTab[OKJAVASCRIPT_TOKEN_KIND_OPENCURLY] = @"{";

        self.program_memo = [NSMutableDictionary dictionary];
        self.element_memo = [NSMutableDictionary dictionary];
        self.identifier_memo = [NSMutableDictionary dictionary];
        self.string_memo = [NSMutableDictionary dictionary];
        self.number_memo = [NSMutableDictionary dictionary];
        self.specialSymbol_memo = [NSMutableDictionary dictionary];
        self.symbol_memo = [NSMutableDictionary dictionary];
        self.comment_memo = [NSMutableDictionary dictionary];
        self.regex_memo = [NSMutableDictionary dictionary];
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
    self.regex_memo = nil;
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

- (void)_clearMemo {
    [_program_memo removeAllObjects];
    [_element_memo removeAllObjects];
    [_identifier_memo removeAllObjects];
    [_string_memo removeAllObjects];
    [_number_memo removeAllObjects];
    [_specialSymbol_memo removeAllObjects];
    [_symbol_memo removeAllObjects];
    [_comment_memo removeAllObjects];
    [_regex_memo removeAllObjects];
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
	
        [t.symbolState add:@"||"];
        [t.symbolState add:@"&&"];
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
        
        // comment state should fallback to delimit state to match regex delimited strings
        t.commentState.fallbackState = t.delimitState;
        
        // regex delimited strings
        NSCharacterSet *cs = [[NSCharacterSet newlineCharacterSet] invertedSet];
        [t.delimitState addStartMarker:@"/" endMarker:@"/" allowedCharacterSet:cs];

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
    
    if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_BREAK, OKJAVASCRIPT_TOKEN_KIND_CASE, OKJAVASCRIPT_TOKEN_KIND_CATCH, OKJAVASCRIPT_TOKEN_KIND_CONTINUE, OKJAVASCRIPT_TOKEN_KIND_DEBUGGER, OKJAVASCRIPT_TOKEN_KIND_DEFAULT, OKJAVASCRIPT_TOKEN_KIND_DELETE, OKJAVASCRIPT_TOKEN_KIND_DO, OKJAVASCRIPT_TOKEN_KIND_ELSE, OKJAVASCRIPT_TOKEN_KIND_FINALLY, OKJAVASCRIPT_TOKEN_KIND_FOR, OKJAVASCRIPT_TOKEN_KIND_FUNCTION, OKJAVASCRIPT_TOKEN_KIND_IF, OKJAVASCRIPT_TOKEN_KIND_IN, OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF, OKJAVASCRIPT_TOKEN_KIND_NEW, OKJAVASCRIPT_TOKEN_KIND_RETURN, OKJAVASCRIPT_TOKEN_KIND_SWITCH, OKJAVASCRIPT_TOKEN_KIND_THIS, OKJAVASCRIPT_TOKEN_KIND_THROW, OKJAVASCRIPT_TOKEN_KIND_TRY, OKJAVASCRIPT_TOKEN_KIND_TYPEOF, OKJAVASCRIPT_TOKEN_KIND_VAR, OKJAVASCRIPT_TOKEN_KIND_VOID, OKJAVASCRIPT_TOKEN_KIND_WHILE, OKJAVASCRIPT_TOKEN_KIND_WITH, 0]) {
        [self reserved_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ALERT, OKJAVASCRIPT_TOKEN_KIND_ARRAY, OKJAVASCRIPT_TOKEN_KIND_BOOLEAN, OKJAVASCRIPT_TOKEN_KIND_CONSOLE, OKJAVASCRIPT_TOKEN_KIND_DATE, OKJAVASCRIPT_TOKEN_KIND_DECODEURI, OKJAVASCRIPT_TOKEN_KIND_DECODEURICOMPONENT, OKJAVASCRIPT_TOKEN_KIND_DOCUMENT, OKJAVASCRIPT_TOKEN_KIND_ENCODEURI, OKJAVASCRIPT_TOKEN_KIND_ENCODEURICOMPONENT, OKJAVASCRIPT_TOKEN_KIND_EVAL, OKJAVASCRIPT_TOKEN_KIND_FAKE, OKJAVASCRIPT_TOKEN_KIND_FALSE, OKJAVASCRIPT_TOKEN_KIND_FLUID, OKJAVASCRIPT_TOKEN_KIND_INFINITY, OKJAVASCRIPT_TOKEN_KIND_ISFINITE, OKJAVASCRIPT_TOKEN_KIND_ISNAN, OKJAVASCRIPT_TOKEN_KIND_JSON, OKJAVASCRIPT_TOKEN_KIND_MATH, OKJAVASCRIPT_TOKEN_KIND_NAN, OKJAVASCRIPT_TOKEN_KIND_NULL, OKJAVASCRIPT_TOKEN_KIND_NUMBERFORMAT, OKJAVASCRIPT_TOKEN_KIND_NUMBER_TITLE, OKJAVASCRIPT_TOKEN_KIND_OBJECT, OKJAVASCRIPT_TOKEN_KIND_PARSEFLOAT, OKJAVASCRIPT_TOKEN_KIND_PARSEINT, OKJAVASCRIPT_TOKEN_KIND_RANGEERROR, OKJAVASCRIPT_TOKEN_KIND_REFERENCEERROR, OKJAVASCRIPT_TOKEN_KIND_REGEXP, OKJAVASCRIPT_TOKEN_KIND_SETINTERVAL, OKJAVASCRIPT_TOKEN_KIND_SETTIMEOUT, OKJAVASCRIPT_TOKEN_KIND_STOPITERATION, OKJAVASCRIPT_TOKEN_KIND_STRING, OKJAVASCRIPT_TOKEN_KIND_SYNTAXERROR, OKJAVASCRIPT_TOKEN_KIND_TRUE, OKJAVASCRIPT_TOKEN_KIND_TYPEERROR, OKJAVASCRIPT_TOKEN_KIND_UNDEFINED, OKJAVASCRIPT_TOKEN_KIND_UNEVAL, OKJAVASCRIPT_TOKEN_KIND_URIERROR, OKJAVASCRIPT_TOKEN_KIND_WINDOW, 0]) {
        [self builtin_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self identifier_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self string_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self number_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND____, 0]) {
        [self regex_]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET, OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY, OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN, OKJAVASCRIPT_TOKEN_KIND_COLON, OKJAVASCRIPT_TOKEN_KIND_COMMA, OKJAVASCRIPT_TOKEN_KIND_DOT, OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET, OKJAVASCRIPT_TOKEN_KIND_OPENCURLY, OKJAVASCRIPT_TOKEN_KIND_OPENPAREN, OKJAVASCRIPT_TOKEN_KIND_SEMI, 0]) {
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
    
    [self matchNumber:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"number"];
}

- (void)number_ {
    [self parseRule:@selector(__number) withMemo:_number_memo];
}

- (void)__specialSymbol {
    
    if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_OPENCURLY, 0]) {
        [self openCurly_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY, 0]) {
        [self closeCurly_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN, 0]) {
        [self openParen_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN, 0]) {
        [self closeParen_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET, 0]) {
        [self openBracket_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET, 0]) {
        [self closeBracket_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_SEMI, 0]) {
        [self semi_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COMMA, 0]) {
        [self comma_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DOT, 0]) {
        [self dot_]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_COLON, 0]) {
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

- (void)__regex {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND____ discard:NO]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self testAndThrow:(id)^{ return MATCHES_IGNORE_CASE(@"^[imxs]+$", LS(1)); }]; 
        [self matchWord:NO]; 
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"regex"];
}

- (void)regex_ {
    [self parseRule:@selector(__regex) withMemo:_regex_memo];
}

- (void)__openCurly {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENCURLY discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openCurly"];
}

- (void)openCurly_ {
    [self parseRule:@selector(__openCurly) withMemo:_openCurly_memo];
}

- (void)__closeCurly {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSECURLY discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeCurly"];
}

- (void)closeCurly_ {
    [self parseRule:@selector(__closeCurly) withMemo:_closeCurly_memo];
}

- (void)__openBracket {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENBRACKET discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openBracket"];
}

- (void)openBracket_ {
    [self parseRule:@selector(__openBracket) withMemo:_openBracket_memo];
}

- (void)__closeBracket {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSEBRACKET discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeBracket"];
}

- (void)closeBracket_ {
    [self parseRule:@selector(__closeBracket) withMemo:_closeBracket_memo];
}

- (void)__openParen {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_OPENPAREN discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"openParen"];
}

- (void)openParen_ {
    [self parseRule:@selector(__openParen) withMemo:_openParen_memo];
}

- (void)__closeParen {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_CLOSEPAREN discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"closeParen"];
}

- (void)closeParen_ {
    [self parseRule:@selector(__closeParen) withMemo:_closeParen_memo];
}

- (void)__semi {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_SEMI discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"semi"];
}

- (void)semi_ {
    [self parseRule:@selector(__semi) withMemo:_semi_memo];
}

- (void)__comma {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_COMMA discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"comma"];
}

- (void)comma_ {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__dot {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_DOT discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"dot"];
}

- (void)dot_ {
    [self parseRule:@selector(__dot) withMemo:_dot_memo];
}

- (void)__colon {
    
    [self match:OKJAVASCRIPT_TOKEN_KIND_COLON discard:NO]; 

    [self fireSyntaxSelector:@selector(parser:didMatchLeaf:) withRuleName:@"colon"];
}

- (void)colon_ {
    [self parseRule:@selector(__colon) withMemo:_colon_memo];
}

- (void)__reserved {
    
    if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_BREAK, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_BREAK discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CASE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_CASE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CATCH, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_CATCH discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CONTINUE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_CONTINUE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DEBUGGER, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DEBUGGER discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DEFAULT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DEFAULT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DELETE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DELETE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DO, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DO discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ELSE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ELSE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_FINALLY, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_FINALLY discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_FOR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_FOR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_FUNCTION, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_FUNCTION discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_IF, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_IF discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_IN, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_IN discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_INSTANCEOF discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_NEW, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_NEW discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_RETURN, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_RETURN discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_SWITCH, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_SWITCH discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_THIS, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_THIS discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_THROW, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_THROW discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_TRY, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_TRY discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_TYPEOF, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_TYPEOF discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_VAR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_VAR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_VOID, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_VOID discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_WHILE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_WHILE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_WITH, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_WITH discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'reserved'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"reserved"];
}

- (void)reserved_ {
    [self parseRule:@selector(__reserved) withMemo:_reserved_memo];
}

- (void)__builtin {
    
    if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ALERT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ALERT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ARRAY, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ARRAY discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_BOOLEAN, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_BOOLEAN discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DATE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DATE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DECODEURI, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DECODEURI discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DECODEURICOMPONENT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DECODEURICOMPONENT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ENCODEURI, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ENCODEURI discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ENCODEURICOMPONENT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ENCODEURICOMPONENT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_EVAL, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_EVAL discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_FAKE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_FAKE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_FLUID, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_FLUID discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_FALSE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_FALSE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_INFINITY, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_INFINITY discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ISFINITE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ISFINITE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_ISNAN, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_ISNAN discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_JSON, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_JSON discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_MATH, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_MATH discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_NAN, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_NAN discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_NULL, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_NULL discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_NUMBER_TITLE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_NUMBER_TITLE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_NUMBERFORMAT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_NUMBERFORMAT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_OBJECT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_OBJECT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_PARSEFLOAT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_PARSEFLOAT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_PARSEINT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_PARSEINT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_RANGEERROR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_RANGEERROR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_REFERENCEERROR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_REFERENCEERROR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_REGEXP, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_REGEXP discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_STOPITERATION, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_STOPITERATION discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_STRING, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_STRING discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_SYNTAXERROR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_SYNTAXERROR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_TYPEERROR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_TYPEERROR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_TRUE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_TRUE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_UNDEFINED, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_UNDEFINED discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_UNEVAL, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_UNEVAL discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_URIERROR, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_URIERROR discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_WINDOW, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_WINDOW discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_CONSOLE, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_CONSOLE discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_DOCUMENT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_DOCUMENT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_SETTIMEOUT, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_SETTIMEOUT discard:NO]; 
    } else if ([self predicts:OKJAVASCRIPT_TOKEN_KIND_SETINTERVAL, 0]) {
        [self match:OKJAVASCRIPT_TOKEN_KIND_SETINTERVAL discard:NO]; 
    } else {
        [self raise:@"No viable alternative found in rule 'builtin'."];
    }

    [self fireSyntaxSelector:@selector(parser:didMatchInterior:) withRuleName:@"builtin"];
}

- (void)builtin_ {
    [self parseRule:@selector(__builtin) withMemo:_builtin_memo];
}

@end
