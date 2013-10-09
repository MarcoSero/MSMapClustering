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

#import "MSMapClusteringDelegate.h"

@interface MSMapClusteringDelegate ()
@property(copy, nonatomic) NSMutableArray *annotationsToAdd;
@end

@implementation MSMapClusteringDelegate

// This value controls the number of off screen annotations are displayed.
// A bigger number means more annotations, less chance of seeing annotations views pop in but
// decreased performance.
// A smaller number means fewer annotations, more chance of seeing annotations views pop in but
// better performance.
static float marginFactor = 2.0;

// Adjust this roughly based on the dimensions of your annotations views.
// Bigger numbers more aggressively coalesce annotations (fewer annotations displayed but better performance)
// Numbers too small result in overlapping annotations views and too many annotations in screen.
static float bucketSize = 60.0;


@synthesize mapView;
@synthesize _allAnnotationsMapView;
@synthesize annotationsToAdd;

- (id)initWithMapView:(MSMapClustering *)aMapView
{
  if (self = [super init]) {
    self.mapView = aMapView;
    _allAnnotationsMapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    // adds an observer to start refresh annotations
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateVisibleAnnotation)
                                                 name:@"ShouldUpdateAnnotations" object:nil];
    return self;
  }
  return nil;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ShouldUpdateAnnotations" object:nil];
}


#pragma mark -
#pragma mark Custom Methods

- (id <MKAnnotation>)annotationInGrid:(MKMapRect)gridMapRect usingAnnotations:(NSSet *)annotations
{
  // First, see if one of the annotations we were already showing is in this mapRect
  NSSet *visibleAnnotationsInBucket = [self.mapView annotationsInMapRect:gridMapRect];
  NSSet *annotationsForGridSet = [annotations objectsPassingTest:^BOOL(id obj, BOOL *stop) {
    BOOL returnValue = ([visibleAnnotationsInBucket containsObject:obj]);
    if (returnValue) {
      *stop = YES;
    }
    return returnValue;
  }];

  if (annotationsForGridSet.count != 0) {
    return [annotationsForGridSet anyObject];
  }

  // Otherwise, sort the annotations based on their distance from the center of the grid square,
  // then choose the one closest to the center to show
  MKMapPoint centerMapPoint = MKMapPointMake(MKMapRectGetMidX(gridMapRect), MKMapRectGetMidY(gridMapRect));
  NSArray *sortedAnnotations = [[annotations allObjects] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    MKMapPoint mapPoint1 = MKMapPointForCoordinate(((id <MKAnnotation>)obj1).coordinate);
    MKMapPoint mapPoint2 = MKMapPointForCoordinate(((id <MKAnnotation>)obj2).coordinate);

    CLLocationDistance distance1 = MKMetersBetweenMapPoints(mapPoint1, centerMapPoint);
    CLLocationDistance distance2 = MKMetersBetweenMapPoints(mapPoint2, centerMapPoint);

    if (distance1 < distance2) {
      return NSOrderedAscending;
    }
    else {
      return NSOrderedDescending;
    }
  }];

  return [sortedAnnotations objectAtIndex:0];

}

