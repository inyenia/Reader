//
// Created by otak on 20/02/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "ReaderAnnotations.h"


@implementation ReaderAnnotations
{

}

+(void)showAnotationImage:(CGPDFPageRef)pageRef inContext:(CGContextRef)context
{
    
    // INITIALIZATION POSITIONS
    CGRect annotation1 = CGRectMake(120, 841-735-15, 100, 37);
    CGRect annotation2 = CGRectMake(350, 841-735-15, 100, 37);
    NSMutableArray *annotationsPos = [[NSMutableArray alloc] init];
    [annotationsPos addObject:[NSValue valueWithCGRect:annotation1]];
    [annotationsPos addObject:[NSValue valueWithCGRect:annotation2]];
    
    
    CGPDFArrayRef pageAnnotations = NULL;
    CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(pageRef);
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
                            
                            char imagestr[16];
                            sprintf( imagestr, "img0");
                            CGPDFStreamRef strm2;
                            
                            if( !CGPDFDictionaryGetStream( xobject, imagestr, &strm2 ) )
                            {
                                continue;
                            }
                            
							UIImage *image = getImageRef(strm2);
							CGSize imageSize = image.size;
							float hfactor = imageSize.width / viewRect.size.width;
							float vfactor = imageSize.height / viewRect.size.height;
							float factor = fmax(hfactor, vfactor);
							
							// Divide the size by the greater of the vertical or horizontal shrinkage factor
							float newWidth = imageSize.width / factor;
							float newHeight = imageSize.height / factor;
							
							CGRect newRect = CGRectMake(viewRect.origin.x, viewRect.origin.y, newWidth, newHeight);
							UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0);
							[image drawInRect:newRect];
							
							CGContextDrawImage(context, newRect, image.CGImage);
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
                            
                            CGPDFStreamRef frm1Stream;
                            if( !CGPDFDictionaryGetStream( xobject, "FRM1", &frm1Stream ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef frm1 = CGPDFStreamGetDictionary(frm1Stream);
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
                            
                            CGPDFStreamRef frm1n1Stream;
                            if( !CGPDFDictionaryGetStream( frm1xobject, "n1", &frm1n1Stream ) )
                            {
                                continue;
                            }
                            
                            CGPDFDictionaryRef frm1n1 = CGPDFStreamGetDictionary(frm1n1Stream);
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
                            
                            char imagestr[16];
                            sprintf( imagestr, "img1");
                            CGPDFStreamRef strm2;
                            
                            if( !CGPDFDictionaryGetStream( frm1n1xobject, imagestr, &strm2 ) )
                            {
                                continue;
                            }
                            
                            //CGPDFDictionaryApplyFunction(frm1xobject, printPDFKeys, NULL);
                            
                            UIImage *image = getImageRef(strm2);
                            CGSize imageSize = image.size;
                            float hfactor = imageSize.width / viewRect.size.width;
                            float vfactor = imageSize.height / viewRect.size.height;
                            float factor = fmax(hfactor, vfactor);
                            
                            // Divide the size by the greater of the vertical or horizontal shrinkage factor
                            float newWidth = imageSize.width / factor;
                            float newHeight = imageSize.height / factor;
                            
                            CGRect newRect = CGRectMake(viewRect.origin.x, viewRect.origin.y, newWidth, newHeight);
                            UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0);
                            [image drawInRect:newRect];
                            
                            CGContextDrawImage(context, newRect, image.CGImage);
                        }
                    }
                    
                }
                
            }
            
        }
        
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
    
    
    
    // prueba cambiar colores imagen
    
    if (strcmp(colorSpaceName, "DeviceGray") == 0){
        
        UIGraphicsBeginImageContext(image.size);
        
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeCopy);
        
        [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
        
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(), kCGBlendModeDifference);
        
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext(),[UIColor whiteColor].CGColor);
        
        CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height));
        
        image= UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
    }
    
    return image;
}

@end
