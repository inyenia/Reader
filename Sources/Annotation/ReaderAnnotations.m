//
// Created by otak on 20/02/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ReaderAnnotations.h"
#import "Annotation.h"


@implementation ReaderAnnotations
{

}

+(NSArray*)getAnnotationsImage:(CGPDFPageRef)pageRef {
    return [ReaderAnnotations getAnnotationsImage:pageRef scaleImages:YES];
}

void ListDictionaryObjects (const char *key, CGPDFObjectRef object, void *info) {
    NSString* tab = @"";
    int rec = ((__bridge NSNumber*)info).intValue;
    for (int i = 0; i < rec; i++) {
        tab = [tab stringByAppendingString:@"-"];
    }
    
    NSLog(@"%@key: %s", tab, key);
    CGPDFObjectType type = CGPDFObjectGetType(object);
    switch (type) {
        case kCGPDFObjectTypeDictionary: {
            CGPDFDictionaryRef objectDictionary;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &objectDictionary)) {
                NSNumber* recursive= [NSNumber numberWithInt: + 1];
                CGPDFDictionaryApplyFunction(objectDictionary, ListDictionaryObjects, (__bridge void * _Nullable)(recursive));
            }
        }
        case kCGPDFObjectTypeInteger: {
            CGPDFInteger objectInteger;
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &objectInteger)) {
                NSLog(@"%@value: %ld", tab, (long int)objectInteger);
            }
        }
        // test other object type cases here
        // cf. http://developer.apple.com/mac/library/documentation/GraphicsImaging/Reference/CGPDFObject/Reference/reference.html#//apple_ref/doc/uid/TP30001117-CH3g-SW1
    }
}