- (void)updateVisibleAnnotation
{
  // fix performance and visual clutter by calling update when change map region
  // it's called any time region changed on the map

  // Find all the annotation in the visible area + a wide margin to avoid popping annotation
  // views in and out while panning the map
  MKMapRect visibleMapRect = [self.mapView visibleMapRect];
  MKMapRect adjustedVisibleMapRect = MKMapRectInset(visibleMapRect, -marginFactor * visibleMapRect.size.width, -marginFactor * visibleMapRect.size.height);

  // Determine how wide each bucket will be, as a MapRect square
  CLLocationCoordinate2D leftCoordinate = [self.mapView convertPoint:CGPointZero toCoordinateFromView:[self.mapView superview]];
  CLLocationCoordinate2D rightCoordinate = [self.mapView convertPoint:CGPointMake(bucketSize, 0) toCoordinateFromView:[self.mapView superview]];
  double gridSize = fabs(MKMapPointForCoordinate(rightCoordinate).x - MKMapPointForCoordinate(leftCoordinate).x);
  MKMapRect gridMapRect = MKMapRectMake(0, 0, gridSize, gridSize);

  // Condense annotations with a padding of two squares, around the visibleMapRect
  double startX = floor(MKMapRectGetMinX(adjustedVisibleMapRect) / gridSize) * gridSize;
  double startY = floor(MKMapRectGetMinY(adjustedVisibleMapRect) / gridSize) * gridSize;
  double endX = floor(MKMapRectGetMaxX(adjustedVisibleMapRect) / gridSize) * gridSize;
  double endY = floor(MKMapRectGetMaxY(adjustedVisibleMapRect) / gridSize) * gridSize;

  // For each square in grid, pick one annotation to show
  gridMapRect.origin.y = startY;
  while (MKMapRectGetMinY(gridMapRect) <= endY) {
    gridMapRect.origin.x = startX;

    while (MKMapRectGetMinX(gridMapRect) <= endX) {
      NSSet *allAnnotationsInBucket = [_allAnnotationsMapView annotationsInMapRect:gridMapRect];
      NSSet *visibleAnnotationsInBucket = [self.mapView annotationsInMapRect:gridMapRect];

      // We only care about MSAnnotation
      NSMutableSet *filteredAnnotationsInBucket = [[allAnnotationsInBucket objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return ([obj isKindOfClass:[MSAnnotation class]]);
      }] mutableCopy];

      if (filteredAnnotationsInBucket.count > 0) {
        MSAnnotation *annotationForGrid = (MSAnnotation *)[self annotationInGrid:gridMapRect usingAnnotations:filteredAnnotationsInBucket];

        [filteredAnnotationsInBucket removeObject:annotationForGrid];

        // Give the annotationForGrid a reference to all the annotation it will represent
        annotationForGrid.containedAnnotations = [filteredAnnotationsInBucket allObjects];


        [self.mapView addAnnotation:annotationForGrid];

        for (MSAnnotation *annotation in filteredAnnotationsInBucket) {
          // Give all the other annotations a reference to the one which is representing them
          annotation.clusterAnnotation = annotationForGrid;
          annotation.containedAnnotations = nil;

          // Remove annotations (with animation) which we've decided to cluster
          if ([visibleAnnotationsInBucket containsObject:annotation]) {
            CLLocationCoordinate2D actualCoordinate = annotation.coordinate;
            [UIView animateWithDuration:0.3 animations:^{
              annotation.coordinate = annotation.clusterAnnotation.coordinate;
            }                completion:^(BOOL finished) {
              annotation.coordinate = actualCoordinate;
              [self.mapView removeAnnotation:annotation];
            }];
          }
        }
      }
      gridMapRect.origin.x += gridSize;
    }
    gridMapRect.origin.y += gridSize;
  }
}

/****************************************************************************************************************/
/***************************************** Map View Delegate methods ********************************************/
/****************************************************************************************************************/

#pragma mark -
#pragma mark Map View Delegate methods

/*
	You can change this method but pay attention to keep the line
	[self updateVisibleAnnotation];
	to update the visible annotation every time map changes region.
*/
- (void)mapView:(MKMapView *)aMapView regionDidChangeAnimated:(BOOL)animated
{
  [self updateVisibleAnnotation];
}

/*
	This method is responsible for the animation of annotations.
	I recommend to not change it.
*/
- (void)mapView:(MKMapView *)aMapView didAddAnnotationViews:(NSArray *)views
{
  for (MKAnnotationView *view in views) {
    if ([view.annotation isKindOfClass:[MSAnnotation class]]) {

      MSAnnotation *annotation = (MSAnnotation *)view.annotation;

      if (annotation.clusterAnnotation != nil) {
        // Animate the annotation from it's old container's coordinate, to its actual coordinate
        CLLocationCoordinate2D actualCoordinate = annotation.coordinate;
        CLLocationCoordinate2D containerCoordinate = annotation.clusterAnnotation.coordinate;

        annotation.clusterAnnotation = nil;
        annotation.coordinate = containerCoordinate;

        [UIView animateWithDuration:0.3 animations:^{
          annotation.coordinate = actualCoordinate;
        }];
      }
    }
  }
}


- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
  MKAnnotationView *annotationView = (MKAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];

  if (annotationView == nil) {
      annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
  }

  annotationView.canShowCallout = YES;
  return annotationView;
}


@end
