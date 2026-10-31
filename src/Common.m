#import "Common.h"
#import <objc/runtime.h>
#import <arpa/inet.h>

NSNotificationName const TweakSettingsDidChangeNotification = @"TweakSettingsDidChangeNotification";
static NSString *const TweakKeyMode = @"daypatch.urlBarMode";
static NSString *const TweakKeyLastMode = @"daypatch.lastHiddenMode";
NSString *const TweakKeyCommandBarStyle = @"daypatch.commandBarStyle";
NSString *const TweakKeyRevealOnHover = @"daypatch.revealOnHover";
NSString *const TweakKeyCmdLFocusesSidebar = @"daypatch.cmdLFocusesSidebar";
NSString *const TweakKeySidebarFullURL = @"daypatch.sidebarShowsFullURL";
NSString *const TweakKeySidebarNavButtons = @"daypatch.sidebarShowsNavButtons";

@implementation TweakSettings

+ (void)initialize {
    // One-time move from the project's previous name: copy "arcedDia.*" settings.
    NSUserDefaults *d = NSUserDefaults.standardUserDefaults;
    if (![d boolForKey:@"daypatch.migrated"]) {
        NSDictionary *all = d.dictionaryRepresentation;
        for (NSString *k in all)
            if ([k hasPrefix:@"arcedDia."]) {
                NSString *nk = [@"daypatch." stringByAppendingString:[k substringFromIndex:9]];
                if (![d objectForKey:nk]) [d setObject:all[k] forKey:nk];
            }
        [d setBool:YES forKey:@"daypatch.migrated"];
    }
    [NSUserDefaults.standardUserDefaults registerDefaults:@{
        TweakKeyMode: @(TweakURLBarModeSidebar),
        TweakKeyLastMode: @(TweakURLBarModeSidebar),
        TweakKeyRevealOnHover: @NO,
        TweakKeyCmdLFocusesSidebar: @YES,
        TweakKeySidebarFullURL: @NO,
        TweakKeySidebarNavButtons: @YES,
        TweakKeyHideAI: @YES,
        // Network blocking is opt-in; hiding AI UI only changes what's shown locally.
        TweakKeyBlockAI: @NO,
        TweakKeyBlockTelemetry: @NO,
        TweakKeyDisableOnDeviceAI: @YES,
        TweakKeyNoBackgroundNetworking: @NO,
        TweakKeyRendererLimit: @0,
        TweakKeyNewTabPalette: @YES,
        TweakKeyCommandBarStyle: @(TweakCommandBarStyleNative),
    }];
}

+ (NSUserDefaults *)d { return NSUserDefaults.standardUserDefaults; }
+ (void)changed { [NSNotificationCenter.defaultCenter postNotificationName:TweakSettingsDidChangeNotification object:nil]; }

+ (TweakURLBarMode)urlBarMode { return [self.d integerForKey:TweakKeyMode]; }
+ (void)setURLBarMode:(TweakURLBarMode)mode {
    [self.d setInteger:mode forKey:TweakKeyMode];
    if (mode != TweakURLBarModeTop) [self.d setInteger:mode forKey:TweakKeyLastMode];
    [self changed];
}
+ (void)toggleHiding {
    if (self.urlBarMode == TweakURLBarModeTop) [self setURLBarMode:[self.d integerForKey:TweakKeyLastMode] ?: TweakURLBarModeSidebar];
    else [self setURLBarMode:TweakURLBarModeTop];
}

+ (BOOL)revealOnHover { return [self.d boolForKey:TweakKeyRevealOnHover]; }
+ (BOOL)cmdLFocusesSidebar { return [self.d boolForKey:TweakKeyCmdLFocusesSidebar]; }
+ (BOOL)sidebarShowsFullURL { return [self.d boolForKey:TweakKeySidebarFullURL]; }
+ (BOOL)sidebarShowsNavButtons { return [self.d boolForKey:TweakKeySidebarNavButtons]; }

+ (BOOL)boolForKey:(NSString *)key { return [self.d boolForKey:key]; }
+ (void)setBool:(BOOL)value forKey:(NSString *)key { [self.d setBool:value forKey:key]; [self changed]; }
+ (void)setString:(NSString *)value forKey:(NSString *)key { [self.d setObject:value forKey:key]; [self changed]; }

@end

#pragma mark - Runtime helpers

NSView *TweakChildOfClass(NSView *parent, NSString *className) {
    for (NSView *s in parent.subviews)
        if ([NSStringFromClass(s.class) isEqualToString:className]) return s;
    return nil;
}

NSView *TweakDescendantOfClass(NSView *root, NSString *className) {
    if ([NSStringFromClass(root.class) isEqualToString:className]) return root;
    for (NSView *s in root.subviews) {
        NSView *hit = TweakDescendantOfClass(s, className);
        if (hit) return hit;
    }
    return nil;
}

Class TweakFindClass(NSString *prefix, NSString *suffix) {
    // Exact name first; private Swift classes carry a per-build hash, so fall back to a scan.
    if (!suffix.length) return NSClassFromString(prefix);
    unsigned n = 0;
    Class *all = objc_copyClassList(&n);
    Class found = nil;
    for (unsigned i = 0; i < n && !found; i++) {
        const char *name = class_getName(all[i]);
        if (strncmp(name, prefix.UTF8String, prefix.length) != 0) continue;
        NSString *s = @(name);
        if ([s hasSuffix:suffix]) found = all[i];
    }
    free(all);
    return found;
}