// From a PDF Page, it retrieves an array of objects of type Annotation with the position and image read in the pdf annotations.
// The scaleImages parameter should be YES for the images to be on high size, so it can be zoomed, or NO for the images to be lower quality.
+(NSArray*)getAnnotationsImage:(CGPDFPageRef)pageRef scaleImages:(BOOL)scaleImages
{
    NSMutableArray *result = [NSMutableArray array];
    CGPDFArrayRef pageAnnotations = NULL;
    CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(pageRef);
    
    // Debug dictionary elements.
//  NSNumber* recursive= @0;
//  CGPDFDictionaryApplyFunction(pageDictionary, ListDictionaryObjects, (__bridge void * _Nullable)(recursive));
    
    if (CGPDFDictionaryGetArray(pageDictionary, "Annots", &pageAnnotations) == true) {
        NSInteger count = CGPDFArrayGetCount(pageAnnotations); // Number of annotations
        for (NSInteger index = 0; index < count; index++) // Iterate through all annotations
        {
            CGPDFDictionaryRef annotationDictionary = NULL; // PDF annotation dictionary
            if (CGPDFArrayGetDictionary(pageAnnotations, index, &annotationDictionary) == true)
            {
                const char *annotationSubtype = NULL; // PDF annotation subtype string
                CGPDFDictionaryGetName(annotationDictionary, "Subtype", &annotationSubtype);
                
                if (CGPDFDictionaryGetName(annotationDictionary, "Subtype", &annotationSubtype) == true)
                {
                    //NSLog(@"Diccionario de tipo: %@", subtype);
                    if (strcmp(annotationSubtype, "Stamp") == 0) // Found annotation subtype of 'Stamp'
                    {
                        CGPDFArrayRef annotationRectArray = NULL; // Annotation co-ordinates array
                        if (CGPDFDictionaryGetArray(annotationDictionary, "Rect", &annotationRectArray))
                        {
                            CGPDFReal ll_x = 0.0f; CGPDFReal ll_y = 0.0f; // PDFRect lower-left X and Y
                            CGPDFReal ur_x = 0.0f; CGPDFReal ur_y = 0.0f; // PDFRect upper-right X and Y
                            CGPDFArrayGetNumber(annotationRectArray, 0, &ll_x); // Lower-left X co-ordinate
                            CGPDFArrayGetNumber(annotationRectArray, 1, &ll_y); // Lower-left Y co-ordinate
                            CGPDFArrayGetNumber(annotationRectArray, 2, &ur_x); // Upper-right X co-ordinate
                            CGPDFArrayGetNumber(annotationRectArray, 3, &ur_y); // Upper-right Y co-ordinate
                            if (ll_x > ur_x) { CGPDFReal t = ll_x; ll_x = ur_x; ur_x = t; } // Normalize Xs
                            if (ll_y > ur_y) { CGPDFReal t = ll_y; ll_y = ur_y; ur_y = t; } // Normalize Ys
                            NSInteger _pageAngle = 0;
                            CGFloat _pageWidth = 0.0;
                            CGFloat _pageHeight = 0.0;
                            CGFloat _pageOffsetX = 0.0;
                            CGFloat _pageOffsetY = 0.0;
                            
                            ll_x -= _pageOffsetX; ll_y -= _pageOffsetY; // Offset lower-left co-ordinate
                            ur_x -= _pageOffsetX; ur_y -= _pageOffsetY; // Offset upper-right co-ordinate
                            
                            switch (_pageAngle) // Page rotation angle (in degrees)
                            {
                                case 90: // 90 degree page rotation
                                {
                                    CGPDFReal swap;
                                    swap = ll_y; ll_y = ll_x; ll_x = swap;
                                    swap = ur_y; ur_y = ur_x; ur_x = swap;
                                    break;
                                }
                                case 270: // 270 degree page rotation
                                {
                                    CGPDFReal swap;
                                    swap = ll_y; ll_y = ll_x; ll_x = swap;
                                    swap = ur_y; ur_y = ur_x; ur_x = swap;
                                    ll_x = ((0.0f - ll_x) + _pageWidth);
                                    ur_x = ((0.0f - ur_x) + _pageWidth);
                                    break;
                                }
                                    
                                case 0: // 0 degree page rotation
                                {
                                    ll_y = ((0.0f - ll_y) + _pageHeight);
                                    ur_y = ((0.0f - ur_y) + _pageHeight);
                                    break;
                                }
                            }
                            NSInteger vr_x = ll_x; NSInteger vr_w = (ur_x - ll_x); // Integer X and width
                            NSInteger vr_y = -1*ll_y; NSInteger vr_h = -1*(ur_y - ll_y); // Integer Y and height
                            CGRect viewRect = CGRectMake(vr_x, vr_y, vr_w, vr_h);
                            
                            CGPDFDictionaryRef ap;
                            if( !CGPDFDictionaryGetDictionary( annotationDictionary, "AP", &ap ) )
                            {
                                continue;
                            }
                            
                            CGPDFStreamRef strm;
                            if( !CGPDFDictionaryGetStream( ap, "N", &strm ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef strmdict = CGPDFStreamGetDictionary( strm );
                            CGPDFDictionaryRef res;
                            if( !CGPDFDictionaryGetDictionary( strmdict, "Resources", &res ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef xobject;
                            if( !CGPDFDictionaryGetDictionary( res, "XObject", &xobject ) )
                            {
                                continue;
                            }
                            
                            UIImage *imageFull = nil;
                            char imagestr1[16];
                            sprintf( imagestr1, "img1");
                            CGPDFStreamRef strm1;
                            if(CGPDFDictionaryGetStream( xobject, imagestr1, &strm1 ) )
                            {
                                imageFull = getImageRef(strm1);
                            }
                            
                            UIImage *imageMask = nil;
                            char imagestr0[16];
                            sprintf( imagestr0, "img0");
                            CGPDFStreamRef strm0;
                            if (CGPDFDictionaryGetStream( xobject, imagestr0, &strm0 )) {
                                imageMask = getImageRef(strm0);
                            }
                            
                            UIImage* imageResult = nil;
                            if (imageMask && imageFull) {
                                // Apply mask in the image
                                imageResult = [self maskImage:imageFull withMask:imageMask];
                            } else if (imageFull) {
                                imageResult = imageFull;
                            } else if (imageMask) {
                                imageResult = imageMask;
                            } else {
                                // Search for the Stamp image in other possible locations
                                NSArray* values = @[@"Im0", @"Im1", @"Im2"];
                                int index = 0;
                                while (!imageResult && index < values.count) {
                                    char* val = [[values objectAtIndex:index] UTF8String];
                                    if (CGPDFDictionaryGetStream( xobject, val, &strm0 )) {
                                        imageResult = getImageRef(strm0);
                                    }
                                    index++;
                                }
                                if (!imageResult) {
                                    continue;
                                }
                            }
                            
                            CGSize imageSize = imageResult.size;
                            float hfactor = imageSize.width / viewRect.size.width;
                            float vfactor = imageSize.height / viewRect.size.height;
                            float factor = fmax(hfactor, vfactor);
                            
                            // Divide the size by the greater of the vertical or horizontal shrinkage factor
                            float newWidth = imageSize.width / factor;
                            float newHeight = imageSize.height / factor;
                            
                            CGRect newRect = CGRectMake(viewRect.origin.x, viewRect.origin.y, newWidth, newHeight);
                            
                            if (!scaleImages) {
                                imageResult = [self imageWithImage:imageResult scaledToSize:newRect.size];
                            }
                            
                            Annotation* annotation = [[Annotation alloc] init];
                            annotation.image = imageResult;
                            annotation.frame = newRect;
                            
                            [result addObject:annotation];
                        }
                    }else if(strcmp(annotationSubtype, "Widget") == 0){
                        // Found annotation subtype of 'Stamp'
                        CGPDFArrayRef annotationRectArray = NULL; // Annotation co-ordinates array
                        if (CGPDFDictionaryGetArray(annotationDictionary, "Rect", &annotationRectArray))
                        {
                            CGPDFReal ll_x = 0.0f; CGPDFReal ll_y = 0.0f; // PDFRect lower-left X and Y
                            CGPDFReal ur_x = 0.0f; CGPDFReal ur_y = 0.0f; // PDFRect upper-right X and Y
                            CGPDFArrayGetNumber(annotationRectArray, 0, &ll_x); // Lower-left X co-ordinate
                            CGPDFArrayGetNumber(annotationRectArray, 1, &ll_y); // Lower-left Y co-ordinate
                            CGPDFArrayGetNumber(annotationRectArray, 2, &ur_x); // Upper-right X co-ordinate
                            CGPDFArrayGetNumber(annotationRectArray, 3, &ur_y); // Upper-right Y co-ordinate
                            if (ll_x > ur_x) { CGPDFReal t = ll_x; ll_x = ur_x; ur_x = t; } // Normalize Xs
                            if (ll_y > ur_y) { CGPDFReal t = ll_y; ll_y = ur_y; ur_y = t; } // Normalize Ys
                            NSInteger _pageAngle = 0;
                            CGFloat _pageWidth = 0.0;
                            CGFloat _pageHeight = 0.0;
                            CGFloat _pageOffsetX = 0.0;
                            CGFloat _pageOffsetY = 0.0;
                            
                            ll_x -= _pageOffsetX; ll_y -= _pageOffsetY; // Offset lower-left co-ordinate
                            ur_x -= _pageOffsetX; ur_y -= _pageOffsetY; // Offset upper-right co-ordinate
                            
                            switch (_pageAngle) // Page rotation angle (in degrees)
                            {
                                case 90: // 90 degree page rotation
                                {
                                    CGPDFReal swap;
                                    swap = ll_y; ll_y = ll_x; ll_x = swap;
                                    swap = ur_y; ur_y = ur_x; ur_x = swap;
                                    break;
                                }
                                case 270: // 270 degree page rotation
                                {
                                    CGPDFReal swap;
                                    swap = ll_y; ll_y = ll_x; ll_x = swap;
                                    swap = ur_y; ur_y = ur_x; ur_x = swap;
                                    ll_x = ((0.0f - ll_x) + _pageWidth);
                                    ur_x = ((0.0f - ur_x) + _pageWidth);
                                    break;
                                }
                                    
                                case 0: // 0 degree page rotation
                                {
                                    ll_y = ((0.0f - ll_y) + _pageHeight);
                                    ur_y = ((0.0f - ur_y) + _pageHeight);
                                    break;
                                }
                            }
                            NSInteger vr_x = ll_x; NSInteger vr_w = (ur_x - ll_x); // Integer X and width
                            NSInteger vr_y = -1*ll_y; NSInteger vr_h = -1*(ur_y - ll_y); // Integer Y and height
                            CGRect viewRect = CGRectMake(vr_x, vr_y, vr_w, vr_h);
                            
                            CGPDFDictionaryRef ap;
                            if( !CGPDFDictionaryGetDictionary( annotationDictionary, "AP", &ap ) )
                            {
                                continue;
                            }
                            
                            CGPDFStreamRef strm;
                            if( !CGPDFDictionaryGetStream( ap, "N", &strm ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef strmdict = CGPDFStreamGetDictionary( strm );
                            CGPDFDictionaryRef res;
                            if( !CGPDFDictionaryGetDictionary( strmdict, "Resources", &res ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef xobject;
                            if( !CGPDFDictionaryGetDictionary( res, "XObject", &xobject ) )
                            {
                                continue;
                            }
                            
                            CGPDFStreamRef frmStream;
                            CGPDFStreamRef frm1Stream;
                            CGPDFStreamRef frmXStream;
                            if(CGPDFDictionaryGetStream( xobject, "FRM", &frmStream ) ) {
                                frmXStream = frmStream;
                            } else if (CGPDFDictionaryGetStream( xobject, "FRM1", &frm1Stream ) ) {
                                frmXStream = frm1Stream;
                            } else {
                                continue;
                            }
                            
                            CGPDFDictionaryRef frm1 = CGPDFStreamGetDictionary(frmXStream);
                            CGPDFDictionaryRef frm1resources;
                            if( !CGPDFDictionaryGetDictionary( frm1, "Resources", &frm1resources ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef frm1xobject;
                            if( !CGPDFDictionaryGetDictionary( frm1resources, "XObject", &frm1xobject ) )
                            {
                                continue;
                            }
                            
                            NSArray* n = @[@"n0", @"n1", @"n2"];
                            for (NSString *nx in n) {
                                CGPDFStreamRef frmXnXStream;
                                if(!CGPDFDictionaryGetStream( frm1xobject, [nx UTF8String], &frmXnXStream ) ) {
                                    continue;
                                }
                                
                                CGPDFDictionaryRef frm1n1 = CGPDFStreamGetDictionary(frmXnXStream);
                                CGPDFDictionaryRef frm1n1resources;
                                if( !CGPDFDictionaryGetDictionary( frm1n1, "Resources", &frm1n1resources ) )
                                {
                                    continue;
                                }
                                
                                CGPDFDictionaryRef frm1n1xobject;
                                if( !CGPDFDictionaryGetDictionary( frm1n1resources, "XObject", &frm1n1xobject ) )
                                {
                                    continue;
                                }
                                
								UIImage *imageMask = nil;
								char imagestr0[16];
								sprintf( imagestr0, "img0");
								CGPDFStreamRef strm0;
								if (CGPDFDictionaryGetStream( frm1n1xobject, imagestr0, &strm0 )) {
									imageMask = getImageRef(strm0);
								}
								
								UIImage *imageFull = nil;
								char imagestr1[16];
								sprintf( imagestr1, "img1");
								CGPDFStreamRef strm1;
								if(CGPDFDictionaryGetStream( frm1n1xobject, imagestr1, &strm1 ) )
								{
									imageFull = getImageRef(strm1);
								}
								
								UIImage* imageResult = nil;
								if (imageMask && imageFull) {
									// Apply mask in the image
									imageResult = [self maskImage:imageFull withMask:imageMask];
								} else if (imageFull) {
									imageResult = imageFull;
								} else if (imageMask) {
									imageResult = imageMask;
								} else {
									continue;
								}
                                
                                CGSize imageSize = imageResult.size;
                                float hfactor = imageSize.width / viewRect.size.width;
                                float vfactor = imageSize.height / viewRect.size.height;
                                float factor = fmax(hfactor, vfactor);
                                
                                // Divide the size by the greater of the vertical or horizontal shrinkage factor
                                float newWidth = imageSize.width / factor;
                                float newHeight = imageSize.height / factor;
                                
                                CGRect newRect = CGRectMake(viewRect.origin.x, viewRect.origin.y, newWidth, newHeight);
                                
                                if (!scaleImages) {
                                    imageResult = [self imageWithImage:imageResult scaledToSize:newRect.size];
                                }
                                
                                Annotation* annotation = [[Annotation alloc] init];
                                annotation.image = imageResult;
                                annotation.frame = newRect;
                                
                                [result addObject:annotation];
                            }
                            
                        }
                    }
                    
                }
                
            }
            
        }
        
    }
    return result;
    
}

+ (UIImage*)imageWithImage:(UIImage*)image
              scaledToSize:(CGSize)newSize;
{
    UIGraphicsBeginImageContext( newSize );
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

// Retrieves the annotations contained in the pdf and draws them in the given page with the given context.
+(void)showAnotationImage:(CGPDFPageRef)pageRef inContext:(CGContextRef)context
{
    NSArray *annots = [self getAnnotationsImage:pageRef];
    
    for (Annotation* annotation in annots) {
        
        UIGraphicsBeginImageContextWithOptions(annotation.frame.size, NO, 0.0);
        [annotation.image drawInRect:annotation.frame];
        
        CGContextDrawImage(context, annotation.frame, annotation.image.CGImage);
        
        UIGraphicsEndImageContext();
    }
    
}

// temporary C function to print out keys
void printPDFKeys(const char *key, CGPDFObjectRef ob, void *info) {
    NSString *typeValue = @"Unknow";
    CGPDFObjectType type = CGPDFObjectGetType(ob);
    switch (type) {
        case kCGPDFObjectTypeBoolean:
            typeValue = @"kCGPDFObjectTypeBoolean";
            break;
        case kCGPDFObjectTypeInteger:
            typeValue = @"kCGPDFObjectTypeInteger";
            break;
        case kCGPDFObjectTypeReal:
            typeValue = @"kCGPDFObjectTypeReal";
            break;
        case kCGPDFObjectTypeName:
            typeValue = @"kCGPDFObjectTypeName";
            break;
        case kCGPDFObjectTypeString:
            typeValue = @"kCGPDFObjectTypeString";
            break;
        case kCGPDFObjectTypeArray:
            typeValue = @"kCGPDFObjectTypeArray";
            break;
        case kCGPDFObjectTypeDictionary:
            typeValue = @"kCGPDFObjectTypeDictionary";
            break;
        case kCGPDFObjectTypeStream:
            typeValue = @"kCGPDFObjectTypeStream";
            break;
    }
    
    NSLog(@"key = %s (%@)", key, typeValue);
}


CGFloat *decodeValuesFromImageDictionary(CGPDFDictionaryRef dict, CGColorSpaceRef cgColorSpace, NSInteger bitsPerComponent) {
    
    CGFloat *decodeValues = NULL;
    
    CGPDFArrayRef decodeArray = NULL;
    
    
    
    if (CGPDFDictionaryGetArray(dict, "Decode", &decodeArray)) {
        
        size_t count = CGPDFArrayGetCount(decodeArray);
        
        decodeValues = malloc(sizeof(CGFloat) * count);
        
        CGPDFReal realValue;
        
        int i;
        
        for (i = 0; i < count; i++) {
            
            CGPDFArrayGetNumber(decodeArray, i, &realValue);
            
            decodeValues[i] = realValue;
            
        }
        
    } else {
        
        size_t n;
        
        switch (CGColorSpaceGetModel(cgColorSpace)) {
                
            case kCGColorSpaceModelMonochrome:
                
                decodeValues = malloc(sizeof(CGFloat) * 2);
                
                decodeValues[0] = 0.0;
                
                decodeValues[1] = 1.0;
                
                break;
                
            case kCGColorSpaceModelRGB:
                
                decodeValues = malloc(sizeof(CGFloat) * 6);
                
                for (int i = 0; i < 6; i++) {
                    
                    decodeValues[i] = i % 2 == 0 ? 0 : 1;
                    
                }
                
                break;
                
            case kCGColorSpaceModelCMYK:
                
                decodeValues = malloc(sizeof(CGFloat) * 8);
                
                for (int i = 0; i < 8; i++) {
                    
                    decodeValues[i] = i % 2 == 0 ? 0.0 :
                    
                    1.0;
                    
                }
                
                break;
                
            case kCGColorSpaceModelLab:
                
                // ????
                
                break;
                
            case kCGColorSpaceModelDeviceN:
                
                n =
                
                CGColorSpaceGetNumberOfComponents(cgColorSpace) * 2;
                
                decodeValues = malloc(sizeof(CGFloat) * (n *
                                                         
                                                         2));
                
                for (int i = 0; i < n; i++) {
                    
                    decodeValues[i] = i % 2 == 0 ? 0.0 :
                    
                    1.0;
                    
                }
                
                break;
                
            case kCGColorSpaceModelIndexed:
                
                decodeValues = malloc(sizeof(CGFloat) * 2);
                
                decodeValues[0] = 0.0;
                
                decodeValues[1] = pow(2.0,
                                      
                                      (double)bitsPerComponent) - 1;
                
                break;
                
            default:
                
                break;
                
        }
        
    }
    return decodeValues;
}



UIImage *getImageRef(CGPDFStreamRef myStream) {
    
    CGPDFArrayRef colorSpaceArray = NULL;
    
    CGPDFStreamRef dataStream;
    
    CGPDFDataFormat format;
    
    CGPDFDictionaryRef dict;
    
    CGPDFInteger width, height, bps, spp;
    
    CGPDFBoolean interpolation = 0;
    
    //  NSString *colorSpace = nil;
    
    CGColorSpaceRef cgColorSpace;
    
    const char *name = NULL, *colorSpaceName = NULL, *renderingIntentName = NULL;
    
    CFDataRef imageDataPtr = NULL;
    
    CGImageRef cgImage;
    
    //maskImage = NULL,
    
    CGImageRef sourceImage = NULL;
    
    CGDataProviderRef dataProvider;
    
    CGColorRenderingIntent renderingIntent;
    
    CGFloat *decodeValues = NULL;
    
    UIImage *image;
    
    
    
    if (myStream == NULL)
        
        return nil;
    
    
    
    dataStream = myStream;
    
    dict = CGPDFStreamGetDictionary(dataStream);
    
    
    
    // obtain the basic image information
    
    if (!CGPDFDictionaryGetName(dict, "Subtype", &name))
        
        return nil;
    
    
    
    if (strcmp(name, "Image") != 0)
        
        return nil;
    
    
    
    if (!CGPDFDictionaryGetInteger(dict, "Width", &width))
        
        return nil;
    
    
    
    if (!CGPDFDictionaryGetInteger(dict, "Height", &height))
        
        return nil;
    
    
    
    if (!CGPDFDictionaryGetInteger(dict, "BitsPerComponent", &bps))
        
        return nil;
    
    
    
    if (!CGPDFDictionaryGetBoolean(dict, "Interpolate", &interpolation))
        
        interpolation = YES;
    
    
    
    if (!CGPDFDictionaryGetName(dict, "Intent", &renderingIntentName))
        
        renderingIntent = kCGRenderingIntentDefault;
    
    else{
        
        renderingIntent = kCGRenderingIntentDefault;
        
        //      renderingIntent = renderingIntentFromName(renderingIntentName);
        
    }
    
    
    
    imageDataPtr = CGPDFStreamCopyData(dataStream, &format);
    
    dataProvider = CGDataProviderCreateWithCFData(imageDataPtr);
    
    CFRelease(imageDataPtr);
    
    
    
    if (CGPDFDictionaryGetArray(dict, "ColorSpace", &colorSpaceArray)) {
        
        cgColorSpace = CGColorSpaceCreateDeviceRGB();
        
        //      cgColorSpace = colorSpaceFromPDFArray(colorSpaceArray);
        
        spp = CGColorSpaceGetNumberOfComponents(cgColorSpace);
        
    } else if (CGPDFDictionaryGetName(dict, "ColorSpace", &colorSpaceName)) {
        
        if (strcmp(colorSpaceName, "DeviceRGB") == 0) {
            cgColorSpace = CGColorSpaceCreateDeviceRGB();
            
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
            
            spp = 3;
            
        } else if (strcmp(colorSpaceName, "DeviceCMYK") == 0) {
            
            cgColorSpace = CGColorSpaceCreateDeviceCMYK();
            
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericCMYK);
            
            spp = 4;
            
        } else if (strcmp(colorSpaceName, "DeviceGray") == 0) {
            
            cgColorSpace = CGColorSpaceCreateDeviceGray();
            
            //          CGColorSpaceCreateWithName(kCGColorSpaceGenericGray);
            
            spp = 1;
            
        } else { // if there's no colorspace entry, there's still one we can infer from bps
            
            cgColorSpace = CGColorSpaceCreateDeviceGray();
            
            //          colorSpace = NSDeviceBlackColorSpace;
            
            spp = 1;
            
        }
        
    }
    
    
    
    decodeValues = decodeValuesFromImageDictionary(dict, cgColorSpace, bps);
    
    
    
    int rowBits = bps * spp * width;
    
    int rowBytes = rowBits / 8;
    
    // pdf image row lengths are padded to byte-alignment
    
    if (rowBits % 8 != 0)
        
        ++rowBytes;
    
    
    
    //  maskImage = SMaskImageFromImageDictionary(dict);
    
    
    
    if (format == CGPDFDataFormatRaw)
        
    {
        sourceImage = CGImageCreate(width, height, bps, bps * spp, rowBytes, cgColorSpace, 0, dataProvider, decodeValues, interpolation, renderingIntent);
        
        CGDataProviderRelease(dataProvider);
        
        cgImage = sourceImage;
        
        //      if (maskImage != NULL) {
        
        //          cgImage = CGImageCreateWithMask(sourceImage, maskImage);
        
        //          CGImageRelease(sourceImage);
        
        //          CGImageRelease(maskImage);
        
        //      } else {
        
        //          cgImage = sourceImage;
        
        //      }
        
    } else {        
        if (format == CGPDFDataFormatJPEGEncoded){ // JPEG data requires a CGImage; AppKit can't decode it {
            
            sourceImage =
            
            CGImageCreateWithJPEGDataProvider(dataProvider,decodeValues,interpolation,renderingIntent);
            
            CGDataProviderRelease(dataProvider);
            
            cgImage = sourceImage;
            
            //          if (maskImage != NULL) {
            
            //              cgImage = CGImageCreateWithMask(sourceImage,maskImage);
            
            //              CGImageRelease(sourceImage);
            
            //              CGImageRelease(maskImage);
            
            //          } else {
            
            //              cgImage = sourceImage;
            
            //          }
            
        }
        
        // note that we could have handled JPEG with ImageIO as well
        
        else if (format == CGPDFDataFormatJPEG2000) { // JPEG2000 requires ImageIO {
            
            CFDictionaryRef dictionary = CFDictionaryCreate(NULL, NULL, NULL, 0, NULL, NULL);
            
            sourceImage=
            
            CGImageCreateWithJPEGDataProvider(dataProvider, decodeValues, interpolation, renderingIntent);
            
            
            
            
            
            //          CGImageSourceRef cgImageSource = CGImageSourceCreateWithDataProvider(dataProvider, dictionary);
            
            CGDataProviderRelease(dataProvider);
            
            
            
            cgImage=sourceImage;
            
            
            
            //          cgImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, dictionary);
            
            CFRelease(dictionary);
            
        } else // some format we don't know about or an error in the PDF
            
            return nil;
        
    }
    
    image=[UIImage imageWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    
    return image;
}

+ (UIImage*) replaceColor:(UIColor*)color inImage:(UIImage*)image withTolerance:(float)tolerance {
    CGImageRef imageRef = [image CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    NSUInteger bitmapByteCount = bytesPerRow * height;
    
    unsigned char *rawData = (unsigned char*) calloc(bitmapByteCount, sizeof(unsigned char));
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGColorRef cgColor = [color CGColor];
    const CGFloat *components = CGColorGetComponents(cgColor);
    float r = components[0];
    float g = components[1];
    float b = components[2];
    //float a = components[3]; // not needed
    
    r = r * 255.0;
    g = g * 255.0;
    b = b * 255.0;
    
    const float redRange[2] = {
        MAX(r - (tolerance / 2.0), 0.0),
        MIN(r + (tolerance / 2.0), 255.0)
    };
    
    const float greenRange[2] = {
        MAX(g - (tolerance / 2.0), 0.0),
        MIN(g + (tolerance / 2.0), 255.0)
    };
    
    const float blueRange[2] = {
        MAX(b - (tolerance / 2.0), 0.0),
        MIN(b + (tolerance / 2.0), 255.0)
    };
    
    int byteIndex = 0;
    
    while (byteIndex < bitmapByteCount) {
        unsigned char red   = rawData[byteIndex];
        unsigned char green = rawData[byteIndex + 1];
        unsigned char blue  = rawData[byteIndex + 2];
        
        if (((red >= redRange[0]) && (red <= redRange[1])) &&
            ((green >= greenRange[0]) && (green <= greenRange[1])) &&
            ((blue >= blueRange[0]) && (blue <= blueRange[1]))) {
            // make the pixel transparent
            //
            rawData[byteIndex] = 0;
            rawData[byteIndex + 1] = 0;
            rawData[byteIndex + 2] = 0;
            rawData[byteIndex + 3] = 0;
        }
        
        byteIndex += 4;
    }
    
    CGImageRef imgref = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:imgref];
    
    CGImageRelease(imgref);
    CGContextRelease(context);
    free(rawData);
    
    return result;
}

+ (UIImage*) maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

        CGImageRef maskImageRef = [maskImage CGImage];

        // create a bitmap graphics context the size of the image
        CGContextRef mainViewContentContext = CGBitmapContextCreate (NULL, maskImage.size.width, maskImage.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);

        if (mainViewContentContext==NULL)
            return NULL;

        CGFloat ratio = 0;

        ratio = maskImage.size.width/ image.size.width;

        if(ratio * image.size.height < maskImage.size.height) {
            ratio = maskImage.size.height/ image.size.height;
        }

        CGRect rect1  = {{0, 0}, {maskImage.size.width, maskImage.size.height}};
        CGRect rect2  = {{-((image.size.width*ratio)-maskImage.size.width)/2 , -((image.size.height*ratio)-maskImage.size.height)/2}, {image.size.width*ratio, image.size.height*ratio}};


        CGContextClipToMask(mainViewContentContext, rect1, maskImageRef);
        CGContextDrawImage(mainViewContentContext, rect2, image.CGImage);


        // Create CGImageRef of the main view bitmap content, and then
        // release that bitmap context
        CGImageRef newImage = CGBitmapContextCreateImage(mainViewContentContext);
        CGContextRelease(mainViewContentContext);

        UIImage *theImage = [UIImage imageWithCGImage:newImage];

        CGImageRelease(newImage);

        // return the image
        return theImage;
}

@end
