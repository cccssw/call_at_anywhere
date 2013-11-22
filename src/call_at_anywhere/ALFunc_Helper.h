//
//  ALFunc_Helper.h
//  call_at_anywhere
//
//  Created by cccssw on 11/22/13.
//  Copyright (c) 2013 cccssw. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void* (*arbitraryFunction)();
@interface ALFunc_Helper : NSObject{
    void* _handlers;
    arbitraryFunction* _funcAddrs;
}
//this is an example for calling a function in a binary file
-(void)_createFairPlay:(unsigned char*)charArray len:(int)len signature:(char*)sigCharArray sigLen:(int*)sigLen buffer:(char*)buffer bufferLen:(int*)bufferLen;//tested successful
//All you need to do is put the binay file under your LIB_PATH directory,and set the symentic symbol name in the __loadFuncToFileMap function also define your function like above

-(arbitraryFunction)__funcWrap:(NSString*)name;
@property (nonatomic,readonly)NSDictionary *funcToFileMap;
@property (nonatomic,readonly)NSArray *bundles;
@property (nonatomic,readonly)NSArray *funcs;

+(id)sharedInstance;
-(void)unloadAll;
-(NSDictionary*)functionAddresses;


@end
