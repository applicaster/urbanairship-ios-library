/*
 Copyright 2009-2013 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <XCTest/XCTest.h>
#import "UAOpenExternalURLAction.h"
#import <OCMock/OCMock.h>

@interface UAOpenExternalURLActionTest : XCTestCase

@end


@implementation UAOpenExternalURLActionTest

UAOpenExternalURLAction *action;
UAActionArguments *arguments;
id mockApplication;

- (void)setUp {
    [super setUp];

    arguments = [[UAActionArguments alloc] init];
    action = [[UAOpenExternalURLAction alloc] init];

    mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
}

- (void)tearDown {
    [mockApplication stopMocking];

    [super tearDown];
}


/**
* Test accepts valid arguments
*/
- (void)testAcceptsArguments {
    arguments.value = @"http://some-valid-url";
    XCTAssertTrue([action acceptsArguments:arguments], @"action should accept valid string URLs");

    arguments.situation = @"any situation";
    XCTAssertTrue([action acceptsArguments:arguments], @"action should accept any situations that is not UASituationBackgroundPush");

    arguments.value = [NSURL URLWithString:@"http://some-valid-url"];
    XCTAssertTrue([action acceptsArguments:arguments], @"action should accept NSURLs");

    arguments.value = nil;
    XCTAssertFalse([action acceptsArguments:arguments], @"action should not accept a nil value");

    arguments.value = @3213;
    XCTAssertFalse([action acceptsArguments:arguments], @"action should not accept an invalid url");

    arguments.value = @"oh hi";
    XCTAssertFalse([action acceptsArguments:arguments], @"action should not accept an invalid url");

    arguments.value = @"http://some-valid-url";
    arguments.situation = UASituationBackgroundPush;
    XCTAssertFalse([action acceptsArguments:arguments], @"action should not accept arguments with UASituationBackgroundPush situation");
}

/**
 * Test perform with a string URL
 */
- (void)testPerformWithStringURL {
    __block UAActionResult *result;

    arguments.value = @"ftp://some-valid-url";
    arguments.situation = UASituationForegroundPush;

    [[[mockApplication expect] andReturnValue:OCMOCK_VALUE(YES)] openURL:[NSURL URLWithString:arguments.value]];

    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];

    XCTAssertNoThrow([mockApplication verify], @"application should try to open the url");
    XCTAssertEqualObjects(result.value, [NSURL URLWithString:arguments.value], @"results value should be the url");
    XCTAssertNil(result.error, @"result should have no error if the application successfully opens the url");
}


/**
 * Test perform with a NSURL
 */
- (void)testPerformWithNSURL {
    __block UAActionResult *result;

    arguments.value = [NSURL URLWithString:@"scheme://some-valid-url"];
    arguments.situation = UASituationForegroundPush;

    [[[mockApplication expect] andReturnValue:OCMOCK_VALUE(YES)] openURL:arguments.value];

    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];

    XCTAssertNoThrow([mockApplication verify], @"application should try to open the url");
    XCTAssertEqualObjects(result.value, arguments.value, @"results value should be the url");
    XCTAssertNil(result.error, @"result should have no error if the application successfully opens the url");
}

/**
 * Test perform when the application is unable to open the URL it returns an error
 */
- (void)testPerformError {
    __block UAActionResult *result;

    arguments.value = [NSURL URLWithString:@"scheme://some-valid-url"];
    arguments.situation = UASituationForegroundPush;

    [[[mockApplication expect] andReturnValue:OCMOCK_VALUE(NO)] openURL:OCMOCK_ANY];

    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];

    XCTAssertNoThrow([mockApplication verify], @"application should try to open the url");
    XCTAssertEqualObjects(result.value, arguments.value, @"results value should be the url");
    XCTAssertNotNil(result.error, @"result should have an error if the application failed opens the url");
    XCTAssertEqualObjects(UAOpenExternalURLActionErrorDomain, result.error.domain, @"error domain should be set to UAOpenExternalURLActionErrorDomain");
    XCTAssertEqual(UAOpenExternalURLActionErrorCodeURLFailedToOpen, result.error.code, @"error code should be set to UAOpenExternalURLActionErrorCodeURLFailedToOpen");
}

/**
 * Test normalizing phone URLs
 */
- (void)testPerformWithPhoneURL {
    __block UAActionResult *result;

    arguments.value = [NSURL URLWithString:@"sms://+1(541)555%2032195%202241%202313"];
    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];

    XCTAssertEqualObjects([result.value absoluteString], @"sms:+15415553219522412313", @"results value should be normalized phone number");

    arguments.value = @"tel://+1541555adfasdfa%2032195%202241%202313";
    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];
    XCTAssertEqualObjects([result.value absoluteString], @"tel:+15415553219522412313", @"results value should be normalized phone number");
}

/**
 * Test normalizing apple iTunes URLs
 */
- (void)testPerformWithiTunesURL {
    __block UAActionResult *result;

    arguments.value = [NSURL URLWithString:@"app://itunes.apple.com/some-app"];
    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];

    XCTAssertEqualObjects([result.value absoluteString], @"http://itunes.apple.com/some-app", @"results value should be http iTunes link");

    arguments.value = @"app://phobos.apple.com/some-app";
    [action performWithArguments:arguments withCompletionHandler:^(UAActionResult *performResult) {
        result = performResult;
    }];
    XCTAssertEqualObjects([result.value absoluteString], @"http://phobos.apple.com/some-app", @"results value should be http iTunes link");
}
@end