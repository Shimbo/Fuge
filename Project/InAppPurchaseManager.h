//
//  InAppPurchaseManager.h
//  Fuge
//
//  Created by Mikhail Larionov on 9/9/13.
//
//

#import <Foundation/Foundation.h>

#define kInAppPurchase7DayShoutoutProductId @"com.shimbotech.s2c.7dayshoutout"

#define inAppManager [InAppPurchaseManager sharedInstance]

@interface InAppPurchaseManager : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    SKProduct *shoutout7Product;
    SKProductsRequest *productsRequest;
}

+ (id)sharedInstance;

- (void)loadStore;
- (void)requestProductData;

@end
