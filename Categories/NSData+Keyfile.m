//
//  NSData+Keyfile.m
//  KeePassKit
//
//  Created by Michael Starke on 12.07.13.
//  Copyright (c) 2013 HicknHack Software GmbH. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import "NSData+Keyfile.h"

#import <CommonCrypto/CommonCrypto.h>

#import "DDXMLElementAdditions.h"
#import "NSMutableData+Base64.h"
#import "KPKErrors.h"




@implementation NSData (Keyfile)

+ (NSData *)dataWithWithContentsOfKeyFile:(NSURL *)url version:(KPKVersion)version error:(NSError *__autoreleasing *)error {
  switch (version) {
    case KPKVersion1:
      return [self _dataVersion1WithWithContentsOfKeyFile:url error:error];
    case KPKVersion2:
      return nil;
  }
}

+ (NSData *)_dataVersion1WithWithContentsOfKeyFile:(NSURL *)url error:(NSError *__autoreleasing *)error {
  // Open the keyfile
  NSData *fileData = [NSData dataWithContentsOfURL:url
                                           options:(NSDataReadingUncached|NSDataReadingMappedIfSafe)
                                             error:error];
  if(error || !fileData) {
    return nil;
  }
  
  if([fileData length] == 32) {
    return fileData; // Loading of a 32 bit binary file succeded;
  }
  NSData *decordedData = nil;
  if ([fileData length] == 64) {
    decordedData = [self _keyDataFromHex:fileData];
  }
  if(!decordedData) {
    decordedData = [self _keyDataFromHash:fileData];
  }
  return decordedData;
}

+ (NSData *)_dataVersion2WithWithContentsOfKeyFile:(NSURL *)url error:(NSError *__autoreleasing *)error {
  // Try and load a 2.x XML keyfile first
  NSData *data = [self _dataWithContentOfXMLKeyFile:url error:error];
  if(!data) {
    return [self _dataVersion1WithWithContentsOfKeyFile:url error:error];
  }
  return data;
}

+ (NSData *)_dataWithContentOfXMLKeyFile:(NSURL *)fileURL error:(NSError *__autoreleasing *)error {
  NSString *xmlString = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:error];
  if (xmlString == nil) {
    return nil;
  }
  
  DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:error];
  if (document == nil) {
    return nil;
  }
  
  // Get the root document element
  DDXMLElement *rootElement = [document rootElement];
  
  DDXMLElement *keyElement = [rootElement elementForName:@"Key"];
  if (keyElement == nil) {
    document = nil;
    NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedStringFromTable(@"ERROR_KEYFILE_NO_KEY_XML_ELEMENT", @"LocalizeableErrors", "")};
    if(error != NULL) {
      *error = [NSError errorWithDomain:KPKErrorDomain code:KPKErrorKeyParsingFailed userInfo:userInfo];
    }
    return nil;
  }
  
  DDXMLElement *dataElement = [keyElement elementForName:@"Data"];
  if (dataElement == nil) {
    document = nil;
    @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse keyfile" userInfo:nil];
  }
  
  NSString *dataString = [dataElement stringValue];
  if (dataString == nil) {
    document = nil;
    @throw [NSException exceptionWithName:@"ParseError" reason:@"Failed to parse keyfile" userInfo:nil];
  }
  
  return [NSMutableData mutableDataWithBase64DecodedData:[dataString dataUsingEncoding:NSASCIIStringEncoding]];
}

+ (NSData *)_keyDataFromHex:(NSData *)hexData {
  uint8_t buffer[32];
 
  NSString *hexString = [[NSString alloc] initWithData:hexData encoding:NSUTF8StringEncoding];
  if(!hexString) {
   return nil;
  }
  if([hexString length] != 64) {
    return nil; // No valid lenght found
  }
  BOOL scanOk = YES;
  @autoreleasepool {
    for(NSUInteger iIndex = 0; iIndex < 32; iIndex++) {
      NSString *split = [hexString substringWithRange:NSMakeRange(iIndex * 2, 2)];
      NSScanner * scanner = [NSScanner scannerWithString:split];
      uint32_t integer = 0;
      if(![scanner scanHexInt:&integer]) {
        scanOk = NO;
        break;
      }
      buffer[iIndex] = (uint8_t)integer;
    }
  }
  if(!scanOk) {
    return nil; // Hex scanning failed
  }
  return [NSData dataWithBytes:buffer length:32];
}

+ (NSData *)_keyDataFromHash:(NSData *)fileData {
  uint8_t buffer[32];
  NSData *chunk;
  
  CC_SHA256_CTX ctx;
  CC_SHA256_Init(&ctx);
  @autoreleasepool {
    const NSUInteger chunkSize = 2048;
    for(NSUInteger iIndex = 0; iIndex < [fileData length]; iIndex += chunkSize) {
      NSUInteger maxChunkLenght = MIN(fileData.length - iIndex, chunkSize);
      chunk = [fileData subdataWithRange:NSMakeRange(iIndex, maxChunkLenght)];
      CC_SHA256_Update(&ctx, chunk.bytes, (CC_LONG)chunk.length);
    }
  }
  CC_SHA256_Final(buffer, &ctx);
  
  return [NSData dataWithBytes:buffer length:32];
}



@end
