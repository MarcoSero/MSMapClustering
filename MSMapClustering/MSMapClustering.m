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

#import "MSMapClustering.h"
#import "MSMapClusteringDelegate.h"

@interface MSMapClustering ()

@end

@implementation MSMapClustering

- (id)initWithDelegate:(id <MKMapViewDelegate>)theDelegate
{
  // force to set MSMapClusteringDelegate
  if ([theDelegate isKindOfClass:[MSMapClusteringDelegate class]]) {
    return (self = [self initWithDelegate:theDelegate]);
  }
  return nil;
}

- (void)addMSAnnotation:(MSAnnotation *)annotation
{
  [((MSMapClusteringDelegate *)self.delegate)._allAnnotationsMapView addAnnotation:annotation];
  // refresh visible annotations
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldUpdateAnnotations" object:self];
}

- (void)addMSAnnotations:(NSArray *)annotations
{
  [((MSMapClusteringDelegate *)self.delegate)._allAnnotationsMapView addAnnotations:annotations];
  // refresh visible annotations
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldUpdateAnnotations" object:self];

}

- (void)removeMSAnnotation:(MSAnnotation *)annotation
{
  [((MSMapClusteringDelegate *)self.delegate)._allAnnotationsMapView removeAnnotation:annotation];
  [((MSMapClusteringDelegate *)self.delegate).mapView removeAnnotation:annotation];
  // refresh visible annotations
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldUpdateAnnotations" object:self];
}


- (void)removeAllMSAnnotations
{
  NSArray *allAnnotations = [((MSMapClusteringDelegate *)self.delegate)._allAnnotationsMapView annotations];
  [((MSMapClusteringDelegate *)self.delegate)._allAnnotationsMapView removeAnnotations:allAnnotations];
  [((MSMapClusteringDelegate *)self.delegate).mapView removeAnnotations:allAnnotations];
  // refresh visible annotations
  [[NSNotificationCenter defaultCenter] postNotificationName:@"ShouldUpdateAnnotations" object:self];
}


@end
