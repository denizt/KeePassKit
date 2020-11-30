//
//  KPKOTP.h
//  KeePassKit
//
//  Created by Michael Starke on 09.12.17.
//  Copyright © 2017 HicknHack Software GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (KPKOTPDataConversion)

@property (readonly) NSUInteger kpk_unsignedInteger;

@end

typedef NS_ENUM(NSUInteger, KPKOTPHashAlgorithm ) {
  KPKOTPHashAlgorithmSha1,
  KPKOTPHashAlgorithmSha256,
  KPKOTPHashAlgorithmSha512,
  KPKOTPHashAlgorithmDefault = KPKOTPHashAlgorithmSha1
};

typedef NS_ENUM(NSUInteger, KPKOTPGeneratorType) {
  KPKOTPGeneratorHmacOTP,
  KPKOTPGeneratorTOTP,
  KPKOTPGeneratorSteamOTP // unsupported for now!
};

@interface KPKOTPGenerator : NSObject

@property (readonly, copy) NSString *string; // will be formatted according to the supplied options on init
@property (readonly, copy) NSData *data; // will return the raw data of the OTP generator, you normally should only need the string value

@property (copy) NSData *key; // the seed key for the OTP Generator, default=empty data
@property KPKOTPGeneratorType type; // the type of OTP Generator to use, default=KPKOTPGeneratorHmacOTP
@property KPKOTPHashAlgorithm hashAlgorithm; // the hash algorithm to base the OTP data on, default=KPKTOPHashAlgorithmSha1
@property NSTimeInterval timeBase; // the base time for Timed OTP, default=0 -> unix reference time
@property NSUInteger timeSlice; // the time slice for Timed OTP, default=30
@property NSTimeInterval time; // the time to calculate the Timed OTP for, default=0
@property NSUInteger counter; // the counter to calculate the Hmac OTP for, default=0
@property NSUInteger numberOfDigits; // the number of digits to vent as code, default=6

- (BOOL)setupWithOptions:(NSDictionary <NSString *, NSString *>*)options;
@end

NS_ASSUME_NONNULL_END
