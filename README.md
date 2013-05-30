# MSMapClustering
### A subclass of `MKMapView` to cluster annotations

MSMapClustering lets you to cluster your annotations inside a map view, like Photos.app does with your photos on the map.

![image](http://f.cl.ly/items/0k0l2c1J3w3K053G3M1E/map_large2.gif)

The code is freely adaped from an Apple tutorial of WWDC 2010, I've packed it into these classes to make a reusable component for my future works.

## Structure

There are three main classes:

- `MSMapClustering`, a subclass of MKMapView
- `MSMapClusteringDelegate`, the class delegate that conforms to protocol `<MKMapViewDelegate>`
- `MSAnnotation`, a particular class that conforms to protocol `<MKAnnotation>`


## Usage

Include in your project the three classes above and then create your map view and its delegate:

    MSMapClustering *mapView = [[MSMapClustering alloc] init];
	mapView.delegate = [[MSMapClusteringDelegate alloc] initWithMapView:mapView];
	
Add/remove annotations using these methods

    - (void)addMSAnnotation:(MSAnnotation *)annotation;
    - (void)addMSAnnotations:(NSArray *)annotations;
    
    - (void)removeMSAnnotation:(MSAnnotation *)annotation;
    - (void)removeAllMSAnnotations;
    
Implement the delegate's method in the class MSMapClusteringDelegate (obviously!), but pay attention if you want to change methods already inside it.

If you want, you could change `marginFactor` and `bucketSize` parameters in `MSMapClusteringDelegate.m`.

- `marginFactor`: this value controls the number of off screen annotations are displayed.  
A bigger number means more annotations, less chance of seeing annotations views pop in but decreased performance.  
A smaller number means fewer annotations, more chance of seeing annotations views pop in but better performance.
- `bucketSize`: adjust this roughly based on the dimensions of your annotations views.  
Bigger numbers more aggressively coalesce annotations (fewer annotations displayed but better performance).
Numbers too small result in overlapping annotations views and too many annotations in screen.

## Dependencies

MapKit framework is required.

## Demo
Play with it and ask me whatever you want.
     

## License
Apache 2.0 [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)