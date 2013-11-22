//
//  ALFunc_Helper.m
//  call_at_anywhere
//
//  Created by cccssw on 11/22/13.
//  Copyright (c) 2013 cccssw. All rights reserved.
//

#import "ALFunc_Helper.h"
#include <dlfcn.h>
#define LIB_PATH @"libs"//relative path for your binary files

@implementation ALFunc_Helper

//your function definitions
-(void)_createFairPlay:(unsigned char*)charArray len:(int)len signature:(char*)sigCharArray sigLen:(int*)sigLen buffer:(char*)buffer bufferLen:(int*)bufferLen
{
    arbitraryFunction func = [self __funcWrap:@"_mh_execute_header"];
//for debug
//    if (func==NULL) {
//        NSDictionary *ddd = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%p",func],@"hanlers", nil];
//        [ddd writeToFile:[NSString stringWithFormat:@"/Users/cccssw/test_%@.plist",[NSDate date]] atomically:NO];
//    }
    func += 0x021260;//your work to caculate the precise address, or contact me on my blog
    func(charArray,len,sigCharArray,sigLen,buffer,bufferLen);
}


//end your function definitions

-(NSDictionary*)__loadFuncToFileMap
{
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
    [mdic setObject:@"apsd_final" forKey:@"_mh_execute_header"];
    return mdic;
}


-(NSDictionary*)functionAddresses
{
    NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
    for (NSString* func in _funcToFileMap) {
        [mdic setObject:[NSString stringWithFormat:@"%p",[self __funcAddrByFuncName:func]] forKey:func];
    }
    return mdic;
}
+(id)sharedInstance
{
    static dispatch_once_t onceToken;
    __strong static id _sharedObject;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}
-(id)init
{
    if (self =[super init]) {
        _funcToFileMap = [self __loadFuncToFileMap];
        _bundles = [self __bundles];
        _funcs = [self __funcs];
        
        NSUInteger fileNum = [_bundles count];
        NSUInteger funcNum = [_funcs count];
        _handlers = malloc(fileNum*sizeof(void*));
        memset(_handlers, 0, fileNum*sizeof(void*));
        _funcAddrs = malloc(funcNum*sizeof(arbitraryFunction));
        memset(_funcAddrs, 0, funcNum*sizeof(arbitraryFunction));
    }
    return self;
}






-(arbitraryFunction)__funcWrap:(NSString*)name
{
    arbitraryFunction func = NULL;
    @try {
        func = [self __funcAddrByFuncName:name];
    }
    @catch (NSException *exception) {
        //TODO When fails it is up to you to notice or ...
    }
    @finally {
        return func;
    }
}



-(void*)__tryLoadBundleForFunc:(NSString*)func
{
    NSString *file = [_funcToFileMap objectForKey:func];
    if(file!=nil){
        void *handler = [self __cachedHandlers:file];
        return handler;
    }
    return NULL;
}




-(arbitraryFunction)__funcAddrByFuncName:(NSString*)name
{
    void*handler = [self __tryLoadBundleForFunc:name];
    if (handler!=NULL) {
        NSUInteger index = [_funcs indexOfObject:name];
        int x= index*sizeof(arbitraryFunction);
        arbitraryFunction *addrAddress = (arbitraryFunction*)(_funcAddrs)+index;
        arbitraryFunction addr = *addrAddress;
        if (addr!=NULL) {
            return addr;
        }
        *(void**)(addrAddress) = dlsym(handler,[name UTF8String]);
        addr = *addrAddress;
        if (addr==NULL) {
            @throw ([NSException exceptionWithName:@"bundle_func_error" reason:@"func load failed" userInfo:nil]);
        }
        return addr;
    }else{
        @throw ([NSException exceptionWithName:@"bundle_error" reason:@"bundle load failed" userInfo:nil]);
    }
    return NULL;
}

-(void*)__cachedHandlers:(NSString*)fileName
{
    arbitraryFunction handler = [self __realCachedHandlers:fileName];
    if (handler==NULL) {
        NSUInteger index =[_bundles indexOfObject:fileName];
        void **addr = (void**)(_handlers)+index;
        handler = [self __tryLoadBundle:fileName];
        *(addr)= handler;
    }
    return handler;
}

-(void*)__realCachedHandlers:(NSString*)fileName
{
    if ([_bundles containsObject:fileName]) {
        NSUInteger index =[_bundles indexOfObject:fileName];
        void **handlerAddr = (void**)(_handlers)+index;
        void* handler = *handlerAddr;
        return handler;
    }
    return NULL;
}

-(void *)__tryLoadBundle:(NSString*)fileName
{
    NSString* path = [[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:LIB_PATH];
    
    path = [path stringByAppendingPathComponent:fileName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        void *handler = dlopen([path UTF8String], RTLD_NOW|RTLD_GLOBAL);
        return handler;
    }
    path = [[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:LIB_PATH];
    path = [path stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        void *handler = dlopen([path UTF8String], RTLD_NOW|RTLD_GLOBAL);
        return handler;
    }
    return NULL;
}


-(NSArray*)__bundles
{
    NSMutableArray *marr = [NSMutableArray array];
    NSDictionary *map = [self __loadFuncToFileMap];
    for (NSString *func in map) {
        NSString*file = [map objectForKey:func];
        if (![marr containsObject:file]) {
            [marr addObject:file];
        }
    }
    return marr;
}
-(NSArray*)__funcs
{
    NSMutableArray *marr = [NSMutableArray array];
    NSDictionary *map = [self __loadFuncToFileMap];
    for (NSString *func in map) {
        if (![marr containsObject:func]) {
            [marr addObject:func];
        }
    }
    return marr;
}
-(void)dealloc
{
    for (NSString *name in _bundles) {
        void * handler = [self __realCachedHandlers:name];
        if (handler!=NULL) {
            dlclose(handler);
        }
    }
    free(_handlers);
    free(_funcAddrs);
}
@end
