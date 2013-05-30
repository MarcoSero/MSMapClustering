/*
 * Copyright 2012 Marco Sero.
 * Author: Marco Sero
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MSViewController.h"

@interface MSViewController ()
@property(strong, nonatomic) id <MKMapViewDelegate> myDelegate;
@end

@implementation MSViewController
@synthesize mapView;
@synthesize myDelegate;

- (void)viewDidLoad
{
  [super viewDidLoad];

  myDelegate = [[MSMapClusteringDelegate alloc] initWithMapView:self.mapView];
  mapView.delegate = myDelegate;

  // prepare annotations for mapview
  NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"annotations" ofType:@"plist"];
  NSArray *plistContent = [[[NSMutableDictionary alloc] initWithContentsOfFile:plistPath] objectForKey:@"annotations"];
  NSMutableArray *annotations = [[NSMutableArray alloc] init];
  for (id annotation in plistContent) {
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [[[annotation valueForKey:@"loc"] valueForKey:@"lat"] floatValue];
    coordinate.longitude = [[[annotation valueForKey:@"loc"] valueForKey:@"lon"] floatValue];
    NSString *title = [annotation valueForKey:@"title"];
    MSAnnotation *a = [[MSAnnotation alloc] initWithCoordinates:coordinate title:title subtitle:@""];
    [annotations addObject:a];
  }
  // ADD ANNOTATIONS
  [self.mapView addMSAnnotations:annotations];


  // go to London
  MKCoordinateRegion region;
  region.center.latitude = 51.503347;
  region.center.longitude = -0.127729;
  region.span.latitudeDelta = 1.0;
  region.span.longitudeDelta = 1.0;
  [self.mapView setRegion:region animated:NO];
}

- (void)viewDidUnload
{
  [super viewDidUnload];
  self.mapView = nil;
  self.myDelegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
  } else {
    return YES;
  }
}

@end
