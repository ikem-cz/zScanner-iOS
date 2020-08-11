#import "SeaCatInternals.h"


void _SCLog(char level, NSString * message)
{
    NSLog(@"SeaCat/%c %@", level, message);
}

void _SCLogV(char level, NSString *format, ...)
{
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	
    _SCLog(level, message);

#if !__has_feature(objc_arc)
	[message release];
#endif
}
