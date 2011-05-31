//
//  MGNapiProjektEngine.m
//  WhatSub
//
//  Created by Marcin Grabda on 1/28/10.
//  Copyright 2010 www.burningtomato.com. All rights reserved.
//

#import "NapiProjektEngine.h"
#import <openssl/md5.h>
#import "AppUtil.h"

@implementation NapiProjektEngine

- (NSData*)retrieveSubtitlesForMovieInPath:(NSString*)moviePath hash:(NSString**)hashPtr
{
	NSString* hash = [self md5ForFileInPath:moviePath limitedTo10MB:YES];
	NSString* token = [self npFDigest:hash];
	
	NSError* error = nil;
	NSString* urlString = [self getURLForHash:hash token:token];
	NSURL* url = [NSURL URLWithString:urlString];
	
	NSLog(@"Retrieving subtitles: %@", urlString);
	NSData* contents = [NSData dataWithContentsOfURL:url options:0 error:&error];
	
	[hash retain];
	*hashPtr = hash;
	
	char buffer[4];
	[contents getBytes:(char*)buffer length:sizeof(buffer)];
	
	NSString* magic = [[NSString alloc] initWithBytes:buffer length:sizeof(buffer) encoding:NSASCIIStringEncoding];
	if ([magic hasPrefix:@"7z"])
    {
		return contents;
	}
    
    NSString* reason;
    NSString* movieFileName = [moviePath lastPathComponent];
    if ([magic isEqualToString:@"NPc0"])
    {
        reason = [NSString stringWithFormat:@"Subtitles not found for movie %@", movieFileName];
    }
    else
    {
        reason = [NSString stringWithFormat:@"Subtitles for movie %@ could not be downloaded", movieFileName];
    }
	
    NSException* e = [NSException exceptionWithName:@"SubtitlesException" reason:reason userInfo:nil];
    @throw e;
}

- (NSString*)getURLForHash:(NSString*)hash token:(NSString*)token
{	
	/* TODO move to configuration file... */
	NSString* urlFormatString = 
		@"http://napiprojekt.pl/unit_napisy/dl.php?l=%@&f=%@&t=%@&v=other&kolejka=false&nick=%@&pass=%@";
    NSString* langCode = [AppUtil getNPLanguageCode];
	NSString* nickname = [AppUtil getNPUsername];
	NSString* password = [AppUtil getNPPassword];
	
	return [NSString stringWithFormat:urlFormatString, langCode, hash, token, nickname, password];
}

- (NSString*)npFDigest:(NSString*)input
{
	if ([input length] != 32) return @"";
	
	int idx[] = { 0xe, 0x3, 0x6, 0x8, 0x2 },
	mul[] = { 2, 2, 5, 4, 3 },
	add[] = { 0x0, 0xd, 0x10, 0xb, 0x5 },
	a, m, i, t, v;
	
	NSMutableString* b = [NSMutableString stringWithString:@""];
	char tmp[2] = { 0, 0 };
	
	for(int j = 0; j <= 4; j++)
	{
		a = add[j];
		m = mul[j];
		i = idx[j];
		
		tmp[0] = [input characterAtIndex:i];
		t = a + (int)(strtol(tmp, NULL, 16));
		
		NSString* substring = [[input substringFromIndex:t] substringToIndex:2];
		const char* cString = [substring cStringUsingEncoding:NSASCIIStringEncoding];
		
		v = (int)strtol(cString, NULL, 16);
		
		snprintf(tmp, 2, "%x", (v * m) % 0x10);
		NSString* tmpString = [NSString stringWithCString:tmp encoding:NSASCIIStringEncoding];
		
		[b appendString:tmpString];
	}
	
	return b;
}

- (NSString*)md5ForFileInPath:(NSString*)path limitedTo10MB:(BOOL)limited
{	
	int length = 10485760;
	void* buffer = malloc(length);
	
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	NSData* data = [fileHandle readDataOfLength:length];
	[data getBytes:buffer length:length];
	
	unsigned char *digest = MD5(buffer, length, NULL);
	NSString* md5String = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
						   digest[0], digest[1],
						   digest[2], digest[3],
						   digest[4], digest[5],
						   digest[6], digest[7],
						   digest[8], digest[9],
						   digest[10], digest[11],
						   digest[12], digest[13],
						   digest[14], digest[15]
						   ];
	
	free(buffer);
	
	return md5String;
}

@end