IMP TweakHook(Class cls, SEL sel, IMP imp) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return NULL;
    if (class_addMethod(cls, sel, imp, method_getTypeEncoding(m))) return method_getImplementation(m);
    return method_setImplementation(m, imp);
}

#pragma mark - Scripting bridge

id TweakActiveTabForWindow(NSWindow *window) {
    NSString *wid = window.identifier;
    if (!wid) return nil;
    @try {
        for (id sw in [NSApp valueForKey:@"appleScriptWindows"])
            if ([[sw valueForKey:@"windowId"] isEqual:wid]) return [sw valueForKey:@"activeTab"];
    } @catch (__unused NSException *e) {}
    return nil;
}

NSString *TweakURLForWindow(NSWindow *window) {
    @try {
        id u = [TweakActiveTabForWindow(window) valueForKey:@"URL"];
        return [u isKindOfClass:NSString.class] ? u : nil;
    } @catch (__unused NSException *e) { return nil; }
}

// 10/8, 127/8, 169.254/16, 172.16/12, 192.168/16.
static BOOL isPrivateIPv4(NSString *host) {
    struct in_addr a;
    if (inet_pton(AF_INET, host.UTF8String, &a) != 1) return NO;
    uint32_t ip = ntohl(a.s_addr);
    return ip >> 24 == 10 || ip >> 24 == 127 || ip >> 16 == 0xA9FE || ip >> 20 == 0xAC1 || ip >> 16 == 0xC0A8;
}

NSString *TweakResolveURL(NSString *input) {
    NSString *s = [input stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!s.length) return nil;
    NSRegularExpression *scheme = [NSRegularExpression regularExpressionWithPattern:@"^([a-zA-Z][a-zA-Z0-9+.-]*):(//)?[^\\s]*$" options:0 error:nil];
    BOOL hasSpace = [s rangeOfCharacterFromSet:NSCharacterSet.whitespaceCharacterSet].location != NSNotFound;
    NSTextCheckingResult *m = hasSpace ? nil : [scheme firstMatchInString:s options:0 range:NSMakeRange(0, s.length)];
    if (m && ([m rangeAtIndex:2].location != NSNotFound ||
              [@[@"about", @"chrome", @"file", @"mailto", @"javascript", @"data", @"blob", @"view-source", @"tel"]
                  containsObject:[s substringWithRange:[m rangeAtIndex:1]].lowercaseString]))
        return s;
    NSString *host = [s componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/?#"]].firstObject;
    NSString *name = ([host hasPrefix:@"["] ? host : [host componentsSeparatedByString:@":"].firstObject).lowercaseString;
    BOOL local = [host hasPrefix:@"["] || [name isEqualToString:@"localhost"] || [name hasSuffix:@".localhost"] ||
                 [name hasSuffix:@".test"] || [name hasSuffix:@".local"] || isPrivateIPv4(name);
    if (!hasSpace && (local || ([host containsString:@"."] && ![host hasSuffix:@"."])))
        return [(local ? @"http://" : @"https://") stringByAppendingString:s];
    return nil;
}

NSString *TweakResolveInput(NSString *input) {
    NSString *url = TweakResolveURL(input);
    if (url) return url;
    NSString *s = [input stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!s.length) return nil;
    NSMutableCharacterSet *allowed = [NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];
    [allowed removeCharactersInString:@"&=+?#"];
    NSString *q = [s stringByAddingPercentEncodingWithAllowedCharacters:allowed];  // nil for a lone UTF-16 surrogate
    return q ? [@"https://www.google.com/search?q=" stringByAppendingString:q] : nil;
}

void TweakNavigateWindow(NSWindow *window, NSString *url) {
    id tab = TweakActiveTabForWindow(window);
    if (!url.length || !tab) return;
    @try { [tab setValue:url forKey:@"URL"]; }
    @catch (NSException *e) { NSLog(@"[daypatch] navigate failed: %@", e); }
}

static void runScript(NSString *src) {
    NSDictionary *err = nil;
    [[[NSAppleScript alloc] initWithSource:src] executeAndReturnError:&err];
    if (err) NSLog(@"[daypatch] script failed: %@", err[NSAppleScriptErrorMessage]);
}

static NSString *scriptString(NSString *s) {
    return [[s stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
}

// This app by path, not bundle ID: with another Dia running (the original during a
// passkey handoff, or a second copy), the bundle ID could reach the wrong one.
static NSString *selfApp(void) {
    return [NSString stringWithFormat:@"application \"%@\"", scriptString(NSBundle.mainBundle.bundlePath)];
}

// Dia's scripting interface, called in-process (AppleEvents to self need no permission).
void TweakOpenInNewTab(NSWindow *window, NSString *url) {
    if (!window.identifier || !url.length) return;
    runScript([NSString stringWithFormat:@"tell %@\n"
               "  tell (first window whose id is \"%@\") to make new tab with properties {URL:\"%@\"}\n"
               "end tell", selfApp(), scriptString(window.identifier), scriptString(url)]);
}

void TweakFocusTab(NSString *windowId, NSString *tabId) {
    if (!windowId || !tabId) return;
    runScript([NSString stringWithFormat:@"tell %@\n"
               "  focus (first tab of (first window whose id is \"%@\") whose id is \"%@\")\n"
               "end tell", selfApp(), scriptString(windowId), scriptString(tabId)]);
}

TweakCommandBarStyle TweakCommandBarCurrentStyle(void) {
    return [NSUserDefaults.standardUserDefaults integerForKey:TweakKeyCommandBarStyle];
}
